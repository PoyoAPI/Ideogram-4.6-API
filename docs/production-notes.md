# Ideogram 4.6 API production notes

## Confirmed contract

- Endpoint: `POST /api/generate/submit`
- Model IDs: `ideogram-v4.6`, `ideogram-v4.6-edit`
- Authentication: `Authorization: Bearer <POYO_API_KEY>`
- Status: `GET /api/generate/status/{task_id}`

## Input limits

| Field | Requirement | Constraint |
| --- | --- | --- |
| prompt | required | 1–10,000 characters with non-whitespace text. |
| size | optional | auto (default), 1:1, 1:1 HD, 4:3, 3:4, 16:9, 9:16, or WIDTHxHEIGHT (lowercase x; sides 256–4096 and multiples of 32; aspect ratio within 1:6 and 6:1). |
| quality | optional | very_low, low, medium (default), or high; very_low only for outputs up to 4,194,304 pixels. |
| n | optional | Integer 1–8 (default 1); strings and booleans are rejected. |
| background | optional | transparent or opaque; on the edit model, regular edits only. |
| seed | optional | Integer 0–2147483647. |
| image_urls (edit) | required | Exactly one public HTTP(S) URL or base64 image data URI, as an array. |
| mask_url (edit) | optional | Same dimensions as the source; black = edit, white = keep; must contain both; requires size auto. |
| reference_image_urls (edit) | optional | 0–4 images, or at most 3 with mask_url. |
| edit_precision (edit) | optional | regular (default) or high; high requires size auto and rejects background. |
| context_window (edit) | optional | none (default) or auto; auto requires mask_url and edit_precision high. |

Any other field in `input` is rejected with an `unsupported fields` error. Prompt expansion is always on.

## Billing tiers

- Per output image; `n` multiplies the price. 1 credit = $0.005.
- 2K tier: outputs up to 4,194,304 pixels (2048×2048 in area). 4K tier: anything larger. The 4K tier has no `very_low`.
- Text-to-image `auto` and the six presets bill at the 2K tier; custom sizes bill by area.
- Edits with `size: auto` keep the source geometry, so the source image's dimensions set the tier. If PoYo cannot read the source size at submission, it reserves the 4K price and settles to the actual output size when the task finishes. Downscale sources to at most 4,194,304 pixels when the 2K tier is enough.

## Launch-day results

Production requests on November 20, 2026, with the jazz-festival poster prompt used in [`payloads/`](../payloads):

| Request | Output | Credits |
| --- | --- | --- |
| `ideogram-v4.6`, `quality: high`, `size: 2304x3072` | 2304×3072 PNG | 40 |
| `ideogram-v4.6`, same prompt, `quality: very_low`, `size: 3:4` | 768×1024 | 1.6 |
| `ideogram-v4.6-edit` on the 2304×3072 poster, `edit_precision: high`, `size: auto`, `quality: high`, prompt `Change only the date line to "JULY 3-5 · RIVERSIDE PARK". Keep everything else exactly the same.` | 2304×3072; changed pixels ≈1.1% of the frame | 120 |

The high-precision edit kept the source resolution and changed only the date line. The edit payloads in this repository use a 1536×2048 copy of the same poster, so the same high-precision edit bills at the 2K tier (44 credits).

## Output

- `files` holds one entry per image, each with `file_url` and `file_type: image`. With `background: transparent`, images have an alpha channel.
- Generated files are available for 3 days after creation.

## Operational checklist

- Keep API keys in a server-side secret manager.
- Validate user input before calling the API, including custom sizes, `very_low` limits, and the edit-mode rules above.
- Check mask dimensions against the source before submitting a masked edit.
- Persist `data.task_id` immediately after submission.
- Use five-second polling only for development; prefer `callback_url` in production.
- Make webhook processing idempotent and reconcile status before fulfilling an order.
- Copy output files to durable storage within 3 days.
- Recheck the live model page before hard-coding prices.

## Failure handling

Treat non-2xx HTTP responses and non-success API `code` values as errors; some validation errors return HTTP 200 with `code: 400`. Preserve the HTTP status, API code, and a redacted response body for debugging.

Schema: [PoYo API documentation](https://docs.poyo.ai/api-manual/image-series/ideogram-v4-6?utm_source=github&utm_medium=readme&utm_campaign=ideogram-4.6-api)
