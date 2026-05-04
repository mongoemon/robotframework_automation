# Robot Framework Mobile Automation

A production-ready mobile test automation project using **Robot Framework** and **AppiumLibrary**.
Supports both **Android** and **iOS** with a single codebase, on **macOS and Windows**.

> **Platform note:** iOS testing requires macOS + Xcode. Android testing works on both macOS and Windows.

---

## Table of Contents

1. [Introduction](#introduction)
2. [Prerequisites](#prerequisites)
3. [Quick Start — Run Your First Test in 5 Steps](#quick-start)
4. [Project Structure](#project-structure)
5. [Configuration — Adapt to Your App](#configuration)
6. [Running Tests](#running-tests)
7. [Understanding Results](#understanding-results)
8. [Next Steps](#next-steps)

---

## Introduction

This project automates the mobile app UI using the **Page Object Model (POM)** pattern:

- **Tests** describe *what* to verify in plain English
- **Page Objects** describe *how* to interact with each screen
- **Keywords** are reusable building blocks for both
- **YAML configs** keep capabilities and test data out of the code

The example flows cover a **Login screen** and **Home screen**, which you adapt for your own app.

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

Five steps to run your first test:

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

### Step 4 — Configure your app capabilities

Edit the file that matches your target platform:

- **Android:** `config/android_capabilities.yaml`
- **iOS:** `config/ios_capabilities.yaml`

At minimum, update these three fields for Android:

```yaml
deviceName: "Pixel_6_API_33"        # output of: adb devices
appPackage: "com.example.myapp"     # your app's package name
appActivity: ".MainActivity"         # your app's launch activity
```

### Step 5 — Start Appium and run smoke tests

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
│   │   └── common_variables.robot  # Timeouts, URLs, element locators
│   ├── keywords/
│   │   ├── common_keywords.robot   # Shared actions (click, type, scroll, screenshot)
│   │   └── appium_keywords.robot   # Low-level platform helpers (alerts, platform detection)
│   └── pages/                      # Page Object Model — one file per screen
│       ├── base_page.robot         # Shared navigation + verification template
│       ├── login_page.robot        # Login screen interactions + assertions
│       └── home_page.robot         # Home screen interactions + assertions
│
├── tests/                           # Test suites
│   ├── smoke/
│   │   └── 01_login_smoke.robot    # 3 fast smoke tests for the login flow
│   └── regression/
│       └── 01_login_regression.robot  # 10 comprehensive regression tests
│
├── test_data/
│   └── users.yaml                  # Test credentials and expected error messages
│
├── scripts/
│   ├── run_android.sh              # Android test runner with pre-flight checks
│   └── run_ios.sh                  # iOS test runner with pre-flight checks
│
├── results/                         # Generated output (gitignored except .gitkeep)
│   └── .gitkeep
│
├── docs/
│   ├── SETUP_GUIDE.md              # Full macOS & Windows environment setup walkthrough
│   ├── WRITING_TESTS.md            # How to add new pages and test cases
│   ├── TROUBLESHOOTING.md          # Top 10 issues and how to fix them
│   └── GIT_WORKFLOW.md             # Git commands: clone, branch, commit, push, PR
│
├── app/
│   ├── android/                    # Place your .apk files here
│   └── ios/                        # Place your .app / .ipa files here
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

All element locators are in `resources/variables/common_variables.robot`.

```robot
${USERNAME_FIELD}    accessibility_id=Username Input
${PASSWORD_FIELD}    accessibility_id=Password Input
${LOGIN_BUTTON}      accessibility_id=Login Button
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

### By Tag (single test)

```bash
# Run only TC002 on Android
make run-tag PLATFORM=android TAG=TC002

# Or directly with robot
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

1. **Learn Git basics** — see `docs/GIT_WORKFLOW.md` for clone, branch, commit, push, and PR commands
2. **Add your own page objects** — follow the guide in `docs/WRITING_TESTS.md`
3. **Expand the regression suite** — add more edge cases to `tests/regression/`
4. **Connect to CI/CD** — run `make smoke-android` in your GitHub Actions / GitLab CI / Jenkins pipeline
5. **Parallel execution** — use Pabot (`pip install robotframework-pabot`) to run suites in parallel
6. **Data-driven tests** — use the `DataDriver` library with `test_data/users.yaml` for table-driven tests
7. **Video recording** — add `appium:recordVideo` to the capabilities to capture test videos

---

*Built with Robot Framework 7.x, AppiumLibrary 2.x, and Appium 2.x.*
