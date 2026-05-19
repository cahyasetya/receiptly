---
name: receipt-processing
description: Receipt scanning, OCR text recognition, and expense tracking domain knowledge
---

## Receipt Processing Pipeline

1. **Image Capture** — Camera or gallery image via `image_picker`
2. **OCR** — Text recognition via `google_mlkit_text_recognition`
3. **Data Extraction** — Parse raw text for items, prices, totals, dates, merchants
4. **Storage** — Persist to local SQLite database via `sqflite`

## Database

- Local SQLite database using `sqflite` package
- Tables: receipts, items, categories
- See `lib/data/database/` for schema definitions

## Key Dependencies

- `image_picker` — Camera/gallery image selection
- `google_mlkit_text_recognition` — OCR text extraction
- `sqflite` — Local SQLite database
- `intl` — Date/number formatting and localization
- `path_provider` — File system paths
