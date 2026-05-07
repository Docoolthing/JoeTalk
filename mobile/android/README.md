# Android host for JoeTalk (Flutter)

## Prerequisites

- [Flutter](https://docs.flutter.dev/get-started) stable SDK on your `PATH`
- Android Studio or Android command-line tools (SDK, `adb`)

## Regenerate the scaffold (if ever needed)

From the `mobile/` directory:

```sh
flutter create --platforms=android --project-name joe_talk_mobile .
```

## Run (debug, device or emulator)

```sh
cd mobile
flutter run
```

## Release build

1. **Version** — bump `version` in `../pubspec.yaml` (`1.0.0+1` → `name+buildNumber`).

2. **Application ID** — `com.joetalk.mobile` in `app/build.gradle.kts`. To change the ID, also move `MainActivity` under a matching `kotlin/.../MainActivity` package and set `namespace`.

3. **Release signing (Play / sideload)**  
   - Create a keystore and copy `android/key.properties.example` to `android/key.properties` (see comments inside; **never commit** `key.properties` or keystore).  
   - `storeFile` is usually relative to `android/app/`, e.g. `../upload-keystore.jks` with the JKS in `android/`.

4. **Backend URL**  
   - Release sets `usesCleartextTraffic="false"`; use an **HTTPS** production API, or the app will not be able to call a plain `http://` host.  
   - Debug / profile allow cleartext so local HTTP (e.g. `10.0.2.2:3000`) still works.  
   - You can set `BACKEND_BASE_URL` at build time:  
     `flutter build appbundle --dart-define=BACKEND_BASE_URL=https://api.example.com`

5. **Build artifacts**

   ```sh
   flutter build appbundle
   # or
   flutter build apk
   ```

   Outputs: `build/app/outputs/bundle/release/` and `build/app/outputs/flutter-apk/`.

6. **Play Console** — upload the **AAB**, complete store listing, privacy policy, and permissions declarations (`INTERNET`, `RECORD_AUDIO`).

## Permissions

- `INTERNET` — call backend `/api/chat`
- `RECORD_AUDIO` — speech-to-text

Users must allow the microphone in system settings; the app uses `permission_handler` at runtime as well.

## Troubleshooting

- **NDK / `[CXX1101] ... did not have a source.properties file`** — A broken Android NDK install in your SDK. Delete the folder the error names under `%LOCALAPPDATA%\Android\Sdk\ndk\` and re-run the build, or (re)install the NDK in Android Studio **SDK Manager → SDK Tools** so Gradle can download a valid copy.
