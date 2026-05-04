*** Settings ***
Documentation    Common variables shared across the entire test suite.
...              Override any variable at runtime with: robot --variable VAR_NAME:value


*** Variables ***
# ─────────────────────────────────────────────────────────────────────────────
# Appium Server
# ─────────────────────────────────────────────────────────────────────────────

# URL of the running Appium server. Change port if you run Appium on a different port.
${APPIUM_URL}           http://localhost:4723

# ─────────────────────────────────────────────────────────────────────────────
# App Identifiers
# Used by Activate Application (e.g., after Reset Application State).
# Override at runtime: robot --variable ANDROID_APP_ID:com.your.app
# ─────────────────────────────────────────────────────────────────────────────

# Android package name — must match appPackage in android_capabilities.yaml
${ANDROID_APP_ID}       com.example.myapp

# iOS bundle identifier — must match bundleId in ios_capabilities.yaml
${IOS_APP_ID}           com.example.myapp

# ─────────────────────────────────────────────────────────────────────────────
# Platform
# Set at runtime:  robot --variable PLATFORM:ios  or  PLATFORM=ios make smoke-ios
# ─────────────────────────────────────────────────────────────────────────────

# Target platform for this test run. Accepted values: android | ios
${PLATFORM}             android

# ─────────────────────────────────────────────────────────────────────────────
# Global Timeouts
# ─────────────────────────────────────────────────────────────────────────────

# Maximum time to wait for an element to appear before failing.
${TIMEOUT}              30s

# How often Robot Framework checks for the element during the wait period.
${RETRY_INTERVAL}       2s

# Time to wait for the app to fully launch before interacting with elements.
${APP_LOAD_TIMEOUT}     15s

# ─────────────────────────────────────────────────────────────────────────────
# Config File Paths
# These are resolved relative to the project root at runtime.
# ─────────────────────────────────────────────────────────────────────────────
${ANDROID_CONFIG_FILE}    ${CURDIR}/../../config/android_capabilities.yaml
${IOS_CONFIG_FILE}        ${CURDIR}/../../config/ios_capabilities.yaml
${TEST_DATA_FILE}         ${CURDIR}/../../test_data/users.yaml

# ─────────────────────────────────────────────────────────────────────────────
# Screenshot Settings
# ─────────────────────────────────────────────────────────────────────────────

# Directory where screenshots are saved (relative to results/).
${SCREENSHOT_DIR}       ${EXECDIR}/results/screenshots

# ─────────────────────────────────────────────────────────────────────────────
# Login Page — Element Locators
#
# Locator strategy guide:
#   accessibility_id  = content-desc (Android) or accessibilityLabel (iOS)  ← PREFERRED
#   xpath             = slow but universal fallback
#   id                = resource-id on Android, bundleId+id on iOS
#
# HOW TO FIND YOUR LOCATORS:
#   1. Start Appium Inspector (https://github.com/appium/appium-inspector)
#   2. Connect to your running Appium session
#   3. Click on each element to see its attributes
#   4. Prefer accessibility_id > id > xpath (in that order)
# ─────────────────────────────────────────────────────────────────────────────

# --- Login Screen ---
# The page-level identifier used to confirm we are on the login screen.
${LOGIN_PAGE_INDICATOR}         accessibility_id=Login Screen

# Input field for the user's email / username
${USERNAME_FIELD}               accessibility_id=Username Input

# Input field for the user's password
${PASSWORD_FIELD}               accessibility_id=Password Input

# The main "Log In" / "Sign In" button
${LOGIN_BUTTON}                 accessibility_id=Login Button

# Error message shown when credentials are invalid
${LOGIN_ERROR_MESSAGE}          accessibility_id=Login Error Message

# "Forgot password?" link (used in regression tests)
${FORGOT_PASSWORD_LINK}         accessibility_id=Forgot Password Link

# ─────────────────────────────────────────────────────────────────────────────
# Home Page — Element Locators
# ─────────────────────────────────────────────────────────────────────────────

# The page-level identifier used to confirm we landed on the home screen.
${HOME_PAGE_INDICATOR}          accessibility_id=Home Screen

# Welcome banner or greeting message shown after login
${WELCOME_MESSAGE}              accessibility_id=Welcome Message

# Hamburger / navigation menu button
${MENU_BUTTON}                  accessibility_id=Menu Button

# Logout option inside the navigation menu
${LOGOUT_BUTTON}                accessibility_id=Logout Button

# ─────────────────────────────────────────────────────────────────────────────
# Common UI Elements
# ─────────────────────────────────────────────────────────────────────────────

# Generic "OK" button that appears in system / app alerts
${ALERT_OK_BUTTON}              accessibility_id=OK

# Generic "Allow" button in iOS permission dialogs
${ALERT_ALLOW_BUTTON}           accessibility_id=Allow

# Back navigation button (Android hardware or iOS navigation bar)
${BACK_BUTTON}                  accessibility_id=Navigate up

# ─────────────────────────────────────────────────────────────────────────────
# Navigation Drawer — Element Locators
# ─────────────────────────────────────────────────────────────────────────────

# Hamburger / navigation drawer toggle (☰) button
${HAMBURGER_MENU}               accessibility_id=open menu

# "Log In" item inside the navigation drawer — visible when not authenticated
${LOGIN_MENU_ITEM}              accessibility_id=menu item log in

# "Log Out" item inside the navigation drawer — visible when authenticated
${LOGOUT_MENU_ITEM}             accessibility_id=menu item log out

# "LOGOUT" confirm button inside the logout confirmation dialog
${LOGOUT_CONFIRM_BUTTON}        accessibility_id=Logout Confirm Button

# ─────────────────────────────────────────────────────────────────────────────
# Products Catalog Screen — Element Locators
# ─────────────────────────────────────────────────────────────────────────────

# Page-level identifier to confirm the Products catalog screen is displayed
${PRODUCTS_SCREEN_INDICATOR}    accessibility_id=Products Screen

# Individual product card / list item in the catalog
${PRODUCT_ITEM}                 accessibility_id=Product Item

# Product title text inside a product card
${PRODUCT_TITLE}                accessibility_id=Product Title

# ─────────────────────────────────────────────────────────────────────────────
# Field-Level Validation Error Messages
# ─────────────────────────────────────────────────────────────────────────────

# Error label shown below the username field when submitted empty
${USERNAME_ERROR_MESSAGE}       accessibility_id=Username Error Message

# Error label shown below the password field when submitted empty
${PASSWORD_ERROR_MESSAGE}       accessibility_id=Password Error Message
