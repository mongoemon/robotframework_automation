# Environment Setup Guide — macOS & Windows

This guide walks you through setting up your machine from scratch to run Robot Framework mobile tests with Appium. Follow every step in order for your operating system.

**Estimated time:** 45–90 minutes (mostly downloads)

> **iOS testing** requires a Mac with Xcode. If you are on Windows, you can automate Android fully but not iOS.

---

## Table of Contents

0. [Get the Project (Git)](#0-get-the-project-git)
1. [Java JDK](#1-java-jdk)
2. [Android Studio and Android SDK](#2-android-studio-and-android-sdk)
3. [Create an Android Emulator](#3-create-an-android-emulator)
4. [Node.js](#4-nodejs)
5. [Appium Server](#5-appium-server)
6. [Appium Drivers](#6-appium-drivers)
7. [Verify Appium with appium-doctor](#7-verify-appium-with-appium-doctor)
8. [Python 3 and Virtual Environment](#8-python-3-and-virtual-environment)
9. [Install Project Dependencies](#9-install-project-dependencies)
10. [iOS Setup (macOS only)](#10-ios-setup-macos-only)
11. [Windows — Running Tests Without Shell Scripts](#11-windows--running-tests-without-shell-scripts)
12. [Final Verification Checklist](#12-final-verification-checklist)

---

## 0. Get the Project (Git)

### Install Git

**macOS** — Git ships with Xcode Command Line Tools:
```bash
git --version
# If not installed, macOS will prompt you to install it automatically
```

**Windows** — Download Git for Windows (includes Git Bash):
- Download from: https://git-scm.com/download/win
- Run the installer — the defaults are fine
- During install, choose **"Git Bash Here"** and **"Use Git from the Windows Command Prompt"**

Verify on both platforms:
```bash
git --version
# Expected: git version 2.x.x
```

### Clone the Repository

```bash
git clone https://github.com/mongoemon/robotframework_automation.git
cd robotframework_automation
```

### Verify the Clone

```bash
# Check that all files are present
ls -la       # macOS / Git Bash
dir          # Windows Command Prompt

# Check the default branch
git branch
# Expected: * main
```

> Already have the folder? See [GIT_WORKFLOW.md](GIT_WORKFLOW.md) for pull, branch, and commit commands.

---

## 1. Java JDK

Appium and the Android SDK require Java 11 or later (JDK 17 recommended).

### macOS

```bash
# Install Homebrew first if you don't have it
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install OpenJDK 17
brew install openjdk@17
```

Add to `~/.zshrc`:

```bash
# Java
export JAVA_HOME="/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home"
export PATH="$JAVA_HOME/bin:$PATH"
```

Apply and verify:

```bash
source ~/.zshrc
java -version
# Expected: openjdk version "17.x.x" ...
```

### Windows

1. Download the **Adoptium OpenJDK 17** installer:
   - Go to: https://adoptium.net
   - Select **JDK 17**, Windows x64, `.msi` installer
   - Run the installer — check **"Set JAVA_HOME variable"** during install (this is the easiest method)

2. Verify in a new Command Prompt or PowerShell window:

```powershell
java -version
# Expected: openjdk version "17.x.x" ...

$env:JAVA_HOME
# Expected: C:\Program Files\Eclipse Adoptium\jdk-17...
```

3. If `JAVA_HOME` is not set automatically, set it manually:
   - Open **Start → Search "Environment Variables" → Edit the system environment variables**
   - Click **Environment Variables...**
   - Under **System variables**, click **New**:
     - Variable name: `JAVA_HOME`
     - Variable value: `C:\Program Files\Eclipse Adoptium\jdk-17.x.x.x-hotspot`
   - Find the `Path` variable → **Edit** → **New** → add `%JAVA_HOME%\bin`
   - Click **OK** on all dialogs, then open a new terminal to verify

---

## 2. Android Studio and Android SDK

### macOS

1. Download from: https://developer.android.com/studio
2. Open the `.dmg` file and drag Android Studio to `/Applications`
3. Launch Android Studio and complete the setup wizard — accept defaults and let it download SDK components

**Configure environment variables** — add to `~/.zshrc`:

```bash
# Android SDK
export ANDROID_HOME="$HOME/Library/Android/sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export PATH="$ANDROID_HOME/emulator:$PATH"
export PATH="$ANDROID_HOME/platform-tools:$PATH"
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
```

```bash
source ~/.zshrc
adb version        # Expected: Android Debug Bridge version 1.x.x
avdmanager list avd
```

### Windows

1. Download from: https://developer.android.com/studio
2. Run the `.exe` installer — accept all defaults
3. Launch Android Studio and complete the setup wizard

**Find your SDK path:**
- Open Android Studio → **File → Settings → Appearance & Behavior → System Settings → Android SDK**
- Copy the **Android SDK Location** (typically `C:\Users\YOUR_NAME\AppData\Local\Android\Sdk`)

**Set environment variables:**
- Open **Environment Variables** (Start → search "Environment Variables")
- Under **System variables**, add:

| Variable | Value |
|----------|-------|
| `ANDROID_HOME` | `C:\Users\YOUR_NAME\AppData\Local\Android\Sdk` |
| `ANDROID_SDK_ROOT` | same as `ANDROID_HOME` |

- Edit the `Path` variable and add these four entries:

```
%ANDROID_HOME%\emulator
%ANDROID_HOME%\platform-tools
%ANDROID_HOME%\cmdline-tools\latest\bin
%ANDROID_HOME%\build-tools\34.0.0
```

Open a **new** Command Prompt and verify:

```cmd
adb version
:: Expected: Android Debug Bridge version 1.x.x

avdmanager list avd
```

### Install Required SDK Packages (both platforms)

Open Android Studio → **Tools → SDK Manager**, then install:

- **SDK Platforms tab:** Android 13 (API Level 33)
- **SDK Tools tab** (enable "Show Package Details" first):
  - Android SDK Build-Tools 34
  - Android Emulator
  - Android SDK Platform-Tools
  - Intel x86 Emulator Accelerator (HAXM) — for Intel CPU machines

---

## 3. Create an Android Emulator

### Using Android Studio GUI (same on both platforms)

1. Open Android Studio → **Tools → Device Manager**
2. Click **Create Device**
3. Select **Pixel 6** → Next
4. Select **API 33 (Android 13)** system image → Download if needed → Next
5. Name it `Pixel_6_API_33` (must match `deviceName` in `config/android_capabilities.yaml`)
6. Click **Finish**, then click the **Play** button to start it

### Using Command Line

**macOS:**
```bash
sdkmanager "system-images;android-33;google_apis;x86_64"
avdmanager create avd \
  --name "Pixel_6_API_33" \
  --package "system-images;android-33;google_apis;x86_64" \
  --device "pixel_6"
emulator -avd Pixel_6_API_33 &
adb devices
```

**Windows (Command Prompt):**
```cmd
sdkmanager "system-images;android-33;google_apis;x86_64"
avdmanager create avd ^
  --name "Pixel_6_API_33" ^
  --package "system-images;android-33;google_apis;x86_64" ^
  --device "pixel_6"
emulator -avd Pixel_6_API_33
```

Open a second Command Prompt and run:
```cmd
adb devices
:: Expected: emulator-5554   device
```

---

## 4. Node.js

Appium is a Node.js application. Install Node.js 18 or later.

### macOS

```bash
brew install node@20
```

Add to `~/.zshrc`:
```bash
export PATH="/opt/homebrew/opt/node@20/bin:$PATH"
```

**Alternative — nvm (Node Version Manager):**
```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
source ~/.zshrc
nvm install 20
nvm use 20
```

Verify:
```bash
node --version   # Expected: v20.x.x
npm --version    # Expected: 10.x.x
```

### Windows

**Option A — Official Installer (simplest):**
1. Download from: https://nodejs.org → choose **LTS (v20.x)**
2. Run the installer — it adds Node and npm to PATH automatically
3. Open a new terminal and verify:

```powershell
node --version   # Expected: v20.x.x
npm --version    # Expected: 10.x.x
```

**Option B — nvm-windows (recommended if you need multiple Node versions):**
1. Download from: https://github.com/coreybutler/nvm-windows/releases → `nvm-setup.exe`
2. Run installer
3. In an **Administrator** PowerShell:

```powershell
nvm install 20
nvm use 20
node --version
```

---

## 5. Appium Server

Install is the same on both platforms:

```bash
npm install -g appium
```

Verify:
```bash
appium --version
# Expected: 2.x.x
```

Start Appium (leave this terminal open while running tests):

```bash
appium
# Expected:
# [Appium] Welcome to Appium v2.x.x
# [Appium] Appium REST http interface listener started on http://0.0.0.0:4723
```

Test that Appium is responding — open a second terminal:

**macOS:**
```bash
curl http://localhost:4723/status
```

**Windows (PowerShell):**
```powershell
Invoke-RestMethod http://localhost:4723/status
# or use curl if Git Bash is installed:
curl http://localhost:4723/status
```

---

## 6. Appium Drivers

Same on both platforms:

```bash
# Android
appium driver install uiautomator2

# iOS (macOS only)
appium driver install xcuitest
```

Verify:
```bash
appium driver list --installed
# Expected:
#   uiautomator2@x.x.x [installed (npm)]
#   xcuitest@x.x.x     [installed (npm)]    ← macOS only
```

---

## 7. Verify Appium with appium-doctor

`appium-doctor` checks your environment for common problems and tells you exactly what to fix.

```bash
npm install -g @appium/doctor
```

**Android check (both platforms):**
```bash
appium-doctor --android
```

**iOS check (macOS only):**
```bash
appium-doctor --ios
```

Fix everything flagged as **WARN** or **ERROR**. The most common issues are:

| Platform | Issue | Fix |
|----------|-------|-----|
| Both | `ANDROID_HOME is not set` | Add the environment variable (Step 2) |
| Both | `adb not in PATH` | Add `platform-tools` to PATH (Step 2) |
| Both | `JAVA_HOME is not set` | Add the environment variable (Step 1) |
| macOS | `Homebrew not found` | Install Homebrew (Step 1) |
| Windows | `ANDROID_HOME uses backslashes` | Use forward slashes or short path if needed |

---

## 8. Python 3 and Virtual Environment

### macOS

```bash
python3 --version   # Expected: Python 3.9.x or higher
```

If Python 3.9+ is not installed:
```bash
brew install python@3.11
```

Add to `~/.zshrc`:
```bash
export PATH="/opt/homebrew/opt/python@3.11/bin:$PATH"
```

Create and activate a virtual environment:
```bash
cd /path/to/robotframework_automation
python3 -m venv .venv
source .venv/bin/activate
# Prompt changes to: (.venv) $
```

Deactivate when done:
```bash
deactivate
```

### Windows

1. Download Python 3.11 from: https://www.python.org/downloads/
2. Run the installer — **check "Add Python to PATH"** on the first screen
3. Also check **"Install pip"**

Open a **new** Command Prompt or PowerShell and verify:
```cmd
python --version
:: Expected: Python 3.11.x

pip --version
:: Expected: pip 23.x from ...
```

Create and activate a virtual environment:

```cmd
cd C:\path\to\robotframework_automation

python -m venv .venv

:: Command Prompt:
.venv\Scripts\activate.bat

:: PowerShell:
.venv\Scripts\Activate.ps1
```

> **PowerShell execution policy:** If you see a "script cannot be loaded" error in PowerShell, run this once in an Administrator PowerShell window:
> ```powershell
> Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
> ```
> Then activate again.

Your prompt will change to `(.venv)`. You need to run the activate command every time you open a new terminal.

Deactivate when done:
```cmd
deactivate
```

---

## 9. Install Project Dependencies

With the virtual environment **active**, run:

**macOS:**
```bash
pip install --upgrade pip
pip install -r requirements.txt
```

**Windows:**
```cmd
python -m pip install --upgrade pip
pip install -r requirements.txt
```

Verify:

**macOS:**
```bash
python3 -c "import robot; print('Robot Framework', robot.version.VERSION)"
python3 -c "from AppiumLibrary import AppiumLibrary; print('AppiumLibrary OK')"
robot --version
```

**Windows:**
```cmd
python -c "import robot; print('Robot Framework', robot.version.VERSION)"
python -c "from AppiumLibrary import AppiumLibrary; print('AppiumLibrary OK')"
robot --version
```

---

## 10. iOS Setup (macOS only)

> Skip this section if you are on Windows — iOS automation requires macOS + Xcode.

### Install Xcode

1. Open the **App Store**
2. Search for "Xcode"
3. Install Xcode (large download — allow 30–60 minutes)

### Install Xcode Command Line Tools

```bash
xcode-select --install
sudo xcodebuild -license accept
```

### Install Carthage (required by XCUITest driver)

```bash
brew install carthage
```

### Boot an iOS Simulator

```bash
# List available simulators
xcrun simctl list devices available | grep "iPhone"

# Boot one (name must match deviceName in ios_capabilities.yaml)
xcrun simctl boot "iPhone 15 Pro"

# Open the Simulator app to see it
open -a Simulator
```

### Verify

```bash
xcrun simctl list devices | grep Booted
# Expected: iPhone 15 Pro (XXXXXXXX-...) (Booted)
```

---

## 11. Windows — Running Tests Without Shell Scripts

The `scripts/run_android.sh` and `scripts/run_ios.sh` files are Bash scripts and do not run natively on Windows. You have three options:

### Option A — Git Bash (easiest)

Git Bash ships with Git for Windows and runs `.sh` scripts natively:

1. Download Git for Windows: https://git-scm.com/download/win
2. During install, choose **"Git Bash Here"** context menu option
3. Open Git Bash and run:

```bash
bash scripts/run_android.sh --tags smoke
```

### Option B — WSL 2 (Windows Subsystem for Linux)

WSL gives you a full Linux environment on Windows. This is the most compatible option for long-term use.

```powershell
# In Administrator PowerShell:
wsl --install
# Restart, then open Ubuntu from Start menu
```

Inside WSL, follow the macOS/Linux instructions in this guide. Note: you still need Android Studio and ADB on the Windows side; configure `adb` forwarding from WSL.

### Option C — Run `robot` Directly (no shell scripts needed)

Skip the scripts entirely and call Robot Framework directly from Command Prompt or PowerShell:

```cmd
:: Activate venv
.venv\Scripts\activate.bat

:: Run smoke tests on Android
robot ^
  --variable PLATFORM:android ^
  --include smoke ^
  --outputdir results\run_%DATE:~10,4%%DATE:~4,2%%DATE:~7,2% ^
  --loglevel INFO ^
  tests\

:: Run all regression tests
robot --variable PLATFORM:android --include regression --outputdir results\ tests\
```

```powershell
# PowerShell version
robot `
  --variable PLATFORM:android `
  --include smoke `
  --outputdir results\run_$(Get-Date -Format 'yyyyMMdd_HHmmss') `
  tests\
```

### Option D — Make (via Chocolatey)

Install `make` on Windows so the `Makefile` targets work:

```powershell
# Install Chocolatey (in Administrator PowerShell):
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install make
choco install make
```

Then use `make smoke-android`, `make regression-android`, etc. — same as macOS.

---

## 12. Final Verification Checklist

### macOS

```bash
# 1. Java
java -version && echo "Java OK"

# 2. Android SDK
adb version && echo "adb OK"
emulator -list-avds && echo "AVDs OK"

# 3. Node.js
node --version && npm --version && echo "Node OK"

# 4. Appium
appium --version && echo "Appium OK"
appium driver list --installed

# 5. Python + Robot Framework
python3 --version
robot --version

# 6. AppiumLibrary
python3 -c "from AppiumLibrary import AppiumLibrary; print('AppiumLibrary OK')"

# 7. Start emulator
emulator -avd Pixel_6_API_33 &
sleep 15
adb devices | grep "device$" && echo "Emulator connected OK"

# 8. Start Appium (separate terminal), then check
appium &
sleep 3
curl -s http://localhost:4723/status | python3 -m json.tool | grep '"ready"' && echo "Appium running OK"

# 9. Dry-run (validates syntax — no device needed)
source .venv/bin/activate
robot --dryrun --variable PLATFORM:android tests/
```

### Windows (Command Prompt)

```cmd
:: 1. Java
java -version

:: 2. Android SDK
adb version
emulator -list-avds

:: 3. Node.js
node --version && npm --version

:: 4. Appium
appium --version
appium driver list --installed

:: 5. Python + Robot Framework
python --version
robot --version

:: 6. AppiumLibrary
python -c "from AppiumLibrary import AppiumLibrary; print('AppiumLibrary OK')"

:: 7. Start emulator (in separate window), then check
adb devices

:: 8. Start Appium (in separate window: appium), then check status
powershell -Command "Invoke-RestMethod http://localhost:4723/status"

:: 9. Dry-run
.venv\Scripts\activate.bat
robot --dryrun --variable PLATFORM:android tests\
```

If all steps pass, you are ready to run tests. Go to:

- [README Quick Start](../README.md#quick-start) — five-step overview
- [RUNNING_ON_DEVICE.md](RUNNING_ON_DEVICE.md) — detailed emulator/simulator run guide with app download, locator discovery, and per-platform troubleshooting

---

## Common Environment Problems

| Error | Platform | Cause | Fix |
|-------|----------|-------|-----|
| `adb: command not found` | Both | PATH missing platform-tools | Add `%ANDROID_HOME%\platform-tools` to PATH |
| `JAVA_HOME is not set` | Both | JAVA_HOME not exported | Add environment variable (Step 1) |
| `appium: command not found` | Both | npm global bin not in PATH | Run `npm config get prefix`, add its `bin` to PATH |
| `robot: command not found` | Both | venv not activated | Run activate command (Step 8) |
| `.venv\Scripts\Activate.ps1 cannot be loaded` | Windows | PowerShell execution policy | Run `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser` |
| `Simulator could not be found` | macOS | Wrong device name | Run `xcrun simctl list devices` for exact name |
| `appium driver list` is empty | Both | Drivers not installed | Run `appium driver install uiautomator2` |
| `emulator: command not found` | Both | Emulator not in PATH | Add `%ANDROID_HOME%\emulator` to PATH |

See `docs/TROUBLESHOOTING.md` for detailed fixes.
