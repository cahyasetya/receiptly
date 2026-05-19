# Receiptly

Receiptly is a powerful, offline-first Flutter application designed to simplify expense tracking. By capturing a photo of your receipt, Receiptly uses advanced OCR (Optical Character Recognition) to extract the merchant's name and the total amount, automatically suggesting a category for your expense.

## Features

- **Smart OCR:** Automatically extracts Merchant Name and Total Amount from receipt photos using Google ML Kit.
- **Auto-Categorization:** Intelligent keyword-based categorization (e.g., "Starbucks" -> Food, "Shell" -> Transport).
- **Manual Review:** Review and edit extracted data and categories before saving.
- **Offline Storage:** All your data stays on your device in a local SQLite database.
- **Expense History:** View a summarized list of all your tracked expenses.

## Prerequisites

Before running the project, ensure you have the following installed:

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.12.0 or higher recommended)
- [Android Studio](https://developer.android.com/studio) or [VS Code](https://code.visualstudio.com/) with Flutter extensions.
- Java Development Kit (JDK) 17.

## How to Run on an Android Device

### 1. Enable Developer Options & USB Debugging
On your physical Android device:
1. Go to **Settings > About Phone**.
2. Tap **Build Number** 7 times until you see "You are now a developer".
3. Go back to **Settings > System > Developer Options**.
4. Enable **USB Debugging**.

### 2. Connect Your Device
Connect your Android device to your computer via a USB cable. If prompted on the phone, authorize the computer for debugging.

### 3. Verify Connection
Run the following command in your terminal:
```bash
flutter devices
```
You should see your device listed in the output.

### 4. Run the App
Navigate to the `receiptly_app` directory and run:
```bash
cd receiptly_app
flutter run
```

*Note: The first build might take a few minutes as it downloads dependencies and builds the APK.*

## Project Structure

- `lib/models/`: Data models for Expenses and Categories.
- `lib/screens/`: App screens (Home, Camera, OCR Review, Categorize).
- `lib/services/`: Core logic for Database, OCR, and Categorization.
- `lib/widgets/`: Reusable UI components.

## Permissions

The app requires the following Android permissions (already configured in `AndroidManifest.xml`):
- `CAMERA`: To take photos of receipts.
- `READ_EXTERNAL_STORAGE` / `WRITE_EXTERNAL_STORAGE`: To handle image files temporarily for processing.

## License

This project is for demonstration purposes.
