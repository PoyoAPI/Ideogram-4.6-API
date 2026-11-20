# Ideogram 4.6 API: cURL quickstart

```bash
export POYO_API_KEY="your-api-key"
export POYO_BASE_URL="https://api.poyo.ai"
```

## Text-to-image

```bash
curl -X POST "$POYO_BASE_URL/api/generate/submit" \
  -H "Authorization: Bearer $POYO_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
  "model": "ideogram-v4.6",
  "input": {
    "prompt": "A colorful storefront with a neon sign reading \"HELLO\"",
    "size": "16:9",
    "quality": "medium"
  }
}'
```

`quality` is `very_low`, `low`, `medium` (default), or `high`. Presets and `auto` bill at the 2K tier, so this request costs 12 credits ($0.06).

## Draft, then render at 4K

```bash
curl -X POST "$POYO_BASE_URL/api/generate/submit" \
  -H "Authorization: Bearer $POYO_API_KEY" \
  -H "Content-Type: application/json" \
  -d @payloads/ideogram-v4.6-text-to-image-draft.json

curl -X POST "$POYO_BASE_URL/api/generate/submit" \
  -H "Authorization: Bearer $POYO_API_KEY" \
  -H "Content-Type: application/json" \
  -d @payloads/ideogram-v4.6-text-to-image-4k.json
```

Both use the same poster prompt. The draft is `3:4` at `very_low` (768×1024, 1.6 credits); the final is `2304x3072` at `high` (40 credits). `very_low` is rejected above 4,194,304 pixels.

## Transparent background

```bash
curl -X POST "$POYO_BASE_URL/api/generate/submit" \
  -H "Authorization: Bearer $POYO_API_KEY" \
  -H "Content-Type: application/json" \
  -d @payloads/ideogram-v4.6-transparent-background.json
```

`background: "transparent"` returns an image with an alpha channel. `seed` makes the result repeatable.

## High-precision edit

```bash
curl -X POST "$POYO_BASE_URL/api/generate/submit" \
  -H "Authorization: Bearer $POYO_API_KEY" \
  -H "Content-Type: application/json" \
  -d @payloads/ideogram-v4.6-edit-high-precision.json
```

`edit_precision: high` edits the whole image, restores unchanged pixels, and keeps the source resolution. It requires `size: auto` and rejects `background`. The 1536×2048 source bills at the 2K tier: 44 credits at `high`.

## Localized edit with a mask

```bash
curl -X POST "$POYO_BASE_URL/api/generate/submit" \
  -H "Authorization: Bearer $POYO_API_KEY" \
  -H "Content-Type: application/json" \
  -d @payloads/ideogram-v4.6-edit-mask-localized.json
```

The mask is the same size as the source, black over the date line and white everywhere else. `context_window: auto` needs `mask_url` and `edit_precision: high`, and edits only the region around the mask. With a mask, `reference_image_urls` holds at most 3 images.

## Check status

Save `data.task_id` from the submit response, then poll:

```bash
curl "$POYO_BASE_URL/api/generate/status/<task_id>" \
  -H "Authorization: Bearer $POYO_API_KEY"
```

For production, add a public HTTPS `callback_url` to the top-level request and make the receiver idempotent.

See the [full README](../README.md) and [production notes](../docs/production-notes.md).
