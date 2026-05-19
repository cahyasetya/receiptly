---
name: flutter-build
description: Build, analyze, and test Flutter/Dart projects with proper commands
---

## Build Commands

- Analyze: `dart analyze lib/`
- Format: `dart format lib/ test/`
- Test: `flutter test --reporter expanded`
- Test single file: `flutter test test/path/to/test.dart`
- Build APK: `flutter build apk --debug`
- Build iOS: `flutter build ios --debug`
- Build runner: `dart run build_runner build --delete-conflicting-outputs`

## Project Structure

- `lib/` — Application source code
- `test/` — Tests mirroring `lib/` structure
- `android/` — Android platform config
- `ios/` — iOS platform config

## State Management

This project uses standard Flutter state management patterns. Check `lib/` for the specific approach used.
