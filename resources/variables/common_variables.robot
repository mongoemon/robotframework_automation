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
${ANDROID_APP_ID}       com.saucelabs.mydemoapp.android

# iOS bundle identifier — must match bundleId in ios_capabilities.yaml
${IOS_APP_ID}           com.saucelabs.mydemoapp.ios

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
# Confirmed via UIAutomator dump against SauceLabs My Demo App v2.2.0

# Page-level identifier — the "Login" title TextView at the top of the login screen
${LOGIN_PAGE_INDICATOR}         id=com.saucelabs.mydemoapp.android:id/loginTV

# Username / email input field (no content-desc; identified by resource-id)
${USERNAME_FIELD}               id=com.saucelabs.mydemoapp.android:id/nameET

# Password input field
${PASSWORD_FIELD}               id=com.saucelabs.mydemoapp.android:id/passwordET

# The main Login button
${LOGIN_BUTTON}                 accessibility_id=Tap to login with given credentials

# Error message element for invalid / rejected credentials (app-level error)
# NOTE: SauceLabs Demo App v2.2.0 accepts any credentials and does not display
# a credential-level error via the UI hierarchy. Field-level errors use
# ${USERNAME_ERROR_MESSAGE} and ${PASSWORD_ERROR_MESSAGE} below.
${LOGIN_ERROR_MESSAGE}          id=com.saucelabs.mydemoapp.android:id/errorTV

# "Forgot password?" link (not present in SauceLabs Demo App v2.2.0)
${FORGOT_PASSWORD_LINK}         accessibility_id=Forgot Password Link

# ─────────────────────────────────────────────────────────────────────────────
# Home Page — Element Locators
# NOTE: The SauceLabs Demo App returns to the Products screen after login.
# There is no separate "Home" screen. Both indicators point to the same element.
# ─────────────────────────────────────────────────────────────────────────────

# After login the app stays on the Products catalog screen
${HOME_PAGE_INDICATOR}          accessibility_id=Displays all products of catalog

# Welcome banner — not present in SauceLabs Demo App v2.2.0
${WELCOME_MESSAGE}              accessibility_id=Welcome Message

# Hamburger / navigation menu button (top-left toolbar icon)
${MENU_BUTTON}                  accessibility_id=View menu

# Logout button — in SauceLabs Demo App logout is via nav drawer (use ${LOGOUT_MENU_ITEM})
${LOGOUT_BUTTON}                accessibility_id=Logout Menu Item

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
# Confirmed via UIAutomator dump (content-desc values from the live app)
# ─────────────────────────────────────────────────────────────────────────────

# Hamburger / navigation drawer toggle (☰) button — top-left toolbar
${HAMBURGER_MENU}               accessibility_id=View menu

# "Log In" item inside the navigation drawer — visible when NOT authenticated
${LOGIN_MENU_ITEM}              accessibility_id=Login Menu Item

# "Log Out" item inside the navigation drawer — visible when authenticated
${LOGOUT_MENU_ITEM}             accessibility_id=Logout Menu Item

# "LOGOUT" confirm button in the AlertDialog that appears after tapping Log Out
# Uses the standard Android system resource-id for the positive button
${LOGOUT_CONFIRM_BUTTON}        id=android:id/button1

# ─────────────────────────────────────────────────────────────────────────────
# Products Catalog Screen — Element Locators
# Confirmed via UIAutomator dump
# ─────────────────────────────────────────────────────────────────────────────

# Page-level identifier — the RecyclerView that contains all product items
${PRODUCTS_SCREEN_INDICATOR}    accessibility_id=Displays all products of catalog

# Individual product card (used for counting: each product has one title element)
${PRODUCT_ITEM}                 accessibility_id=Product Title

# Product title text inside a product card
${PRODUCT_TITLE}                accessibility_id=Product Title

# ─────────────────────────────────────────────────────────────────────────────
# Field-Level Validation Error Messages
# Confirmed: appears when the login form is submitted with empty fields
# ─────────────────────────────────────────────────────────────────────────────

# Error label below the username field when submitted empty ("Username is required")
${USERNAME_ERROR_MESSAGE}       id=com.saucelabs.mydemoapp.android:id/nameErrorTV

# Error label below the password field when submitted with username only ("Enter Password")
${PASSWORD_ERROR_MESSAGE}       id=com.saucelabs.mydemoapp.android:id/passwordErrorTV
