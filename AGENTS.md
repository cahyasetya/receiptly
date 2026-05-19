# Receiptly — Aplikasi Scan Nota Belanja

Aplikasi Flutter Android untuk memindai nota belanja menggunakan AI OCR (OpenRouter),
mengkategorikan pengeluaran per-item, dan melacak pengeluaran harian dalam Rupiah (Rp).

- **Platform:** Android only
- **Locale:** Indonesia (`id_ID`), Rupiah (Rp)
- **OCR:** AI via OpenRouter API (tidak pakai ML Kit)
- **SDK:** Dart ^3.12.0 / Flutter stable

## Struktur Direktori

```
lib/
  main.dart                          Entry point, navigatorKey untuk share intent
  utils/
    logger.dart                      Logger (debugPrint + dart:developer)
  rules/
    categorization_rules.dart        Keyword/regex rules untuk kategorisasi
    ai_models.dart                   Preset model AI (free & paid)
  models/
    expense.dart                     Expense + ExpenseItem (customCategoryName)
    expense_category.dart            Enum kategori (built-in fallback)
    ocr_data.dart                    OCRItem + OCRResult + InputMode enum
    category.dart                    Category model + seed data (16 default)
    credit_info.dart                 CreditInfo dari OpenRouter API
    receipt_type.dart                ReceiptType enum (itemized/summary)
    index.dart                       Barrel export
  services/
    database_service.dart            SQLite singleton (sqflite + migrations)
    expense_repository.dart          Layer abstraksi database
    ai_ocr_service.dart              OCR via OpenRouter AI + CreditInfo fetch
    categorization_service.dart      Kategorisasi item berdasarkan rules
    google_sheets_service.dart       Google Sheets sync
    share_handler.dart               Handle shared images via receive_sharing_intent
    migrations.dart                  Schema migrations (v1-v8)
    parsers/
      receipt_parser.dart            Abstract parser
      itemized_parser.dart           Items with individual prices
      summary_parser.dart            Items without prices (combine + total)
      parser_factory.dart            Auto-detect receipt type
      index.dart                     Barrel export
    index.dart                       Barrel export
  screens/
    home_screen.dart                 Daftar expense + grafik + budget progress
    ocr_screen.dart                  AI OCR processing
    categorize_screen.dart           Kategorisasi per-item + simpan
    camera_screen.dart               Pilih foto (kamera/galeri) + crop optional
    crop_screen.dart                 Crop image (crop_your_image library)
    input_mode_picker_screen.dart    Pilih input: AI Scan / Manual
    manual_entry_screen.dart         Input item manual
    settings_screen.dart             Menu settings (AI, kategori, sync)
    ai_settings_screen.dart          Model selection + credit info
    category_manager_screen.dart     CRUD kategori + budget
    sync_screen.dart                 Google Sheets sync UI
  widgets/
    expense_card.dart                Kartu expense
    category_selector.dart           Pemilih kategori (built-in + custom)
    category_chart.dart              Pie chart pengeluaran per kategori
    budget_progress.dart             Progress bar budget per kategori
    index.dart                       Barrel export
android/
  app/src/main/kotlin/com/receiptly/app/MainActivity.kt
  app/src/main/AndroidManifest.xml   Intent filter SEND image/*
test/
  widget_test.dart                   Smoke test
```

## Alur Aplikasi

```
InputModePicker
  ├─ AI Scan → Camera → (crop?) → OCRScreen → AI OCR → CategorizeScreen → save
  └─ Manual → ManualEntryScreen → CategorizeScreen → save

Share image from other app → ShareHandler → OCRScreen → same flow
```

## Konvensi Kode

### State Management
- `StatefulWidget` + `setState` — no external state management

### Database
- `sqflite` singleton (`DatabaseService`)
- Tables: `expenses`, `settings`, `categories`, `budgets`
- All queries use `Future`/`async`
- Schema versioning via `migrations.dart` (current: v8)

### Categories
- All categories stored in `categories` table (built-in + custom)
- 16 default categories seeded on fresh install
- Budget amount stored directly in category (`budget_amount` column)
- `ExpenseCategory` enum for internal backward compat

### AI OCR
- `POST https://openrouter.ai/api/v1/chat/completions`
- Response contains `type` (itemized/summary), `items[]`, `total`
- ParserFactory detects type → routes to ItemizedParser or SummaryParser
- Categories included in AI prompt dynamically from DB

### Parsers (Strategy Pattern)
- `ItemizedReceiptParser` — each item has own price
- `SummaryReceiptParser` — only total, combine all items into one

### Logger
- `debugPrint` for terminal + `dart:developer` for DevTools

### Share Intent
- AndroidManifest.xml: `ACTION_SEND` with `image/*`
- `receive_sharing_intent` package handles intent data
- `ShareHandler` copies shared file to temp, triggers OCR

### Google Sheets Sync
- OAuth2 via `google_sign_in`
- Data pushed to: Expenses sheet, Categories sheet
- Sheet ID saved to settings

## Dependensi Utama

| Paket | Kegunaan |
|---|---|
| `image_picker` | Pilih foto dari kamera/galeri |
| `crop_your_image` | Crop image (pure Dart) |
| `receive_sharing_intent` | Terima shared image dari app lain |
| `sqflite` | Database SQLite lokal |
| `fl_chart` | Pie chart pengeluaran |
| `http` | HTTP client untuk OpenRouter |
| `flutter_dotenv` | Load .env untuk API key |
| `google_sign_in` + `googleapis` | Google Sheets sync |
| `intl` | Format angka & tanggal Indonesia |
| `flutter_localizations` | Lokalisasi UI (id_ID) |

## Perintah Berguna

```bash
flutter test                    # Jalankan semua test
dart analyze lib/               # Analisis kode statis
flutter build apk --debug       # Build APK debug (Android)
dart format lib/ test/          # Format kode
```
