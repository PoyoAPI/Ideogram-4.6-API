# Ideogram 4.6 API: cURL, Python, and Node.js Examples

[![Ideogram 4.6 on PoYo](https://img.shields.io/badge/Try%20on%20PoYo-ideogram--v4.6-84cc16)](https://poyo.ai/models/ideogram-4-6?utm_source=github&utm_medium=readme&utm_campaign=ideogram-4.6-api) [![API docs](https://img.shields.io/badge/API-docs-22d3ee)](https://docs.poyo.ai/api-manual/image-series/ideogram-v4-6?utm_source=github&utm_medium=readme&utm_campaign=ideogram-4.6-api) [![Check](https://github.com/PoyoAPI/Ideogram-4.6-API/actions/workflows/check.yml/badge.svg)](https://github.com/PoyoAPI/Ideogram-4.6-API/actions/workflows/check.yml)

Runnable examples for **Ideogram 4.6** through PoYo's async image API: text-to-image with accurate on-image text at four quality levels and custom sizes up to 4096 pixels per side, transparent backgrounds, and image editing with masks, reference images, and high-precision edits that keep every pixel you did not ask to change.

**Answer:** To use the Ideogram 4.6 API, send a server-side request to `POST https://api.poyo.ai/api/generate/submit` with model `ideogram-v4.6` (or `ideogram-v4.6-edit` to edit an image) and a PoYo API key, then poll `GET https://api.poyo.ai/api/generate/status/{task_id}`. The examples in this repository run with Python 3.9+, Node.js 22+, or cURL.

Last verified against the PoYo API reference and model catalog on **November 20, 2026**.

## Ideogram 4.6 at a glance

- **Model IDs:** `ideogram-v4.6` (text-to-image) and `ideogram-v4.6-edit` (edit one source image)
- **Text in images:** put the exact words in quotes in the prompt, such as a poster title or a sign
- **Quality:** `very_low` for fast drafts, then `low`, `medium` (default), and `high`
- **Sizes:** `auto`, six presets from 512×512 to 1024×1024, or a custom `WIDTHxHEIGHT` from 256 to 4096 pixels per side (for example `2304x3072`)
- **Editing:** an optional mask (black = edit, white = keep), up to 4 reference images, and `edit_precision: high` to restore unchanged pixels at the source resolution
- **Batches and transparency:** 1–8 images per request, `background: "transparent"`, and repeatable seeds
- **Price:** from 1.6 credits ($0.008) per image; outputs above 4,194,304 pixels bill at the 4K tier

## Quickstart

1. Create a key in the [PoYo dashboard](https://poyo.ai/dashboard/api-key?utm_source=github&utm_medium=readme&utm_campaign=ideogram-4.6-api).
2. Copy `.env.example` to `.env` and replace the placeholder.
3. Run one of the examples. Each submits the task and polls until `finished` or `failed`.

```dotenv
POYO_API_KEY=YOUR_POYO_API_KEY_HERE
POYO_BASE_URL=https://api.poyo.ai
```

### Python

```bash
python python/generate.py
python python/generate.py payloads/ideogram-v4.6-edit-high-precision.json
```

[`python/generate.py`](python/generate.py) uses only the Python standard library.

### Node.js

```bash
node node/index.mjs
node node/index.mjs payloads/ideogram-v4.6-text-to-image-4k.json
```

The examples poll every 5 seconds for up to 10 minutes. For production, set `POYO_CALLBACK_URL` in `.env` to receive a webhook instead.

### cURL

```bash
curl -X POST "https://api.poyo.ai/api/generate/submit" \
  -H "Authorization: Bearer $POYO_API_KEY" \
  -H "Content-Type: application/json" \
  -d @payloads/ideogram-v4.6-text-to-image-draft.json
```

Status polling and the other modes are in [curl/generate.md](curl/generate.md).

## Example requests

Every file in [`payloads/`](payloads) is a complete request body with public input media, so it runs as-is. The edit examples use a hosted 1536×2048 copy of the jazz-festival poster and a same-size mask over its date line.

| File | Model | Mode | Settings | Credits |
| --- | --- | --- | --- | --- |
| [`ideogram-v4.6-text-to-image-draft.json`](payloads/ideogram-v4.6-text-to-image-draft.json) | `ideogram-v4.6` | Text-to-image draft | `3:4` (768×1024), `very_low` | 1.6 ($0.008) |
| [`ideogram-v4.6-text-to-image-4k.json`](payloads/ideogram-v4.6-text-to-image-4k.json) | `ideogram-v4.6` | Text-to-image poster | `2304x3072`, `high` | 40 ($0.20) |
| [`ideogram-v4.6-transparent-background.json`](payloads/ideogram-v4.6-transparent-background.json) | `ideogram-v4.6` | Transparent sticker | `1:1 HD` (1024×1024), `low`, seed 42 | 6 ($0.03) |
| [`ideogram-v4.6-edit-high-precision.json`](payloads/ideogram-v4.6-edit-high-precision.json) | `ideogram-v4.6-edit` | High-precision edit of the whole image | `auto` (1536×2048 source), `high` | 44 ($0.22) |
| [`ideogram-v4.6-edit-mask-localized.json`](payloads/ideogram-v4.6-edit-mask-localized.json) | `ideogram-v4.6-edit` | Localized edit with a mask, `context_window: auto` | `auto` (1536×2048 source), `medium` | 12 ($0.06) |

The two text-to-image poster payloads share one prompt, so you can draft at `very_low` and render the final at `high`. Both edits change only the date line to "JULY 3-5 · RIVERSIDE PARK". Edits with `size: auto` keep the source resolution, so a source above 4,194,304 pixels bills at the 4K tier: the same high-precision edit on the full 2304×3072 poster costs 120 credits ($0.60).

## Input modes

| Model ID | Mode | Selected when | Output size |
| --- | --- | --- | --- |
| `ideogram-v4.6` | Text-to-image | Always | From `size` (default `auto`, about 2K) |
| `ideogram-v4.6-edit` | Regular edit | `edit_precision` is `regular` (default) | Source geometry with `size: auto`; without a mask, any preset or custom size |
| `ideogram-v4.6-edit` | High-precision edit | `edit_precision: high`, `context_window: none` | Source resolution; unchanged pixels are restored |
| `ideogram-v4.6-edit` | Localized edit | `edit_precision: high`, `context_window: auto`, `mask_url` | Source resolution; only the region around the mask is edited |

- **Masks:** same dimensions as the source image. Black areas are edited and white areas are kept; the mask must contain both. A mask that is too large falls back to whole-image editing.
- **Reference images:** up to 4 in `reference_image_urls`, or 3 when `mask_url` is set, to guide style or content.
- **Image inputs:** public HTTP(S) URLs or base64 data URIs (`data:image/<type>;base64,...`). `image_urls` is always an array with exactly one image.

## Request fields

### `ideogram-v4.6`

| Field | Requirement | Meaning |
| --- | --- | --- |
| prompt | required | 1–10,000 characters with non-whitespace text. Put exact on-image text in quotes. |
| size | optional | `auto` (default), `1:1` (512×512), `1:1 HD` (1024×1024), `4:3` (1024×768), `3:4` (768×1024), `16:9` (1024×576), `9:16` (576×1024), or `WIDTHxHEIGHT` with a lowercase `x`: sides 256–4096 and multiples of 32, aspect ratio within 1:6 and 6:1. |
| quality | optional | `very_low`, `low`, `medium` (default), or `high`. `very_low` only for outputs up to 4,194,304 pixels. |
| n | optional | Number of images, integer 1–8. Default 1. |
| background | optional | `transparent` (alpha channel) or `opaque`. Omit for the model default. |
| seed | optional | Integer 0–2147483647. |

### `ideogram-v4.6-edit`

| Field | Requirement | Meaning |
| --- | --- | --- |
| prompt | required | 1–10,000 characters describing the edit. |
| image_urls | required | Exactly one source image. Always an array. |
| mask_url | optional | Same size as the source; black = edit, white = keep. Requires `size: auto`. |
| reference_image_urls | optional | 0–4 images, or at most 3 with `mask_url`. |
| edit_precision | optional | `regular` (default) or `high`. `high` requires `size: auto` and rejects `background`. |
| context_window | optional | `none` (default) or `auto`. `auto` requires `mask_url` and `edit_precision: high`. |
| size | optional | `auto` (default) keeps the source geometry. Presets and custom sizes only for regular edits without a mask. |
| quality | optional | `very_low`, `low`, `medium` (default), or `high`. `very_low` only for outputs up to 4,194,304 pixels. |
| background | optional | `transparent` or `opaque`, regular edits only. |
| n | optional | Integer 1–8. Default 1. |
| seed | optional | Integer 0–2147483647. |

Both models reject any other field in `input` with an `unsupported fields` error. `callback_url` goes at the top level of the request.

## Pricing

Billing is per output image, so `n` multiplies the price. 1 credit = $0.005. The 2K tier covers outputs up to 4,194,304 pixels (2048×2048 in area); larger outputs bill at the 4K tier, which has no `very_low`.

### `ideogram-v4.6`

| Quality | 2K tier | 4K tier |
| --- | --- | --- |
| `very_low` | 1.6 credits ($0.008) | — |
| `low` | 6 credits ($0.03) | 12 credits ($0.06) |
| `medium` | 12 credits ($0.06) | 24 credits ($0.12) |
| `high` | 20 credits ($0.10) | 40 credits ($0.20) |

`auto` and the six presets bill at the 2K tier; a custom size bills by its area.

### `ideogram-v4.6-edit`

| Quality | 2K tier | 4K tier |
| --- | --- | --- |
| `very_low` | 1.6 credits ($0.008) | — |
| `low` | 6 credits ($0.03) | 12 credits ($0.06) |
| `medium` | 12 credits ($0.06) | 40 credits ($0.20) |
| `high` | 44 credits ($0.22) | 120 credits ($0.60) |

With `size: auto` the tier follows the source image's dimensions. Confirm current prices on the [model page](https://poyo.ai/models/ideogram-4-6?utm_source=github&utm_medium=readme&utm_campaign=ideogram-4.6-api).

## Writing Ideogram 4.6 prompts

- **Quote the words:** put every word that must appear on the image in quotes, such as `"NORTHBOUND JAZZ FESTIVAL"`, and say where it goes.
- **Say what stays:** for edits, name the one change and add "Keep everything else exactly the same."
- **Draft cheap, finish big:** iterate at `very_low` on a preset size, then rerun the same prompt at `high` with a custom size.
- **Mask small areas:** for a single line of text or one object, a mask with `context_window: auto` edits only that region at the source resolution.
- **Transparent assets:** describe the subject alone ("sticker only") and set `background` to `transparent`.

## Errors

Every response carries a business `code`. `200` is success; anything else is a failure, and some validation errors return HTTP 200 with `code: 400` in the body, so always check `code`. Both examples raise on either a non-2xx HTTP status or a non-success `code`.

| Code | Meaning |
| --- | --- |
| 400 | Invalid parameters, such as `very_low` above 4,194,304 pixels, `size` other than `auto` with a mask or `edit_precision: high`, or an unsupported field |
| 401 | Missing or invalid API key |
| 402 | Insufficient credits |
| 429 | Rate limit exceeded |
| 500, 502, 503 | Server or upstream error; retry with backoff |

## Async production flow

```text
submit -> persist data.task_id -> poll during development -> receive callback_url webhook in production
```

Treat `finished` and `failed` as terminal states. Images arrive in `files`, one entry per image with `file_url` and `file_type: image`. Generated files are available for 3 days, so copy them to your own storage after the task finishes. See [docs/production-notes.md](docs/production-notes.md) for limits and launch-day results.

## FAQ

**How much does the Ideogram 4.6 API cost?** Text-to-image costs 1.6 credits ($0.008) per image at `very_low` up to 40 credits ($0.20) at `high` above 4,194,304 pixels. Edits cost 1.6 credits ($0.008) to 120 credits ($0.60) per image.

**What counts as 2K and 4K?** Outputs up to 4,194,304 pixels (2048×2048 in area) bill at the 2K tier, and larger outputs at the 4K tier. `2304x3072` is 7,077,888 pixels, so it bills at 4K.

**Do I need a separate model ID for editing?** Yes. Use `ideogram-v4.6-edit` with exactly one image in `image_urls`.

**What is the difference between high-precision and localized edits?** `edit_precision: high` edits the whole image and restores the pixels you did not ask to change. Adding a mask and `context_window: auto` limits the edit to the region around the mask. Both keep the source resolution.

**Can it make transparent PNGs?** Yes. Set `background` to `transparent` on `ideogram-v4.6`, or on a regular edit with `ideogram-v4.6-edit`.

**Why was my `very_low` request rejected?** `very_low` is limited to outputs of at most 4,194,304 pixels. Use `low` or higher for larger sizes.

## Repository map

- [`payloads/`](payloads) — complete request bodies for each mode
- [`python/generate.py`](python/generate.py) — standard-library Python example
- [`node/index.mjs`](node/index.mjs) — dependency-free Node.js example
- [`curl/generate.md`](curl/generate.md) — copy-paste cURL requests
- [`docs/production-notes.md`](docs/production-notes.md) — limits, launch-day results, and rollout checklist

## Related repositories

- [GPT-Image-2.6-API](https://github.com/PoyoAPI/GPT-Image-2.6-API) — GPT Image 2.6 text-to-image and editing
- [MAI-Image-2.7-API](https://github.com/PoyoAPI/MAI-Image-2.7-API) — MAI Image 2.7 with transparent backgrounds and custom sizes
- [awesome-poyo-api](https://github.com/PoyoAPI/awesome-poyo-api) — every PoYo model repository in one list
- [poyo-devtools](https://github.com/PoyoAPI/poyo-devtools) — PoYo CLI, MCP bridge, and Agent Skill

## Links

- [Ideogram 4.6 API on PoYo](https://poyo.ai/models/ideogram-4-6?utm_source=github&utm_medium=readme&utm_campaign=ideogram-4.6-api)
- [Ideogram 4.6 API reference](https://docs.poyo.ai/api-manual/image-series/ideogram-v4-6?utm_source=github&utm_medium=readme&utm_campaign=ideogram-4.6-api)
- [Ideogram 4.6 Edit API reference](https://docs.poyo.ai/api-manual/image-series/ideogram-v4-6-edit?utm_source=github&utm_medium=readme&utm_campaign=ideogram-4.6-api)
- [PoYo model catalog](https://poyo.ai/models?utm_source=github&utm_medium=readme&utm_campaign=ideogram-4.6-api)

## License

MIT
