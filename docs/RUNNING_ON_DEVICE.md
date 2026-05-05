# Running Tests on Android Emulator and iOS Simulator

This guide is the end-to-end reference for executing the test suite against a running Android emulator or iOS simulator on your local machine. It assumes your environment is already set up per `docs/SETUP_GUIDE.md`.

**Platform note:** iOS simulator steps require macOS + Xcode. Android emulator steps work on macOS and Windows.

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
# Create the apps directory if it doesn't exist
mkdir -p apps/android

# Download the APK (version pinned to match test credentials)
curl -fsSL \
  "https://github.com/saucelabs/my-demo-app-android/releases/download/v2.2.0/mda-2.2.0-25.apk" \
  -o apps/android/mda-2.2.0-25.apk

# Verify the download
ls -lh apps/android/mda-2.2.0-25.apk
# Expected: -rw-r--r-- ... ~4MB ... apps/android/mda-2.2.0-25.apk
```

### Step 2 — Start the Android Emulator

You need an AVD named `Pixel_6_API_33` (created in `SETUP_GUIDE.md` § 3). If you already have a different AVD, substitute its name.

```bash
# List available AVDs
emulator -list-avds
# Example output:
# Pixel_6_API_33

# Launch the emulator (background process)
emulator -avd Pixel_6_API_33 &

# Wait for it to be fully booted (~60 seconds)
adb wait-for-device
adb shell getprop sys.boot_completed
# Expected: 1  (means fully booted)
```

Verify the device is connected:

```bash
adb devices
# Expected output:
# List of devices attached
# emulator-5554   device
```

> **Tip:** The emulator serial (`emulator-5554`) must match `deviceName` in `config/android_capabilities.yaml`.

### Step 3 — Install the APK on the Emulator

```bash
adb install -r apps/android/mda-2.2.0-25.apk
# Expected: Performing Streamed Install
#           Success

# Verify the app is installed
adb shell pm list packages | grep saucelabs
# Expected: package:com.saucelabs.mydemoapp.android
```

### Step 4 — Configure Android Capabilities

Edit `config/android_capabilities.yaml` to match your emulator:

```yaml
capabilities:
  platformName: Android
  platformVersion: "13"            # Android API 33 → version 13
  deviceName: "emulator-5554"      # must match `adb devices` output

  appPackage: "com.saucelabs.mydemoapp.android"
  appActivity: "com.saucelabs.mydemoapp.android.view.activities.SplashActivity"

  automationName: UiAutomator2
  noReset: false
  fullReset: false
  newCommandTimeout: 300
  disableWindowAnimation: true
  uiautomator2ServerLaunchTimeout: 60000
  uiautomator2ServerInstallTimeout: 60000
```

> **Using a real device?** Replace `deviceName` with your device serial from `adb devices -l`.

### Step 5 — Start Appium

Open a **new terminal window** and leave Appium running there:

```bash
appium
# Expected:
# [Appium] Welcome to Appium v2.x.x
# [Appium] Appium REST http interface listener started on http://0.0.0.0:4723
```

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
mkdir apps\android

curl -fsSL "https://github.com/saucelabs/my-demo-app-android/releases/download/v2.2.0/mda-2.2.0-25.apk" ^
  -o apps\android\mda-2.2.0-25.apk
```

**PowerShell:**
```powershell
New-Item -ItemType Directory -Force -Path apps\android

Invoke-WebRequest `
  -Uri "https://github.com/saucelabs/my-demo-app-android/releases/download/v2.2.0/mda-2.2.0-25.apk" `
  -OutFile "apps\android\mda-2.2.0-25.apk"
```

### Step 2 — Start the Android Emulator

Open **Android Studio → Device Manager** and click the **Play ▶** button next to your AVD.

Or from the command line:

**Command Prompt:**
```cmd
:: List AVDs
emulator -list-avds

:: Launch (in a separate window)
start "" emulator -avd Pixel_6_API_33

:: Wait for full boot, then check
adb wait-for-device
adb shell getprop sys.boot_completed
:: Expected: 1
```

**PowerShell:**
```powershell
# Launch emulator in background
Start-Process emulator -ArgumentList "-avd", "Pixel_6_API_33"

# Check connectivity (~60 sec after launch)
adb devices
# Expected: emulator-5554   device
```

### Step 3 — Install the APK

```cmd
adb install -r apps\android\mda-2.2.0-25.apk
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
mkdir -p apps/ios

# Download the simulator zip
curl -fsSL \
  "https://github.com/saucelabs/my-demo-app-ios/releases/download/v1.0.3/SauceLabs-Demo-App.Simulator.zip" \
  -o apps/ios/app.zip

# Extract the .app bundle
unzip -q apps/ios/app.zip -d apps/ios/
rm apps/ios/app.zip

# Verify
ls apps/ios/
# Expected: SauceLabs-Demo-App.app
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
xcrun simctl install "$UDID" apps/ios/SauceLabs-Demo-App.app
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
| `uiautomator2 not found` | Driver not installed | `appium driver install uiautomator2` |
| Tests are very slow | Animations enabled | Add `disableWindowAnimation: true` to capabilities, or disable animations in the emulator settings |

### iOS

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| `Device not found` | Simulator not booted | `xcrun simctl boot "iPhone 15 Pro"` |
| `UDID doesn't match any device` | Stale UDID in capabilities | Re-run `xcrun simctl list devices \| grep Booted` and copy the current UDID |
| `WebDriverAgent build failed` | Xcode or signing issue | Run `xcodebuild -version` — ensure Xcode 14+. Try `appium driver run xcuitest build-wda --platform-version 17.2` |
| `The bundle "WebDriverAgentRunner" could not be installed` | Simulator storage full | Delete old simulators: **Xcode → Window → Devices and Simulators → simulator → Delete Device** |
| `Application not installed` | `.app` bundle not on simulator | Re-run `xcrun simctl install "$UDID" apps/ios/SauceLabs-Demo-App.app` |
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

### Android (macOS)
```bash
# Terminal 1 — emulator (leave running)
emulator -avd Pixel_6_API_33 &

# Terminal 2 — Appium (leave running)
appium

# Terminal 3 — tests
source .venv/bin/activate
adb install -r apps/android/mda-2.2.0-25.apk
python -m robot --variable PLATFORM:android --include smoke --outputdir results/smoke_android tests/
open results/smoke_android/report.html
```

### Android (Windows — PowerShell)
```powershell
# Window 1 — emulator
Start-Process emulator -ArgumentList "-avd", "Pixel_6_API_33"

# Window 2 — Appium
appium

# Window 3 — tests
.venv\Scripts\Activate.ps1
adb install -r apps\android\mda-2.2.0-25.apk
robot --variable PLATFORM:android --include smoke --outputdir results\smoke_android tests\
Start-Process results\smoke_android\report.html
```

### iOS (macOS)
```bash
# Boot simulator
xcrun simctl boot "iPhone 15 Pro"
open -a Simulator

# Get UDID and install app
UDID=$(xcrun simctl list devices booted | grep "iPhone 15 Pro" | grep -oE '[A-F0-9-]{36}')
xcrun simctl install "$UDID" apps/ios/SauceLabs-Demo-App.app

# Update config/ios_capabilities.yaml with the UDID above

# Terminal 2 — Appium (leave running)
appium

# Terminal 3 — tests
source .venv/bin/activate
python -m robot --variable PLATFORM:ios --include smoke --outputdir results/smoke_ios tests/
open results/smoke_ios/report.html
```

---

See `docs/TROUBLESHOOTING.md` for additional debugging techniques.
