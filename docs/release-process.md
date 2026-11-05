# Releasing Anuvaad

Every release is a signed set of APKs on this repo's GitHub Releases page. The app checks for new releases, shows the "What's new / Fixed" notes in a popup, and installs the update after the user confirms. The website's Download page lists the same releases.

## One-time setup

### 1. Create the release signing key (owner only)

Every release must be signed with the **same key forever**. If the key is lost, installed apps can never be updated again: people would have to uninstall and reinstall.

```bash
keytool -genkeypair -keystore anuvaad-release.jks -storetype PKCS12 \
  -keyalg RSA -keysize 4096 -validity 10000 -alias anuvaad
```

- Choose a strong password. Store the file **and** the password in two separate safe places, such as a password manager and an offline USB drive.
- Never commit the `.jks` file or the password. `.gitignore` already blocks `*.jks`, `*.keystore` and `android/key.properties`.

### 2. Add the GitHub secrets and variables

In the GitHub repo, go to **Settings → Secrets and variables → Actions**.

| Kind | Name | Value |
|---|---|---|
| Secret | `ANDROID_KEYSTORE_BASE64` | The keystore as base64 (`base64 -w0 anuvaad-release.jks`, or PowerShell `[Convert]::ToBase64String([IO.File]::ReadAllBytes("anuvaad-release.jks"))`) |
| Secret | `ANDROID_KEYSTORE_PASSWORD` | Keystore password |
| Secret | `ANDROID_KEY_ALIAS` | `anuvaad` (or the alias you chose) |
| Secret | `ANDROID_KEY_PASSWORD` | Key password (same as the keystore password if you used one) |
| Secret | `REVALIDATE_SECRET` | The same random value set on Vercel |
| Variable | `API_BASE_URL` | The website, e.g. `https://<project>.vercel.app` |
| Variable | `WEB_REVALIDATE_URL` | `https://<project>.vercel.app/api/v1/revalidate` |

### 3. Optional: sign release builds on your own computer

Create `android/key.properties`. It is git-ignored.

```properties
storeFile=C:/path/to/anuvaad-release.jks
storePassword=...
keyAlias=anuvaad
keyPassword=...
```

Without a key, `flutter build apk --release` stops with "Release signing is not configured". That is deliberate: a debug-signed release could never be updated.

## Every release

1. **Bump the version** in `pubspec.yaml` to `X.Y.Z+BUILD`. BUILD must be higher than every earlier release.
2. **Add a CHANGELOG entry** at the top of `CHANGELOG.md`, in exactly this format:

   ```markdown
   ## 0.1.1 (2) — 2026-11-20
   Mandatory: no
   Min supported build: 1
   ### What's new
   - Short, user-facing sentence.
   ### Fixed
   - Short, user-facing sentence.
   ```

   - The version and build must match `pubspec.yaml`.
   - `Mandatory:` and `Min supported build:` are optional (defaults `no` and `1`). Builds below the minimum must update before using the app.
   - Only `### What's new` and `### Fixed` are allowed. Leave a section out if it is empty.
3. **Commit, tag and push:**

   ```bash
   git commit -am "release: 0.1.1"
   git tag v0.1.1
   git push origin main v0.1.1
   ```

4. **Watch the Release workflow** under GitHub → Actions. It runs the tests, builds four signed APKs, writes `release.json` and creates the GitHub Release.

   | APK | For |
   |---|---|
   | `anuvaad-X.Y.Z-arm64-v8a.apk` | Most phones |
   | `anuvaad-X.Y.Z-armeabi-v7a.apk` | Older 32-bit phones |
   | `anuvaad-X.Y.Z-x86_64.apk` | Emulators |
   | `anuvaad-X.Y.Z-universal.apk` | Any phone (larger) |

5. **Smoke-test the update** on a phone that has the previous version installed. Open the app, check the popup shows the right notes, tap **Update now**, confirm Android's install screen, then check "What's new" appears once.

## How versions are checked

- The app compares the installed build number with the latest release's build number.
- The workflow builds split APKs with `-P force-version-code-ignoring-abi=true`, so every APK's versionCode equals the pubspec build number. Without it, Flutter would add 1000 × ABI to each split APK.
- Each APK's size and SHA-256 are listed in `release.json`. The app refuses to install a download that doesn't match.

## If the app is ever published on Google Play

Google Play does not allow apps to update themselves from outside Play. A Play build must leave out the in-app updater and the `REQUEST_INSTALL_PACKAGES` permission.
