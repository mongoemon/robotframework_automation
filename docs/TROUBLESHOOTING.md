# Troubleshooting Guide

This guide covers the 10 most common problems when running Robot Framework + Appium mobile tests, with exact diagnostic commands and fixes for **both macOS and Windows**.

---

## Quick Diagnostic Checklist

Run this block to check all prerequisites at once.

**macOS / Git Bash:**
```bash
echo "--- Java ---"   && java -version 2>&1 | head -1
echo "--- adb ---"    && adb version 2>&1 | head -1
echo "--- Node ---"   && node --version
echo "--- Appium ---" && appium --version 2>/dev/null || echo "NOT FOUND"
echo "--- Drivers ---" && appium driver list --installed 2>/dev/null
echo "--- Robot ---"  && robot --version
echo "--- Appium status ---" && curl -s http://localhost:4723/status 2>/dev/null | python3 -m json.tool 2>/dev/null || echo "Appium NOT running"
echo "--- Devices ---" && adb devices
```

**Windows (Command Prompt):**
```cmd
java -version
adb version
node --version
appium --version
appium driver list --installed
robot --version
powershell -Command "try { Invoke-RestMethod http://localhost:4723/status } catch { 'Appium NOT running' }"
adb devices
```

---

## Issue 1 — Appium is Not Starting

### Symptoms
- Running `appium` immediately exits with an error
- `curl http://localhost:4723/status` returns "Connection refused"
- Tests fail instantly with `WebDriverException: Could not start a new session`

### Diagnosis

**macOS:**
```bash
appium --version
lsof -i :4723         # find what is already on port 4723
appium --log-level debug
```

**Windows:**
```cmd
appium --version
netstat -ano | findstr :4723   :: find what is on port 4723
appium --log-level debug
```

### Fixes

**Fix 1 — Appium not installed:**
```bash
npm install -g appium
```

**Fix 2 — npm global bin not in PATH:**

*macOS:*
```bash
npm config get prefix       # e.g. /usr/local
# Add /usr/local/bin to PATH in ~/.zshrc
echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.zshrc && source ~/.zshrc
```

*Windows:*
```cmd
npm config get prefix
:: e.g. C:\Users\YOUR_NAME\AppData\Roaming\npm
:: Add that path to the PATH environment variable via System Properties
```

**Fix 3 — Node.js version too old (Appium 2.x requires Node 18+):**
```bash
node --version
# If below 18.x, reinstall Node from https://nodejs.org
```

**Fix 4 — No drivers installed:**
```bash
appium driver install uiautomator2
appium driver install xcuitest    # macOS only
```

---

## Issue 2 — No Devices Found (Android)

### Symptoms
- `adb devices` shows nothing, or `offline`
- Error: `Could not find a connected Android device`

### Diagnosis

**macOS / Windows:**
```bash
adb devices -l
adb kill-server && adb start-server && adb devices
```

**Check environment variables:**

*macOS:*
```bash
echo $ANDROID_HOME
ls "$ANDROID_HOME/platform-tools/adb"
```

*Windows (Command Prompt):*
```cmd
echo %ANDROID_HOME%
dir "%ANDROID_HOME%\platform-tools\adb.exe"
```

### Fixes

**Fix 1 — Emulator not started:**

*macOS:*
```bash
emulator -list-avds
emulator -avd Pixel_6_API_33 &
sleep 20 && adb devices
```

*Windows:*
```cmd
emulator -list-avds
start emulator -avd Pixel_6_API_33
:: wait ~30 seconds then check:
adb devices
```

**Fix 2 — Real device shows "unauthorized":**
```
1. Enable Developer Options: Settings → About Phone → tap "Build number" 7 times
2. Enable USB Debugging: Settings → Developer Options → USB Debugging → ON
3. Connect via USB cable, tap "Allow" on the device when prompted
```

**Fix 3 — Multiple devices (Appium confused which to use):**
```bash
adb devices
# Pick your target device serial (e.g. emulator-5554 or R3CR10XABCD)
# Set it in config/android_capabilities.yaml:
#   deviceName: "emulator-5554"
```

**Fix 4 — ANDROID_HOME not set (Windows):**
- Open **Environment Variables** via Start menu
- Add `ANDROID_HOME` as a System variable pointing to your SDK folder
- Add `%ANDROID_HOME%\platform-tools` to `Path`
- Open a **new** Command Prompt and retry `adb devices`

---

## Issue 3 — App Not Found / Wrong Package Name

### Symptoms
- `org.openqa.selenium.SessionNotCreatedException: Could not launch app... Activity not found`
- Session starts but lands on the wrong screen

### Diagnosis

**macOS / Windows (adb commands are identical):**
```bash
# Find the foreground app's package name (open the app first)
adb shell dumpsys window | grep -E "mCurrentFocus|mFocusedApp"

# List all installed packages
adb shell pm list packages | grep myapp

# Find the launch activity for a known package
adb shell dumpsys package com.example.myapp | grep -A 3 "MAIN"
```

### Fixes

**Fix 1 — Wrong `appPackage` or `appActivity` in YAML:**
```yaml
# config/android_capabilities.yaml
appPackage: "com.example.correctpackage"
appActivity: "com.example.correctpackage.MainActivity"
```

**Fix 2 — APK not installed:**
```bash
adb install /path/to/your/app.apk
```

**Fix 3 — Use `app` capability to install on session start:**
```yaml
# macOS path format:
app: "/Users/monmac/work/robotframework_automation/app/android/myapp.apk"

# Windows path format (forward slashes work in YAML):
app: "C:/Users/YOUR_NAME/work/robotframework_automation/app/android/myapp.apk"
```

---

## Issue 4 — Element Not Found

### Symptoms
- `ElementNotVisibleException: An element could not be located on the page`
- `TimeoutException: Timed out waiting for element`
- Test hangs for 30 seconds then fails

### Diagnosis — Take a screenshot of current screen state

**macOS:**
```bash
adb exec-out screencap -p > /tmp/screen.png && open /tmp/screen.png
```

**Windows:**
```cmd
adb exec-out screencap -p > %TEMP%\screen.png
start %TEMP%\screen.png
```

### Fixes

**Fix 1 — Wrong locator (most common):**
```
1. Open Appium Inspector: https://github.com/appium/appium-inspector/releases
2. Start a session with your app
3. Click the element that cannot be found
4. Read content-desc → use as:  accessibility_id=<value>
5. Update locator in resources/variables/common_variables.robot
```

**Fix 2 — Element is off-screen:**
```robot
Scroll Down To Find Element    ${YOUR_ELEMENT_LOCATOR}
Wait And Click Element    ${YOUR_ELEMENT_LOCATOR}
```

**Fix 3 — Timeout too short:**
```bash
robot --variable TIMEOUT:60s tests/
```

**Fix 4 — Keyboard covering the element:**
```robot
Hide Keyboard If Visible
Wait And Click Element    ${YOUR_ELEMENT_LOCATOR}
```

---

## Issue 5 — Session Creation Failed

### Symptoms
- `SessionNotCreatedException: Unable to create a new remote session`
- `WebDriverException: session not created`

### Diagnosis
```bash
# Check Appium terminal output for error lines starting with:
# [AndroidUiautomator2Driver] or [XCUITestDriver]

appium-doctor --android
appium-doctor --ios     # macOS only
```

### Fixes

**Fix 1 — Appium driver not installed:**
```bash
appium driver install uiautomator2
appium driver list --installed
```

**Fix 2 — `platformVersion` does not match device:**
```bash
adb shell getprop ro.build.version.release
# e.g. output: 13
# Update config/android_capabilities.yaml → platformVersion: "13"
```

**Fix 3 — iOS — WebDriverAgent build failing (macOS only):**
```bash
cd ~/.appium/node_modules/appium-xcuitest-driver/node_modules/appium-webdriveragent
xcodebuild -project WebDriverAgent.xcodeproj \
  -scheme WebDriverAgentRunner \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  test
```

**Fix 4 — Windows: `newCommandTimeout` exceeded during slow emulator boot:**
```yaml
# config/android_capabilities.yaml
newCommandTimeout: 600    # increase to 10 minutes
```

---

## Issue 6 — Tests Time Out on Slow Actions

### Symptoms
- Random `TimeoutException` on elements that usually appear quickly
- Tests pass locally but time out in CI
- Flaky tests (sometimes pass, sometimes fail)

### Fixes

**Fix 1 — Increase global timeout:**
```bash
robot --variable TIMEOUT:60s tests/
```

Or update `resources/variables/common_variables.robot`:
```robot
${TIMEOUT}    60s
```

**Fix 2 — Disable animations for faster, more stable tests:**

*macOS / Windows (adb commands are identical):*
```bash
adb shell settings put global window_animation_scale 0
adb shell settings put global transition_animation_scale 0
adb shell settings put global animator_duration_scale 0
```

Or in capabilities YAML:
```yaml
disableWindowAnimation: true
```

**Fix 3 — CI machines are slower — raise `newCommandTimeout`:**
```yaml
newCommandTimeout: 600
```

---

## Issue 7 — iOS Code Signing / Real Device Issues (macOS only)

### Symptoms
- `Unable to launch com.example.myapp because it has an invalid code signature`
- Session starts but immediately closes on real device

### Diagnosis
```bash
xcrun xctrace list devices
```

### Fixes

**Fix 1 — Add signing capabilities to `config/ios_capabilities.yaml`:**
```yaml
xcodeOrgId: "YOUR_TEAM_ID"
xcodeSigningId: "iPhone Developer"
updatedWDABundleId: "com.yourcompany.WebDriverAgentRunner"
```

**Fix 2 — Trust the developer certificate on the device:**
```
iPhone: Settings → General → VPN & Device Management → tap cert → Trust
```

**Fix 3 — Use simulator (no signing needed):**
```yaml
deviceName: "iPhone 15 Pro"
# Remove udid, xcodeOrgId, xcodeSigningId
```

---

## Issue 8 — Wrong Python Version / Import Errors

### Symptoms
- `ModuleNotFoundError: No module named 'AppiumLibrary'`
- `robot: command not found`

### Diagnosis

**macOS:**
```bash
python3 --version
which python3
which robot
pip3 list | grep -i robot
pip3 list | grep -i appium
```

**Windows:**
```cmd
python --version
where python
where robot
pip list | findstr -i robot
pip list | findstr -i appium
```

### Fixes

**Fix 1 — Virtual environment not activated:**

*macOS:*
```bash
source .venv/bin/activate
which python3   # Expected: .../robotframework_automation/.venv/bin/python3
```

*Windows (Command Prompt):*
```cmd
.venv\Scripts\activate.bat
where python    :: Expected: ...\robotframework_automation\.venv\Scripts\python.exe
```

*Windows (PowerShell):*
```powershell
.venv\Scripts\Activate.ps1
# If blocked by execution policy:
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.venv\Scripts\Activate.ps1
```

**Fix 2 — Dependencies not installed:**
```bash
pip install -r requirements.txt
```

**Fix 3 — Multiple Python versions conflict (Windows):**
```cmd
:: Use py launcher to target specific version
py -3.11 -m pip install -r requirements.txt
py -3.11 -m robot --version
```

---

## Issue 9 — Missing System Dependencies

### Symptoms
- `appium-doctor` reports WARN or ERROR
- `ANDROID_HOME is not set`
- `adb: command not found`

### Fixes

**macOS:**
```bash
# Missing Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Missing ANDROID_HOME in ~/.zshrc
echo 'export ANDROID_HOME="$HOME/Library/Android/sdk"' >> ~/.zshrc
echo 'export PATH="$ANDROID_HOME/platform-tools:$PATH"' >> ~/.zshrc
echo 'export PATH="$ANDROID_HOME/emulator:$PATH"' >> ~/.zshrc
source ~/.zshrc

# Missing carthage (iOS)
brew install carthage

# Missing Xcode CLI tools
xcode-select --install
```

**Windows:**
```
1. Open Start → search "Environment Variables"
2. Under System variables:
   - Add ANDROID_HOME = C:\Users\YOUR_NAME\AppData\Local\Android\Sdk
3. Edit Path variable, add:
   - %ANDROID_HOME%\platform-tools
   - %ANDROID_HOME%\emulator
   - %ANDROID_HOME%\cmdline-tools\latest\bin
4. Open a NEW Command Prompt and verify:
   adb version
   emulator -list-avds
```

Run `appium-doctor --android` again to confirm all issues are resolved.

---

## Issue 10 — Port 4723 Already in Use

### Symptoms
- `Error: listen EADDRINUSE: address already in use :::4723`
- Appium exits immediately after starting

### Diagnosis — Find what is using port 4723

**macOS:**
```bash
lsof -i :4723
# Example output:
# COMMAND  PID   USER  FD  TYPE  DEVICE  SIZE NODE NAME
# node   12345  user  23u  IPv4  0x...   0t0  TCP *:4723 (LISTEN)
```

**Windows (Command Prompt):**
```cmd
netstat -ano | findstr :4723
:: Example output:
::   TCP    0.0.0.0:4723   0.0.0.0:0   LISTENING   12345
:: The last number (12345) is the PID
```

### Fixes

**Fix 1 — Kill the existing process:**

*macOS:*
```bash
lsof -ti :4723 | xargs kill -9
appium
```

*Windows (Command Prompt — use PID from netstat above):*
```cmd
taskkill /PID 12345 /F
appium
```

*Windows — kill all Node processes (if nothing else uses Node):*
```cmd
taskkill /F /IM node.exe
appium
```

**Fix 2 — Run Appium on a different port:**
```bash
appium --port 4724
```

Update `resources/variables/common_variables.robot`:
```robot
${APPIUM_URL}    http://localhost:4724
```

**Fix 3 — Old session from a crashed test:**

*macOS:*
```bash
pkill -f "appium"
adb kill-server && adb start-server
```

*Windows:*
```cmd
taskkill /F /IM node.exe
adb kill-server && adb start-server
```

---

## Issue 11 — AppiumLibrary 2.x Keyword Compatibility

### Symptoms
- `No keyword with name 'Get Window Size' found`
- `No keyword with name 'Wait Until Element Is Not Visible' found`
- `No keyword with name 'Launch App' found. Did you mean: AppiumLibrary.Launch Application`
- `Keyword 'BuiltIn.Log' got multiple values for argument 'level'`

These errors appear after upgrading to **AppiumLibrary 2.x** or **Robot Framework 7.x**, both of which introduced breaking changes compared to earlier versions.

### Root Causes and Fixes

**Get Window Size removed**

AppiumLibrary 2.x replaced the combined `Get Window Size` (which returned a dict) with separate `Get Window Width` and `Get Window Height` keywords.

This project provides a backward-compatible wrapper keyword in `resources/keywords/common_keywords.robot`:

```robot
Get Window Size
    ${width}=     Get Window Width
    ${height}=    Get Window Height
    &{size}=      Create Dictionary    width=${width}    height=${height}
    RETURN    ${size}
```

No changes needed in your tests — just keep `resources/keywords/common_keywords.robot` imported.

**Wait Until Element Is Not Visible removed**

Replaced by `Wait Until Page Does Not Contain Element`. All occurrences in this project have been updated. If you see this error in your own keywords, change:

```robot
# Before
Wait Until Element Is Not Visible    ${locator}    timeout=${TIMEOUT}

# After
Wait Until Page Does Not Contain Element    ${locator}    timeout=${TIMEOUT}
```

**Launch App removed / Launch Application deprecated**

`Launch App` was removed and `Launch Application` was deprecated in favour of `Activate Application` (which requires the app's bundle ID / package name).

Set `${ANDROID_APP_ID}` and `${IOS_APP_ID}` in `resources/variables/common_variables.robot` to match your `appPackage` / `bundleId` in the capabilities YAML. The `Launch Application` wrapper in `appium_keywords.robot` calls `Activate Application` automatically.

**Log keyword gets "multiple values for argument 'level'"**

In Robot Framework's space-separated format, **two or more consecutive spaces are argument separators**. A line like:

```robot
Log    Platform  : ${platform}    level=INFO
#                ^^
#          These 2 spaces split "Platform" and ": ${platform}" into separate args!
```

Is parsed as `Log(message="Platform", level=": ${platform}", level=INFO)` — the named `level` receives two values. Fix: remove the alignment spaces so the message contains no double-space sequence:

```robot
Log    Platform: ${platform}    level=INFO
```

---

## Getting More Help

**1. Enable verbose Appium logging:**
```bash
appium --log-level debug 2>&1 | tee appium.log
```

**2. Enable Robot Framework TRACE level:**
```bash
robot --loglevel TRACE tests/
```

**3. Check `results/*/log.html`** — it captures the exact keyword that failed with a screenshot at the moment of failure. This is the fastest way to diagnose most failures.

**4. Community resources:**
- Appium Discuss: https://discuss.appium.io
- Robot Framework Forum: https://forum.robotframework.org
- AppiumLibrary GitHub Issues: https://github.com/serhatbolsu/robotframework-appiumlibrary/issues
