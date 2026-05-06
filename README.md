# Robot Framework Mobile Automation

A production-ready mobile test automation project using **Robot Framework** and **AppiumLibrary**.
Supports both **Android** and **iOS** with a single codebase, on **macOS and Windows**.

> **Platform note:** iOS testing requires macOS + Xcode. Android testing works on both macOS and Windows.

---

## Table of Contents

1. [Introduction](#introduction)
2. [Prerequisites](#prerequisites)
3. [Quick Start — Run Your First Test in 6 Steps](#quick-start)
4. [App Binaries](#app-binaries)
5. [Project Structure](#project-structure)
6. [Configuration — Adapt to Your App](#configuration)
7. [Running Tests](#running-tests)
8. [Running on Emulator / Simulator](#running-on-emulator--simulator)
9. [Understanding Results](#understanding-results)
10. [Next Steps](#next-steps)

---

## Introduction

This project automates the mobile app UI using the **Page Object Model (POM)** pattern:

- **Tests** describe *what* to verify in plain English
- **Page Objects** describe *how* to interact with each screen
- **Keywords** are reusable building blocks for both
- **YAML configs** keep capabilities and test data out of the code

The included test suites cover a **Login flow**, **Navigation Drawer**, and **Products Catalog screen**, which you adapt for your own app.

---

## Prerequisites

Before you can run tests, install and configure every item in this checklist.

### Required Software

| Tool | Version | macOS check | Windows check |
|------|---------|-------------|---------------|
| Python | 3.9+ | `python3 --version` | `python --version` |
| Java JDK | 11+ | `java -version` | `java -version` |
| Node.js | 18+ | `node --version` | `node --version` |
| npm | 9+ | `npm --version` | `npm --version` |
| Appium | 2.x | `appium --version` | `appium --version` |
| Android Studio | Latest | Launch from `/Applications` | Launch from Start menu |
| Xcode | 14+ | `xcodebuild -version` | **macOS only** |

### Python Packages

Installed via `pip install -r requirements.txt` (handled in Quick Start step 3).

### Appium Drivers

```bash
appium driver install uiautomator2   # Android
appium driver install xcuitest        # iOS
```

> See `docs/SETUP_GUIDE.md` for the full step-by-step environment setup.

---

## Quick Start

Six steps to run your first test:

### Step 1 — Clone the repository

```bash
git clone https://github.com/mongoemon/robotframework_automation.git
cd robotframework_automation
```

### Step 2 — Create and activate a Python virtual environment

**macOS:**
```bash
python3 -m venv .venv
source .venv/bin/activate
```

**Windows (Command Prompt):**
```cmd
python -m venv .venv
.venv\Scripts\activate.bat
```

**Windows (PowerShell):**
```powershell
python -m venv .venv
.venv\Scripts\Activate.ps1
```

### Step 3 — Install dependencies

```bash
pip install -r requirements.txt
```

### Step 4 — Download app binaries

App binaries (APK/IPA) are not stored in the repository. Download them with the included script:

```bash
python scripts/download_apps.py           # download both Android and iOS
python scripts/download_apps.py --android # Android only
python scripts/download_apps.py --ios     # iOS only
```

Files are saved to `apps/android/` and `apps/ios/` automatically.
If the files already exist, the script skips them — run with `--force` to re-download.

> See the [App Binaries](#app-binaries) section for switching to a private download source.

### Step 5 — Configure your app capabilities

Edit the file that matches your target platform:

- **Android:** `config/android_capabilities.yaml`
- **iOS:** `config/ios_capabilities.yaml`

At minimum, update these fields for Android:

```yaml
deviceName: "Pixel_6_API_33"        # output of: adb devices
appPackage: "com.example.myapp"     # your app's package name
appActivity: ".MainActivity"         # your app's launch activity
```

Also set the matching app ID in `resources/variables/common_variables.robot` (used by the `Reset Application State` keyword):

```robot
${ANDROID_APP_ID}    com.example.myapp   # matches appPackage above
${IOS_APP_ID}        com.example.myapp   # matches bundleId in ios_capabilities.yaml
```

### Step 6 — Start Appium and run smoke tests

**Terminal 1 — Start Appium (same on all platforms):**

```bash
appium
```

**Terminal 2 — Run tests:**

*macOS:*
```bash
./scripts/run_android.sh --tags smoke   # Android
./scripts/run_ios.sh --tags smoke       # iOS
make smoke-android                      # or via Make
```

*Windows (Command Prompt or PowerShell):*
```cmd
robot --variable PLATFORM:android --include smoke --outputdir results\ tests\
```

*Windows — Git Bash (runs the shell scripts directly):*
```bash
bash scripts/run_android.sh --tags smoke
```

When the run finishes, open the HTML report:

*macOS:*
```bash
open results/android_*/report.html
```

*Windows:*
```cmd
start results\report.html
```

---

## App Binaries

APK and IPA files are excluded from the repository (see `.gitignore`). They are managed separately so the repo stays small and version-controlled independently of the app build.

### Downloading on a New Machine

After cloning the repo and installing dependencies (`pip install -r requirements.txt`), run:

```bash
# Download everything (Android APK + iOS IPA)
python scripts/download_apps.py

# Platform-specific
python scripts/download_apps.py --android
python scripts/download_apps.py --ios

# Force re-download even if file already exists
python scripts/download_apps.py --force
```

| Destination | File |
|---|---|
| `apps/android/` | `mda-2.2.0-25.apk` |
| `apps/ios/` | `SauceLabs-Demo-App.ipa` |

### Switching Between Sources

Download URLs and the active source are configured in **`scripts/apps.yaml`** — this is the only file you need to edit when updating versions or switching sources.

```yaml
# Set to "saucelabs" to use the official public release,
# or "private" to use your own hosted build.
source: saucelabs

android:
  filename: mda-2.2.0-25.apk
  saucelabs_url: "https://github.com/saucelabs/my-demo-app-android/releases/..."
  private_url: ""   # fill in your private URL here

ios:
  filename: SauceLabs-Demo-App.ipa
  saucelabs_url: "https://github.com/saucelabs/my-demo-app-ios/releases/..."
  private_url: ""
```

### Private Hosting Setup (GitHub Releases — recommended)

Using your own hosted builds lets you pin an exact version and avoids relying on the upstream public release.

1. Go to your GitHub repo → **Releases** → **Draft a new release**
2. Upload `mda-2.2.0-25.apk` and `SauceLabs-Demo-App.ipa` as release assets
3. Copy the asset URLs into `private_url` in `scripts/apps.yaml`
4. Change `source: private`

For **private repos**, set a GitHub personal access token before running the script:

```bash
# macOS / CI
export GITHUB_TOKEN="ghp_xxxxxxxxxxxx"
python scripts/download_apps.py
```

```powershell
# Windows PowerShell
$env:GITHUB_TOKEN = "ghp_xxxxxxxxxxxx"
python scripts/download_apps.py
```

---

## Project Structure

```
robotframework_automation/
│
├── config/                          # Appium capabilities (one file per platform)
│   ├── android_capabilities.yaml   # Android device, app package, version, etc.
│   └── ios_capabilities.yaml       # iOS device, bundleId, UDID, etc.
│
├── resources/                       # Reusable Robot Framework code
│   ├── variables/
│   │   └── common_variables.robot  # Timeouts, app IDs, element locators
│   ├── keywords/
│   │   ├── common_keywords.robot   # Shared actions (click, type, scroll, screenshot)
│   │   └── appium_keywords.robot   # Low-level platform helpers (alerts, platform detection)
│   └── pages/                      # Page Object Model — one file per screen
│       ├── base_page.robot         # Shared navigation + verification template
│       ├── login_page.robot        # Login screen interactions + assertions
│       ├── home_page.robot         # Home screen interactions + assertions
│       ├── navigation_page.robot   # Navigation drawer (hamburger menu) interactions
│       └── products_page.robot     # Products catalog screen interactions + assertions
│
├── tests/                           # Test suites
│   ├── smoke/
│   │   ├── 01_login_smoke.robot          # 3 smoke tests — direct login flow
│   │   └── 02_products_smoke.robot       # 3 smoke tests — nav drawer + products (TC-AND/IOS-001,002,005)
│   └── regression/
│       ├── 01_login_regression.robot     # 10 regression tests — login edge cases
│       └── 02_login_validation_regression.robot  # 2 regression tests — field validation (TC-AND/IOS-003,004)
│
├── test_data/
│   └── users.yaml                  # Test credentials and expected error messages (incl. demo_user)
│
├── scripts/
│   ├── apps.yaml                   # Download URLs for APK/IPA (edit here to switch source or version)
│   ├── download_apps.py            # Cross-platform binary downloader (Mac + Windows)
│   ├── run_android.sh              # Android test runner with pre-flight checks
│   └── run_ios.sh                  # iOS test runner with pre-flight checks
│
├── results/                         # Generated output (gitignored except .gitkeep)
│   └── .gitkeep
│
├── docs/
│   ├── SETUP_GUIDE.md              # Full macOS & Windows environment setup walkthrough
│   ├── RUNNING_ON_DEVICE.md        # Step-by-step: run tests on Android emulator & iOS simulator
│   ├── WRITING_TESTS.md            # How to add new pages and test cases
│   ├── TROUBLESHOOTING.md          # Top 10 issues and how to fix them
│   └── GIT_WORKFLOW.md             # Git commands: clone, branch, commit, push, PR
│
├── apps/
│   ├── android/                    # .apk builds (mda-2.2.0-25.apk)
│   └── ios/                        # .ipa / .XCUITest builds (SauceLabs-Demo-App)
│
├── requirements.txt                # Python dependencies
├── Makefile                        # Convenient make targets
└── .gitignore
```

### Why This Structure?

- **`resources/pages/`** — The Page Object Model means test files never reference raw locators. If the UI changes, update the locator in ONE place (the page file), not in every test.
- **`config/*.yaml`** — Capabilities live outside the code. Switch devices by editing the YAML, not the tests.
- **`test_data/users.yaml`** — Test data in a dedicated file. Update credentials without touching test logic.

---

## Configuration

### Changing the Target Device

**Android** — edit `config/android_capabilities.yaml`:

```yaml
capabilities:
  platformVersion: "13"                           # Android version on your device
  deviceName: "Pixel_6_API_33"                    # from: adb devices
  appPackage: "com.yourcompany.yourapp"           # from: adb shell dumpsys window | grep Focus
  appActivity: "com.yourcompany.yourapp.MainActivity"
```

**iOS** — edit `config/ios_capabilities.yaml`:

```yaml
capabilities:
  platformVersion: "17.2"
  deviceName: "iPhone 15 Pro"                     # from: xcrun simctl list devices
  udid: "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"   # from: xcrun xctrace list devices
  bundleId: "com.yourcompany.yourapp"
```

### Changing Locators

All element locators are in `resources/variables/common_variables.robot`, organised by screen:

```robot
# Login screen
${USERNAME_FIELD}               accessibility_id=Username Input
${PASSWORD_FIELD}               accessibility_id=Password Input
${LOGIN_BUTTON}                 accessibility_id=Login Button

# Navigation drawer (hamburger menu ☰)
${HAMBURGER_MENU}               accessibility_id=open menu
${LOGIN_MENU_ITEM}              accessibility_id=menu item log in
${LOGOUT_MENU_ITEM}             accessibility_id=menu item log out
${LOGOUT_CONFIRM_BUTTON}        accessibility_id=Logout Confirm Button

# Products catalog screen
${PRODUCTS_SCREEN_INDICATOR}    accessibility_id=Products Screen
${PRODUCT_ITEM}                 accessibility_id=Product Item
${PRODUCT_TITLE}                accessibility_id=Product Title

# Field-level validation error labels
${USERNAME_ERROR_MESSAGE}       accessibility_id=Username Error Message
${PASSWORD_ERROR_MESSAGE}       accessibility_id=Password Error Message
```

Use **Appium Inspector** to find the correct `accessibility_id` (or `xpath`) for your app's elements.
See `docs/WRITING_TESTS.md` for a guide on using Appium Inspector.

---

## Running Tests

### All Tests

```bash
make android        # all tests on Android
make ios            # all tests on iOS
```

### By Test Type

```bash
make smoke-android
make smoke-ios
make regression-android
make regression-ios
```

### By Tag (single test or xlsx test ID)

```bash
# Run a specific original test by ID
make run-tag PLATFORM=android TAG=TC002

# Run a specific xlsx-sourced test by its Android or iOS ID
robot --variable PLATFORM:android --include TC-AND-001 tests/
robot --variable PLATFORM:ios     --include TC-IOS-001 tests/

# Or directly with robot (original IDs)
robot --variable PLATFORM:android --include TC002 tests/
```

### With the Shell Scripts

```bash
# All options
./scripts/run_android.sh --tags smoke --loglevel DEBUG

# Dry run (validate syntax only, no real device needed)
./scripts/run_android.sh --dryrun

# Run a specific suite file
./scripts/run_android.sh --suite 01_login_regression
```

### Directly with Robot Framework

*macOS / Git Bash:*
```bash
robot \
  --variable PLATFORM:android \
  --variable TIMEOUT:45s \
  --include smoke \
  --outputdir results/manual_run \
  tests/
```

*Windows (Command Prompt — use `^` for line continuation):*
```cmd
robot ^
  --variable PLATFORM:android ^
  --variable TIMEOUT:45s ^
  --include smoke ^
  --outputdir results\manual_run ^
  tests\
```

*Windows (PowerShell — use backtick for line continuation):*
```powershell
robot `
  --variable PLATFORM:android `
  --variable TIMEOUT:45s `
  --include smoke `
  --outputdir results\manual_run `
  tests\
```

---

## Running on Emulator / Simulator

Full step-by-step instructions are in **[docs/RUNNING_ON_DEVICE.md](docs/RUNNING_ON_DEVICE.md)**. Here is the minimal sequence for each platform.

### Android Emulator (macOS or Windows)

Current emulator: **Android 16 (API 36)**, serial `emulator-5554`, AVD `sdk_gphone64_x86_64`.

```bash
# 1. Boot emulator and wait for it to be ready
emulator -avd sdk_gphone64_x86_64 &
adb wait-for-device && adb shell getprop sys.boot_completed  # wait for: 1

# 2. Download the APK (skip if already in apps/android/)
python scripts/download_apps.py --android

# 3. Install the app onto the emulator
adb install -r apps/android/mda-2.2.0-25.apk

# 3. Start Appium (separate terminal)
appium

# 4. Run smoke tests — videos are saved automatically per test
python -m robot \
  --variable PLATFORM:android \
  --include smoke \
  --outputdir results/smoke_android \
  tests/
```

After the run: open `results/smoke_android/log.html` — each test has an embedded video player in its teardown step.

Configuration: `config/android_capabilities.yaml` — change `deviceName` and `platformVersion` if your emulator differs.

### iOS Simulator (macOS only)

```bash
# 1. Boot simulator
xcrun simctl boot "iPhone 15 Pro"
open -a Simulator

# 2. Download the IPA (skip if already in apps/ios/)
python scripts/download_apps.py --ios

# 3. Install the app onto the simulator
UDID=$(xcrun simctl list devices booted | grep "iPhone 15 Pro" | grep -oE '[A-F0-9-]{36}')
xcrun simctl install "$UDID" apps/ios/SauceLabs-Demo-App.ipa

# 4. Start Appium (separate terminal)
appium

# 5. Run smoke tests
python -m robot \
  --variable PLATFORM:ios \
  --include smoke \
  --outputdir results/smoke_ios \
  tests/
```

Configuration: `config/ios_capabilities.yaml` — set `udid` to the value from Step 2.

> **App binaries are not in the repo.** Run `python scripts/download_apps.py` after cloning.  
> See the [App Binaries](#app-binaries) section to configure the download source.

---

## Understanding Results

After each run, Robot Framework generates three files in `results/run_TIMESTAMP/`:

| File | What it contains |
|------|-----------------|
| `report.html` | High-level pass/fail summary — open this first |
| `log.html` | Every keyword call, with screenshots and timings |
| `output.xml` | Machine-readable results (used by CI systems) |

### Reading the HTML Report

1. Open `report.html` in your browser
2. The top panel shows the overall pass/fail count
3. Click on a **failed test** to expand it
4. Click through to the **log** link to see the exact step that failed, with a screenshot

### Screenshots

Screenshots are taken automatically:
- **Before each test** (precondition state)
- **After each test** (result state)
- **On failure** (the exact moment of failure, embedded in the log)

---

## Next Steps

Once you have the smoke tests passing against your app:

1. **Run on a device** — see `docs/RUNNING_ON_DEVICE.md` for the full Android emulator and iOS simulator walkthrough
2. **Find your real locators** — use Appium Inspector (§ 4 in `docs/RUNNING_ON_DEVICE.md`) to discover the actual `accessibility_id` values for your app and update `resources/variables/common_variables.robot`
3. **Learn Git basics** — see `docs/GIT_WORKFLOW.md` for clone, branch, commit, push, and PR commands
4. **Add your own page objects** — follow the guide in `docs/WRITING_TESTS.md`
5. **Expand the regression suite** — add more edge cases to `tests/regression/`
6. **Connect to CI/CD** — run `make smoke-android` in your GitHub Actions / GitLab CI / Jenkins pipeline
7. **Parallel execution** — use Pabot (`pip install robotframework-pabot`) to run suites in parallel
8. **Data-driven tests** — use the `DataDriver` library with `test_data/users.yaml` for table-driven tests
9. **Video recording** — add `appium:recordVideo` to the capabilities to capture test videos

---

---

## Test Inventory

| Suite | File | Tests | Tags | Source |
|-------|------|-------|------|--------|
| Login Smoke | `tests/smoke/01_login_smoke.robot` | TC001–TC003 | `smoke login` | Original |
| Products Smoke | `tests/smoke/02_products_smoke.robot` | TC-AND/IOS-001, 002, 005 | `smoke login products` | `docs/test-cases.xlsx` |
| Login Regression | `tests/regression/01_login_regression.robot` | TC010–TC019 | `regression login` | Original |
| Validation Regression | `tests/regression/02_login_validation_regression.robot` | TC-AND/IOS-003, 004 | `regression login validation` | `docs/test-cases.xlsx` |

### Test Credentials

| Credential set | Username | Password | Used by |
|---|---|---|---|
| Generic valid user | `testuser@example.com` | `ValidPass123!` | `01_*` suites |
| SauceLabs Demo App user | `bod@example.com` | `10203040` | `02_*` suites (xlsx) |

---

*Built with Robot Framework 7.x, AppiumLibrary 2.x, and Appium 2.x.*
