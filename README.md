# Anuvaad (Android app)

Two-way voice translation for English, Hindi and Gujarati. Flutter app for Android, powered by REA Intelligence.

## Develop

- Flutter stable (3.47+), JDK 17, Android SDK with platform `android-37`.
- `flutter pub get`, then `dart run build_runner build --delete-conflicting-outputs` for generated models.
- `flutter test` runs unit and widget tests. `flutter analyze` must stay clean.

Notes:

- `android/gradle.properties` sets `kotlin.incremental=false` because Kotlin's incremental cache fails when the pub cache and the project are on different Windows drives.
- `compileSdk` is 37 because `permission_handler_android` requires it. `minSdk` is 29.

Design and plans live outside this repo in the Anuvaad project folder (`docs/specs`, `docs/superpowers/plans`).
