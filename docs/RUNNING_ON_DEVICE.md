# Running Tests on Android Emulator and iOS Simulator

This guide is the end-to-end reference for executing the test suite against a running Android emulator or iOS simulator on your local machine. It assumes your environment is already set up per `docs/SETUP_GUIDE.md`.

**Platform note:** iOS simulator steps require macOS + Xcode. Android emulator steps work on macOS and Windows.

---

## Quick Run

Everything already set up? Use these commands. Open **3 separate terminals**.

### Android

```bash
# Terminal 1 — start emulator
~/Library/Android/sdk/emulator/emulator -avd Pixel_7 -no-snapshot-load

# Wait for full boot, then suppress the 16KB compatibility dialog (ARM64/Apple Silicon only)
adb wait-for-device && adb shell getprop sys.boot_completed   # wait for: 1
adb shell settings put global show_16kb_compat_dialog 0

# Terminal 2 — start Appium (once emulator is booted)
ANDROID_HOME=~/Library/Android/sdk /opt/homebrew/bin/appium

# Terminal 3 — run tests
cd /Users/monmac/work/robotframework_automation
adb install -r app/android/mda-2.2.0-25.apk    # skip if already installed
.venv/bin/robot --variable PLATFORM:android --include smoke --outputdir results/smoke_android tests/
open results/smoke_android/report.html
```

> **Apple Silicon (ARM64) note:** The `adb shell settings put global show_16kb_compat_dialog 0` command suppresses the "Android App Compatibility" 16 KB page-size modal that blocks tests on ARM64 emulators (Android 15+). Run it once after each emulator boot. It is not needed on Windows/Intel.

### iOS (macOS only)

```bash
# Terminal 1 — boot simulator
xcrun simctl boot "iPhone 15 Pro" && open -a Simulator

# Terminal 2 — start Appium (once simulator is booted)
/opt/homebrew/bin/appium

# Terminal 3 — run tests
cd /Users/monmac/work/robotframework_automation
UDID=$(xcrun simctl list devices booted | grep "iPhone 15 Pro" | grep -oE '[A-F0-9-]{36}')
xcrun simctl install "$UDID" app/ios/SauceLabs-Demo-App.app
.venv/bin/robot --variable PLATFORM:ios --include smoke --outputdir results/smoke_ios tests/
open results/smoke_ios/report.html
```

---

## Current Emulator Configuration (verified)

| Parameter | Value |
|-----------|-------|
| Android version | 17 |
| API level | 37 |
| AVD name | `Pixel_7` |
| Device serial | `emulator-5554` |
| App under test | SauceLabs My Demo App v2.2.0 (`mda-2.2.0-25.apk`) |
| App package | `com.saucelabs.mydemoapp.android` |
| Launch activity | `...view.activities.SplashActivity` |
| Appium server | 3.3.1 |
| UiAutomator2 driver | 7.2.0 |

These values are the defaults in `config/android_capabilities.yaml`. Verify with:

```bash
adb shell getprop ro.build.version.release   # → 17
adb shell getprop ro.build.version.sdk       # → 37
adb devices                                  # → emulator-5554   device
/opt/homebrew/bin/appium --version           # → 3.3.1
/opt/homebrew/bin/appium driver list --installed   # → uiautomator2@7.2.0
```

---

## Video Recording

Every test automatically records a screen video. No extra setup is required.

**How it works:**
- `Start Test Video Recording` is called in every `Test Setup` — starts `adb screenrecord` on the device.
- `Stop And Save Test Video` is called first in every `Test Teardown` — stops recording, decodes the video, saves it to the output directory, and embeds it inline in `log.html`.
- Video files are named after the test: `TC001_-_Verify_Login_Page.mp4`, etc.

**After a run:**
```
results/smoke_android/
├── TC001_-_Verify_Login_Page_Is_Displayed.mp4
├── TC002_-_Login_With_Valid_Credentials_Should_Navigate_To_Home.mp4
├── TC003_-_Login_With_Invalid_Password_Should_Show_Error_Message.mp4
├── ...
├── log.html        ← videos embedded here (click test → expand teardown → play)
└── report.html
```

**To watch a video** — open `log.html`, expand any test, and play the embedded `<video>` player in the teardown step. Or open the `.mp4` file directly.

**Video settings** (defined in `Start Test Video Recording` in `resources/keywords/appium_keywords.robot`):

| Setting | Android | iOS |
|---------|---------|-----|
| Resolution | 1280 × 720 | device native |
| Bit rate | 4 Mbps | — |
| Max duration | 3 min (180 s) | 3 min (180 s) |
| Format | MP4 (H.264) | MP4 |
| Embedded in log | Yes | No |

---

## Table of Contents

1. [Android Emulator — macOS](#1-android-emulator--macos)
2. [Android Emulator — Windows](#2-android-emulator--windows)
3. [iOS Simulator — macOS only](#3-ios-simulator--macos-only)
4. [Finding Real Locators with Appium Inspector](#4-finding-real-locators-with-appium-inspector)
5. [Troubleshooting Emulator Runs](#5-troubleshooting-emulator-runs)

---

## 1. Android Emulator — macOS

### Step 1 — Download the Demo App APK

The test suite targets the **SauceLabs My Demo App** for Android.

```bash
# Recommended — uses the pinned URL in scripts/apps.yaml
SSL_CERT_FILE=$(python3 -c "import certifi; print(certifi.where())") \
  python3 scripts/download_apps.py --android

# Verify the download
ls -lh app/android/mda-2.2.0-25.apk
# Expected: -rw-r--r-- ... ~4MB ... app/android/mda-2.2.0-25.apk
```

> **macOS SSL note:** Python on macOS may fail with `CERTIFICATE_VERIFY_FAILED`. The `SSL_CERT_FILE` prefix above fixes it using `certifi` (installed with `pip install certifi`).

Alternatively, download manually with curl:

```bash
mkdir -p app/android
curl -fsSL \
  "https://github.com/saucelabs/my-demo-app-android/releases/download/2.2.0/mda-2.2.0-25.apk" \
  -o app/android/mda-2.2.0-25.apk
```

### Step 2 — Start the Android Emulator

The project uses the **Pixel_7** AVD. If you have a different AVD, substitute its name and update `platformVersion` in `config/android_capabilities.yaml` to match.

```bash
# List your available AVDs
~/Library/Android/sdk/emulator/emulator -list-avds
# Expected output includes: Pixel_7

# Launch the emulator (use the full path to avoid picking up an old version)
~/Library/Android/sdk/emulator/emulator -avd Pixel_7 -no-snapshot-load &

# Wait until fully booted (~60–90 s)
adb wait-for-device
adb shell getprop sys.boot_completed   # Expected: 1

# Confirm the serial
adb devices
# Expected:
# List of devices attached
# emulator-5554   device
```

Verify the Android version matches your capabilities file:

```bash
adb shell getprop ro.build.version.release   # → 17
adb shell getprop ro.build.version.sdk       # → 37
```

#### Suppress the 16KB compatibility dialog (ARM64 / Apple Silicon only)

On Apple Silicon Macs, ARM64 emulators running Android 15+ show an "Android App Compatibility" modal when launching apps that contain native libraries not yet aligned to the 16 KB page size. This dialog overlays the app UI and **blocks all tests**.

Suppress it once after each emulator boot:

```bash
adb shell settings put global show_16kb_compat_dialog 0
```

Verify it is suppressed:

```bash
adb shell settings get global show_16kb_compat_dialog   # → 0
```

> **Persistent alternative:** Open Developer Options on the emulator and toggle off **App compatibility check for 16 KB page size**. You can jump there via adb:
> ```bash
> adb shell am start -a android.settings.APPLICATION_DEVELOPMENT_SETTINGS
> ```
> This toggle survives reboots, but `show_16kb_compat_dialog` must be re-applied after each cold boot.

> **Windows / Intel note:** The dialog does not appear on x86_64 emulators. This step is macOS ARM64 only.

> **Tip:** The serial (`emulator-5554`) must match `deviceName` in `config/android_capabilities.yaml`. If you run multiple emulators, serials increment: `emulator-5554`, `emulator-5556`, etc.

### Step 3 — Install the APK on the Emulator

```bash
adb install -r app/android/mda-2.2.0-25.apk
# Expected: Performing Streamed Install
#           Success

# Verify the app is installed
adb shell pm list packages | grep saucelabs
# Expected: package:com.saucelabs.mydemoapp.android
```

### Step 4 — Configure Android Capabilities

`config/android_capabilities.yaml` is already set for the current emulator. The key fields are:

```yaml
capabilities:
  platformName: Android
  platformVersion: "16"            # Android 16 (Baklava) — API level 36
  deviceName: "emulator-5554"      # serial from: adb devices

  appPackage: "com.saucelabs.mydemoapp.android"
  appActivity: "com.saucelabs.mydemoapp.android.view.activities.SplashActivity"

  automationName: UiAutomator2
  noReset: false
  fullReset: false
  newCommandTimeout: 300
  disableWindowAnimation: true     # disables animations for faster, stable tests
  uiautomator2ServerLaunchTimeout: 60000
  uiautomator2ServerInstallTimeout: 60000
```

**To adapt to a different device**, change:

| Field | How to find the value |
|-------|-----------------------|
| `platformVersion` | `adb shell getprop ro.build.version.release` |
| `deviceName` | `adb devices` (copy the serial, e.g. `emulator-5554` or `R3CN90BXXXX`) |
| `appPackage` | `adb shell dumpsys window \| grep -E 'mCurrentFocus\|mFocusedApp'` (while app is open) |
| `appActivity` | same command as above |

> **Real device:** Replace `deviceName` with the USB serial from `adb devices -l`. Everything else stays the same.

### Step 5 — Start Appium

Open a **new terminal window** and leave Appium running there.

> **macOS note:** Use the full Homebrew path to ensure Appium 3.x is launched, not the old
> system-installed 1.x. `ANDROID_HOME` must be set so the UiAutomator2 driver can find `adb`.

```bash
ANDROID_HOME=~/Library/Android/sdk \
ANDROID_SDK_ROOT=~/Library/Android/sdk \
/opt/homebrew/bin/appium
# Expected:
# [Appium] Welcome to Appium v3.x.x
# [Appium] Appium REST http interface listener started on http://0.0.0.0:4723
```

> If you added `ANDROID_HOME` to `~/.zshrc` and opened a **fresh terminal**, you can just run `/opt/homebrew/bin/appium` without the prefixes.

Verify Appium is ready (from another terminal):

```bash
curl -s http://localhost:4723/status | python3 -m json.tool | grep '"ready"'
# Expected: "ready": true
```

### Step 6 — Run the Tests

Return to your project terminal (with the virtual environment active):

```bash
# Activate virtual environment (if not already active)
source .venv/bin/activate

# Run all smoke tests
python -m robot \
  --variable PLATFORM:android \
  --include smoke \
  --outputdir results/smoke_android \
  --loglevel INFO \
  tests/

# Run all regression tests
python -m robot \
  --variable PLATFORM:android \
  --include regression \
  --outputdir results/regression_android \
  tests/

# Run a specific test by xlsx test ID
python -m robot \
  --variable PLATFORM:android \
  --include TC-AND-001 \
  --outputdir results/tc_and_001 \
  tests/

# Run all tests (smoke + regression)
python -m robot \
  --variable PLATFORM:android \
  --outputdir results/full_android \
  tests/
```

### Step 7 — Open the Results Report

```bash
open results/smoke_android/report.html
```

---

## 2. Android Emulator — Windows

### Step 1 — Download the Demo App APK

**Command Prompt:**
```cmd
mkdir app\android

curl -fsSL "https://github.com/saucelabs/my-demo-app-android/releases/download/2.2.0/mda-2.2.0-25.apk" ^
  -o app\android\mda-2.2.0-25.apk
```

**PowerShell:**
```powershell
New-Item -ItemType Directory -Force -Path app\android

Invoke-WebRequest `
  -Uri "https://github.com/saucelabs/my-demo-app-android/releases/download/2.2.0/mda-2.2.0-25.apk" `
  -OutFile "app\android\mda-2.2.0-25.apk"
```

### Step 2 — Start the Android Emulator

Open **Android Studio → Device Manager** and click the **Play ▶** button next to your AVD. Or from the command line:

**Command Prompt:**
```cmd
:: List available AVDs
emulator -list-avds

:: Launch (substitute your AVD name)
start "" emulator -avd sdk_gphone64_x86_64

:: Wait for full boot, then check
adb wait-for-device
adb shell getprop sys.boot_completed
:: Expected: 1

:: Confirm serial
adb devices
:: Expected: emulator-5554   device
```

**PowerShell:**
```powershell
# Launch emulator in background
Start-Process emulator -ArgumentList "-avd", "sdk_gphone64_x86_64"

# Check connectivity (~60 sec after launch)
adb devices
# Expected: emulator-5554   device

# Verify Android version
adb shell getprop ro.build.version.release   # → 16
```

### Step 3 — Install the APK

```cmd
adb install -r app\android\mda-2.2.0-25.apk
:: Expected: Success
```

### Step 4 — Configure Capabilities

Edit `config/android_capabilities.yaml` exactly as shown in the macOS section above. The file is the same on both platforms.

### Step 5 — Start Appium

Open a **new terminal window**:

```cmd
appium
```

Verify Appium is ready in PowerShell:

```powershell
(Invoke-RestMethod http://localhost:4723/status).value.ready
# Expected: True
```

### Step 6 — Run the Tests

Activate the virtual environment first:

**Command Prompt:**
```cmd
.venv\Scripts\activate.bat

:: Run smoke tests
robot ^
  --variable PLATFORM:android ^
  --include smoke ^
  --outputdir results\smoke_android ^
  --loglevel INFO ^
  tests\

:: Run regression tests
robot ^
  --variable PLATFORM:android ^
  --include regression ^
  --outputdir results\regression_android ^
  tests\

:: Run a specific test by xlsx ID
robot --variable PLATFORM:android --include TC-AND-001 --outputdir results\tc_and_001 tests\
```

**PowerShell:**
```powershell
.venv\Scripts\Activate.ps1

robot `
  --variable PLATFORM:android `
  --include smoke `
  --outputdir results\smoke_android `
  --loglevel INFO `
  tests\
```

### Step 7 — Open the Results Report

```powershell
Start-Process results\smoke_android\report.html
# or
Invoke-Item results\smoke_android\report.html
```

---

## 3. iOS Simulator — macOS only

> **Windows users:** iOS automation requires macOS + Xcode. There is no Windows equivalent for the iOS simulator.

### Step 1 — Download the Demo App (Simulator Build)

The iOS simulator requires a `.app` bundle (not an `.ipa`). The SauceLabs Demo App ships as a zip containing the `.app`.

```bash
# Recommended — uses the pinned URL in scripts/apps.yaml
SSL_CERT_FILE=$(python3 -c "import certifi; print(certifi.where())") \
  python3 scripts/download_apps.py --ios

# Extract the .app bundle
unzip -q app/ios/SauceLabs-Demo-App.Simulator.zip -d app/ios/

# Verify
ls app/ios/
# Expected: SauceLabs-Demo-App.app  SauceLabs-Demo-App.Simulator.zip
```

Alternatively, download manually with curl:

```bash
mkdir -p app/ios
curl -fsSL \
  "https://github.com/saucelabs/my-demo-app-ios/releases/download/2.2.2/SauceLabs-Demo-App.Simulator.zip" \
  -o app/ios/SauceLabs-Demo-App.Simulator.zip
unzip -q app/ios/SauceLabs-Demo-App.Simulator.zip -d app/ios/
```

### Step 2 — Boot an iOS Simulator

```bash
# List available simulators — look for iPhone 15 Pro with iOS 17.x
xcrun simctl list devices available | grep "iPhone 15 Pro"
# Example output:
#     iPhone 15 Pro (D6F5A1B2-...) (Shutdown)

# Boot the simulator (use the name shown above)
xcrun simctl boot "iPhone 15 Pro"

# Open Simulator.app to see the window
open -a Simulator

# Wait until booted
xcrun simctl bootstatus "$(xcrun simctl list devices booted | grep 'iPhone 15 Pro' | awk '{print $NF}' | tr -d '()')" -b
```

Verify it is running:

```bash
xcrun simctl list devices | grep Booted
# Expected: iPhone 15 Pro (XXXXXXXX-...) (Booted)
```

### Step 3 — Install the App on the Simulator

```bash
# Find the booted simulator UDID
UDID=$(xcrun simctl list devices booted | grep "iPhone 15 Pro" | grep -oE '[A-F0-9-]{36}')
echo "Simulator UDID: $UDID"

# Install the .app bundle
xcrun simctl install "$UDID" app/ios/SauceLabs-Demo-App.app
echo "App installed"

# Verify
xcrun simctl listapps "$UDID" | grep saucelabs
# Expected: "com.saucelabs.mydemoapp.ios"
```

### Step 4 — Configure iOS Capabilities

Edit `config/ios_capabilities.yaml`:

```yaml
capabilities:
  platformName: iOS
  platformVersion: "17.2"              # check: xcrun simctl list runtimes
  deviceName: "iPhone 15 Pro"          # must match simulator name exactly
  udid: "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"   # from Step 3 above
  bundleId: "com.saucelabs.mydemoapp.ios"

  automationName: XCUITest
  noReset: false
  fullReset: false
  newCommandTimeout: 300
  usePrebuiltWDA: false
  wdaLaunchTimeout: 120000
  wdaConnectionTimeout: 120000

appium_server:
  url: "http://localhost:4723"
```

Get the exact UDID:

```bash
xcrun simctl list devices | grep "iPhone 15 Pro"
# Output: iPhone 15 Pro (D6F5A1B2-XXXX-XXXX-XXXX-XXXXXXXXXXXX) (Booted)
#                        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ copy this
```

### Step 5 — Start Appium

Open a new terminal:

```bash
appium
# Expected:
# [Appium] Welcome to Appium v2.x.x
# [Appium] Appium REST http interface listener started on http://0.0.0.0:4723
```

> **First run note:** XCUITest builds `WebDriverAgent` on first launch, which can take 3–5 minutes. Subsequent runs are much faster because it is cached on the simulator.

### Step 6 — Run the Tests

```bash
# Activate virtual environment
source .venv/bin/activate

# Run all iOS smoke tests
python -m robot \
  --variable PLATFORM:ios \
  --include smoke \
  --outputdir results/smoke_ios \
  --loglevel INFO \
  tests/

# Run all iOS regression tests
python -m robot \
  --variable PLATFORM:ios \
  --include regression \
  --outputdir results/regression_ios \
  tests/

# Run a specific test by xlsx ID
python -m robot \
  --variable PLATFORM:ios \
  --include TC-IOS-001 \
  --outputdir results/tc_ios_001 \
  tests/

# Run full suite (both platforms — requires both emulator and simulator running)
python -m robot \
  --variable PLATFORM:ios \
  --outputdir results/full_ios \
  tests/
```

### Step 7 — Open the Results Report

```bash
open results/smoke_ios/report.html
```

---

## 4. Finding Real Locators with Appium Inspector

All `accessibility_id` values in `resources/variables/common_variables.robot` are derived from the app at runtime. If your app differs from the defaults, use Appium Inspector to find the correct values.

### Install Appium Inspector

Download from: https://github.com/appium/appium-inspector/releases  
Choose the `.dmg` (macOS) or `.exe` (Windows) for the latest release.

### Connect to a Running Session

1. Start your emulator/simulator and install the app (Steps 1–3 above)
2. Start Appium: `appium`
3. Open Appium Inspector
4. Fill in **Remote Path** = `/` and **Remote Port** = `4723`
5. Under **Desired Capabilities**, paste your capabilities JSON:

**Android example:**
```json
{
  "platformName": "Android",
  "platformVersion": "13",
  "deviceName": "emulator-5554",
  "appPackage": "com.saucelabs.mydemoapp.android",
  "appActivity": "com.saucelabs.mydemoapp.android.view.activities.SplashActivity",
  "automationName": "UiAutomator2",
  "noReset": true
}
```

**iOS example:**
```json
{
  "platformName": "iOS",
  "platformVersion": "17.2",
  "deviceName": "iPhone 15 Pro",
  "udid": "YOUR-SIMULATOR-UDID",
  "bundleId": "com.saucelabs.mydemoapp.ios",
  "automationName": "XCUITest",
  "noReset": true
}
```

6. Click **Start Session**
7. The Inspector shows the live screen. Click any element to see its attributes.
8. Copy the `content-desc` (Android) or `label` (iOS) value — use it as `accessibility_id=<value>` in your variable file.

### Locator Priority

Use this order when choosing a locator strategy:

| Priority | Strategy | Robot Framework syntax | Notes |
|----------|----------|----------------------|-------|
| 1 | `accessibility_id` | `accessibility_id=My Label` | Most stable. Content-desc (Android) or accessibilityLabel (iOS) |
| 2 | `id` | `id=com.example:id/button` | Resource-id (Android). Fragile on iOS. |
| 3 | `xpath` | `xpath=//android.widget.Button[@text='Login']` | Last resort. Slow and brittle. |

### Update Variables After Inspection

Edit `resources/variables/common_variables.robot` and replace placeholder values with the real `accessibility_id` you found:

```robot
# Before (placeholder)
${USERNAME_FIELD}     accessibility_id=Username Input

# After (real value from Appium Inspector)
${USERNAME_FIELD}     accessibility_id=username input field
```

---

## 5. Troubleshooting Emulator Runs

### Android

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| `adb devices` shows nothing | Emulator not started / not booted | Wait for `adb shell getprop sys.boot_completed` to return `1` |
| `Appium could not find a connected Android device` | `deviceName` mismatch | Copy the exact serial from `adb devices` into `config/android_capabilities.yaml` |
| `Unable to find an element` (test fails immediately) | Wrong `accessibility_id` | Open Appium Inspector and find the real value |
| Session starts but app crashes instantly | Wrong `appPackage` / `appActivity` | Run `adb shell dumpsys window \| grep -E 'mCurrentFocus\|mFocusedApp'` while app is open |
| `INSTALL_FAILED_VERSION_DOWNGRADE` | Older APK already installed | `adb uninstall com.saucelabs.mydemoapp.android` first |
| "Android App Compatibility" 16 KB modal appears / tests fail immediately | ARM64 emulator (Apple Silicon) with Android 15+ | Run `adb shell settings put global show_16kb_compat_dialog 0` after each emulator boot (see Step 2) |
| `uiautomator2 not found` | Driver not installed | `appium driver install uiautomator2` |
| Tests are very slow | Animations enabled | Add `disableWindowAnimation: true` to capabilities, or disable animations in the emulator settings |

### iOS

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| `Device not found` | Simulator not booted | `xcrun simctl boot "iPhone 15 Pro"` |
| `UDID doesn't match any device` | Stale UDID in capabilities | Re-run `xcrun simctl list devices \| grep Booted` and copy the current UDID |
| `WebDriverAgent build failed` | Xcode or signing issue | Run `xcodebuild -version` — ensure Xcode 14+. Try `appium driver run xcuitest build-wda --platform-version 17.2` |
| `The bundle "WebDriverAgentRunner" could not be installed` | Simulator storage full | Delete old simulators: **Xcode → Window → Devices and Simulators → simulator → Delete Device** |
| `Application not installed` | `.app` bundle not on simulator | Re-run `xcrun simctl install "$UDID" app/ios/SauceLabs-Demo-App.app` |
| First run takes 5+ minutes | WDA is being compiled | Normal on first run. Cache is reused afterward. |
| `xcuitest not found` | Driver not installed | `appium driver install xcuitest` |

### Common to Both Platforms

| Symptom | Fix |
|---------|-----|
| `Connection refused` on port 4723 | Appium is not running — `appium` in a separate terminal |
| `No module named 'robot'` | Virtual environment not activated — `source .venv/bin/activate` (macOS) or `.venv\Scripts\activate.bat` (Windows) |
| All tests fail with `AssertionError` immediately | Locator values are wrong — use Appium Inspector (§ 4) to find the real `accessibility_id` values |
| Screenshots not saved | `results/screenshots/` directory missing — Robot Framework creates it automatically; check write permissions |
| `newCommandTimeout` errors in long pauses | Increase `newCommandTimeout: 600` in the capabilities file |

---

## Quick Reference — Full Run Sequence

### Android (macOS) — current emulator: Pixel_7 / Android 17 / API 37

```bash
# Terminal 1 — emulator (leave running)
~/Library/Android/sdk/emulator/emulator -avd Pixel_7 -no-snapshot-load &
adb wait-for-device && adb shell getprop sys.boot_completed   # wait for: 1
adb shell settings put global show_16kb_compat_dialog 0       # ARM64/Apple Silicon: suppress 16KB dialog

# Terminal 2 — Appium 3.3.1 (leave running)
ANDROID_HOME=~/Library/Android/sdk /opt/homebrew/bin/appium

# Terminal 3 — tests (videos saved to results/smoke_android/*.mp4)
source .venv/bin/activate
adb install -r app/android/mda-2.2.0-25.apk   # skip if already installed
.venv/bin/robot \
  --variable PLATFORM:android \
  --include smoke \
  --outputdir results/smoke_android \
  tests/
open results/smoke_android/report.html   # videos are embedded inside log.html
```

### Android (Windows — PowerShell) — current emulator: Android 17 / API 37

```powershell
# Window 1 — emulator
Start-Process emulator -ArgumentList "-avd", "Pixel_7"
Start-Sleep 60
adb devices   # Expected: emulator-5554   device

# Window 2 — Appium
appium

# Window 3 — tests (videos saved to results\smoke_android\*.mp4)
.venv\Scripts\Activate.ps1
adb install -r app\android\mda-2.2.0-25.apk   # skip if already installed
.venv\Scripts\robot.exe `
  --variable PLATFORM:android `
  --include smoke `
  --outputdir results\smoke_android `
  tests\
Start-Process results\smoke_android\report.html
```

### iOS (macOS)

```bash
# Boot simulator
xcrun simctl boot "iPhone 15 Pro"
open -a Simulator

# Get UDID and install app
UDID=$(xcrun simctl list devices booted | grep "iPhone 15 Pro" | grep -oE '[A-F0-9-]{36}')
xcrun simctl install "$UDID" app/ios/SauceLabs-Demo-App.app

# Update config/ios_capabilities.yaml with the UDID above

# Terminal 2 — Appium (leave running)
appium

# Terminal 3 — tests (videos embedded in log.html on iOS also)
source .venv/bin/activate
python -m robot \
  --variable PLATFORM:ios \
  --include smoke \
  --outputdir results/smoke_ios \
  tests/
open results/smoke_ios/report.html
```

---

See `docs/TROUBLESHOOTING.md` for additional debugging techniques.
