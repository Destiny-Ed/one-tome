# OneTome

**One book. Finish it.**

Local-first Flutter PDF reader that enforces one active book at a time. Designed to feel like reading a physical hard copy — one book, daily progress, no unfinished piles.

## Features

- Strict one-book rule (no second book until the first is finished)
- Daily reading goal with progress gating and “done for today”
- Streaks, highlights/annotations with export
- Page-curl turn animation, night-shift reader filter
- Explicit “Complete book” → confetti celebration
- Premium glass UI, full dark/light themes
- Completely offline-first (optional cloud sync later)

## Store distribution

### Android signing

1. Generate an upload keystore (once):

```bash
keytool -genkey -v -keystore android/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

2. Create `android/key.properties` (gitignored) from the template:

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=../upload-keystore.jks
```

3. Build the release bundle:

```bash
flutter build appbundle --release
```

The release build enables R8 minification + resource shrinking using `android/app/proguard-rules.pro`.

### iOS

Purpose strings are already in `ios/Runner/Info.plist`:

- Photo Library (PDF import)
- Documents folder
- Background modes for notifications

Set your bundle identifier, capabilities (Push Notifications if using remote, Background Modes), and signing in Xcode, then:

```bash
flutter build ipa --release
```

### Permissions summary

**Android** (`AndroidManifest.xml`):
- `POST_NOTIFICATIONS`, `VIBRATE`, `RECEIVE_BOOT_COMPLETED`, `SCHEDULE_EXACT_ALARM`
- Legacy + modern media/storage read permissions for file picker

**iOS** (`Info.plist`):
- `NSPhotoLibraryUsageDescription`
- `NSDocumentsFolderUsageDescription`
- `UIBackgroundModes` (fetch, remote-notification)

## Development

```bash
flutter pub get
flutter run
```

Requires Flutter 3.16+.

## License

Private / all rights reserved.
