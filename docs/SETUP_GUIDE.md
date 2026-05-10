# FlashChat Setup Guide

## 1. Purpose

This guide explains how to use FlashChat in two different ways:

- as an end user who only wants to download and open the app
- as a developer who wants to run or build the project locally

If you are new to development, start with the end-user sections first.

## 2. If You Only Want To Download The App

The easiest way to get FlashChat is from the GitHub Releases page.

### Android

1. Open the repository on GitHub.
2. Go to the `Releases` section.
3. Download the latest file that ends with:
   `-android-release.apk`
4. Move the file to your Android phone if needed.
5. Open the APK on the phone.
6. If Android warns that the app comes from an unknown source, allow installation for that file source.
7. Finish the installation and open the app.

### Windows

1. Open the repository on GitHub.
2. Go to the `Releases` section.
3. Download the latest file that ends with:
   `-windows.zip`
4. Extract the ZIP file to a folder on your computer.
5. Open the extracted folder.
6. Run `flashchat.exe`.

If Windows SmartScreen appears, choose:

- `More info`
- `Run anyway`

This can happen for unsigned desktop builds distributed outside an app store.

## 3. If You Want To Run The Project Locally

You need:

- Git
- Flutter SDK
- Android Studio or Visual Studio Code
- Android SDK for Android builds
- Visual Studio with Desktop development with C++ for Windows builds

## 4. Download The Project

1. Install Git if you do not already have it.
2. Clone the repository:

```bash
git clone https://github.com/flennium/FlashChat.git
```

3. Open the project folder.

## 5. Install Flutter

1. Download Flutter from the official Flutter website.
2. Extract it to a folder on your computer.
3. Add Flutter to your system `PATH`.
4. Run:

```bash
flutter doctor
```

5. Follow Flutter's instructions until the important checks are green.

## 6. Install Android Build Tools

For Android development:

1. Install Android Studio.
2. Open Android Studio once so it can install the Android SDK.
3. Accept any SDK licenses if prompted.
4. Verify the setup:

```bash
flutter doctor
```

## 7. Install Windows Build Tools

For Windows desktop development:

1. Install Visual Studio Community.
2. During installation, select:
   `Desktop development with C++`
3. After installation, run:

```bash
flutter doctor
```

Flutter should confirm Windows desktop tooling is available.

## 8. Project Configuration Files

This repository does not commit sensitive Firebase files.

For local development, you need:

- `lib/firebase_options.dart`
- `android/app/google-services.json` for Android builds
- `.env.local`

The repository already includes:

- `.env.github.example`
- `scripts/flutter-with-env.ps1`

## 9. Local Environment File

Create a file named:

- `.env.local`

It should contain:

```env
SUPABASE_URL=
SUPABASE_ANON_KEY=
SUPABASE_AVATAR_BUCKET=avatars
SUPABASE_CHAT_IMAGE_BUCKET=chat-images
GOOGLE_WEB_CLIENT_ID=
```

This file is ignored by Git and is only for your machine.

## 10. Install Project Dependencies

In the project folder, run:

```bash
flutter pub get
```

## 11. Run The App Locally

### Windows PowerShell

To run with the environment values from `.env.local`:

```powershell
.\scripts\flutter-with-env.ps1 run
```

### Standard Flutter

If you prefer running Flutter manually, you must pass the same values yourself with `--dart-define`.

## 12. Build Android Locally

### Recommended command

```powershell
.\scripts\flutter-with-env.ps1 build apk --release
```

### Output

The APK is created at:

`build/app/outputs/flutter-apk/app-release.apk`

## 13. Build Windows Locally

### Recommended command

```powershell
.\scripts\flutter-with-env.ps1 build windows --release
```

### Output

The Windows executable bundle is created under:

`build/windows/x64/runner/Release/`

To share it with another user, compress that folder into a ZIP file.

## 14. Run Checks Before Publishing

Use:

```bash
flutter analyze
flutter test
```

## 15. GitHub Actions Builds

This repository includes GitHub Actions workflows for:

- build and test
- Android release publishing
- Windows release publishing

The required GitHub secrets are documented in:

- `.env.github.example`
- `docs/CONFIGURATION_AND_SECURITY.md`

## 16. GitHub Releases Workflow

To publish a new release:

1. Update `version:` in `pubspec.yaml`
2. Commit the version change
3. Create a matching tag:

```bash
git tag v0.1.1
git push origin v0.1.1
```

4. GitHub Actions will build:
   - Android APK
   - Windows ZIP
5. Both files will be attached to the GitHub Release page.

## 17. Troubleshooting

### `Missing FIREBASE_OPTIONS_DART secret`

Add the `FIREBASE_OPTIONS_DART` repository secret in GitHub Actions.

### `Missing GOOGLE_SERVICES_JSON secret`

Add the `GOOGLE_SERVICES_JSON` repository secret in GitHub Actions.

### App builds but some features do not work

Check that `.env.local` contains the required values and that you used the wrapper script or matching `--dart-define` values.

### Windows build fails

Check `flutter doctor` and verify Visual Studio Desktop C++ tools are installed.

### Android build fails

Check:

- Android Studio installation
- Android SDK
- local `google-services.json`
- accepted Android licenses

