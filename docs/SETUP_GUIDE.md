# FlashChat Setup Guide

This guide is for running FlashChat locally for testing and development.

It covers:

- what you need installed
- which local files and environment values are required
- how to run Android and Windows builds
- how to verify the app is working after first launch

## 1. What You Need

Required:

- Git
- Flutter SDK
- a code editor such as VS Code or Android Studio

Platform-specific:

- Android:
  - Android Studio
  - Android SDK
  - a physical Android device or emulator
- Windows desktop:
  - Visual Studio Community or Professional
  - `Desktop development with C++` workload

Useful check:

```bash
flutter doctor
```

Before trying to run the app, make sure `flutter doctor` is mostly clean for the platform you want to use.

## 2. Clone The Project

```bash
git clone https://github.com/flennium/FlashChat.git
cd FlashChat
```

## 3. Install Flutter Packages

```bash
flutter pub get
```

## 4. Firebase Files You Need

FlashChat depends on Firebase client configuration.

Important files:

- `lib/firebase_options.dart`
- `android/app/google-services.json` for Android builds

Current repo note:

- `lib/firebase_options.dart` may already be present in your copy of the repo
- if you want to use a different Firebase project, replace it with your own FlutterFire-generated file

Android note:

- `google-services.json` must match the same Firebase project as `lib/firebase_options.dart`
- for this app, the Android package name is `com.example.flashchat`

## 5. Local Environment Values

This project uses Dart defines for Supabase and web auth config.

Create a file named:

- `.env.local`

Example:

```env
SUPABASE_URL=
SUPABASE_ANON_KEY=
SUPABASE_AVATAR_BUCKET=avatars
SUPABASE_CHAT_IMAGE_BUCKET=chat-images
GOOGLE_WEB_CLIENT_ID=
```

What these are used for:

- `SUPABASE_URL`: Supabase project URL
- `SUPABASE_ANON_KEY`: public anon key for uploads
- `SUPABASE_AVATAR_BUCKET`: storage bucket for user and room avatars
- `SUPABASE_CHAT_IMAGE_BUCKET`: storage bucket for chat images
- `GOOGLE_WEB_CLIENT_ID`: needed for Google sign-in on supported platforms

The helper script `scripts/flutter-with-env.ps1` reads this file and passes the values into Flutter automatically.

## 6. Recommended Run Command

On Windows PowerShell, use:

```powershell
.\scripts\flutter-with-env.ps1 run
```

That script will:

- load `.env.local`
- verify all required keys are present
- pass them to Flutter with `--dart-define`

If `.env.local` is missing or incomplete, the script will stop and show which key is missing.

## 7. Run On Android

1. Make sure `android/app/google-services.json` exists
2. Start an emulator or connect a phone
3. Check that Flutter sees the device:

```bash
flutter devices
```

4. Run the app:

```powershell
.\scripts\flutter-with-env.ps1 run
```

If you have multiple devices:

```powershell
.\scripts\flutter-with-env.ps1 run -d <device-id>
```

## 8. Run On Windows Desktop

1. Make sure Visual Studio with `Desktop development with C++` is installed
2. Verify Windows tooling:

```bash
flutter doctor
```

3. Run the desktop app:

```powershell
.\scripts\flutter-with-env.ps1 run -d windows
```

Important desktop note:

- this project maps desktop Firebase initialization to the web Firebase options in `lib/core/utils/firebase_platform_options.dart`
- because of that, the Firebase web configuration inside `lib/firebase_options.dart` must also be valid

## 9. First-Run Test Checklist

After the app launches, use this checklist:

1. Sign up with a brand new test account through the app
2. Confirm login succeeds
3. Open Firestore and verify these collections begin to appear as the app writes data:
   - `users`
   - `usernames`
   - `rooms`
4. Create a room
5. Open the room
6. Send a text message
7. If Supabase is configured, try uploading:
   - a profile avatar
   - a room avatar
   - a chat image

Why this matters:

- creating a Firebase Auth user from the Firebase Console does not automatically create the Firestore `users` or `usernames` documents
- those documents are created by the app flow itself

## 10. Firebase Checks If Something Looks Broken

If the app opens but behavior looks wrong, check these:

### Firestore

Make sure the app can read and write:

- `users`
- `usernames`
- `rooms`
- `rooms/{roomId}/messages`
- `rooms/{roomId}/members`
- `app/config`

Important admin config:

- collection: `app`
- document: `config`
- field: `roomAdminEmail`

### Realtime Database

Presence and typing depend on Realtime Database.

Expected path:

- `/presence`

If presence is not updating, check that:

- the database URL inside `lib/firebase_options.dart` is correct
- the signed-in user can write presence data

### Supabase Storage

Media uploads need:

- a valid `SUPABASE_URL`
- a valid `SUPABASE_ANON_KEY`
- the buckets from `.env.local` to exist

Expected buckets:

- `avatars`
- `chat-images`

## 11. Local Build Commands

### Android debug run

```powershell
.\scripts\flutter-with-env.ps1 run -d android
```

### Android release APK

```powershell
.\scripts\flutter-with-env.ps1 build apk --release
```

Output:

- `build/app/outputs/flutter-apk/app-release.apk`

### Windows release build

```powershell
.\scripts\flutter-with-env.ps1 build windows --release
```

Output:

- `build/windows/x64/runner/Release/`

## 12. Android Release Signing For Local Release Builds

You only need this for a properly signed release APK.

Required environment variables:

- `ANDROID_KEYSTORE_PATH`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

Optional strict check:

- `REQUIRE_RELEASE_SIGNING=true`

What happens without them:

- local release builds can fall back to debug signing
- GitHub Actions is intended to use the real release keystore instead

If you want local release APKs signed exactly like CI, set those environment variables before building.

## 13. Manual Flutter Command Example

If you do not want to use the PowerShell helper script, you must pass every define yourself:

```bash
flutter run ^
  --dart-define=SUPABASE_URL=... ^
  --dart-define=SUPABASE_ANON_KEY=... ^
  --dart-define=SUPABASE_AVATAR_BUCKET=avatars ^
  --dart-define=SUPABASE_CHAT_IMAGE_BUCKET=chat-images ^
  --dart-define=GOOGLE_WEB_CLIENT_ID=...
```

Using the script is easier and avoids mistakes.

## 14. Useful Validation Commands

```bash
flutter analyze
flutter test
```

Run these before pushing important changes.

## 15. Common Problems

### `Missing .env.local`

Create `.env.local` in the project root and add all required keys.

### `Missing 'SUPABASE_URL' in .env.local`

The helper script validates the file before starting Flutter. Add the missing key and retry.

### Google sign-in does not work

Check:

- `GOOGLE_WEB_CLIENT_ID`
- Firebase Auth provider setup
- matching Firebase configuration files

### App signs in but Firestore collections do not appear

Create the user through the app, not only from Firebase Console.

### Android build fails

Check:

- `android/app/google-services.json`
- Android SDK setup
- accepted Android SDK licenses

### Windows build fails

Check:

- Visual Studio installation
- `Desktop development with C++` workload
- `flutter doctor`

## 16. Related Docs

- [Architecture](ARCHITECTURE_README.md)
- [Backend](BACKEND_README.md)
- [Data Model](DATA_MODEL_README.md)
- [Features](FEATURES_README.md)
- [Configuration And Security](CONFIGURATION_AND_SECURITY.md)
