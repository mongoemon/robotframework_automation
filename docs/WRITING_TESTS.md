# Writing Tests — Developer Guide

This guide explains how the project is structured and walks you through adding new screens, keywords, and test cases step by step.

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Locator Strategies](#locator-strategies)
3. [Using Appium Inspector to Find Locators](#using-appium-inspector-to-find-locators)
4. [Step 1 — Create a New Page Object File](#step-1--create-a-new-page-object-file)
5. [Step 2 — Add Keywords to a Page](#step-2--add-keywords-to-a-page)
6. [Step 3 — Write a New Test Case](#step-3--write-a-new-test-case)
7. [Naming Conventions](#naming-conventions)
8. [Tag Strategy](#tag-strategy)
9. [Data-Driven Tests with YAML](#data-driven-tests-with-yaml)
10. [Common Patterns](#common-patterns)

---

## Architecture Overview

```
                     ┌────────────────────────────────────┐
                     │          TEST SUITES               │
                     │   tests/smoke/01_login_smoke.robot │
                     │   tests/smoke/02_products_smoke    │
                     │   tests/regression/01_login_*.robot│
                     │   tests/regression/02_login_val_*  │
                     │                                    │
                     │  Calls page keywords in plain      │
                     │  English — no raw locators         │
                     └───────────────┬────────────────────┘
                                     │ Resources
                     ┌───────────────▼────────────────────┐
                     │         PAGE OBJECTS               │
                     │   resources/pages/login_page.robot │
                     │   resources/pages/home_page.robot  │
                     │   resources/pages/navigation_page  │
                     │   resources/pages/products_page    │
                     │   resources/pages/base_page.robot  │
                     │                                    │
                     │  Encapsulates screen interactions  │
                     │  Locators referenced by variable   │
                     └───────────────┬────────────────────┘
                                     │ Resources
              ┌──────────────────────┼──────────────────────┐
              │                      │                       │
┌─────────────▼───────┐ ┌───────────▼──────────┐ ┌─────────▼──────────────┐
│  COMMON KEYWORDS    │ │  APPIUM KEYWORDS      │ │  VARIABLES             │
│  common_keywords    │ │  appium_keywords      │ │  common_variables      │
│                     │ │                       │ │                        │
│  Wait And Click     │ │  Get Current Platform │ │  ${TIMEOUT}            │
│  Wait And Input Text│ │  Run Keyword For      │ │  ${USERNAME_FIELD}     │
│  Swipe Screen Up    │ │    Platform           │ │  ${LOGIN_BUTTON}       │
│  Take Screenshot    │ │  Accept Alert If      │ │  ${APPIUM_URL}         │
└─────────────┬───────┘ │    Present            │ └────────────────────────┘
              │         └───────────┬──────────┘
              └──────────────────────┘
                                     │ Uses
                     ┌───────────────▼────────────────────┐
                     │         AppiumLibrary               │
                     │                                    │
                     │  Click Element, Input Text,        │
                     │  Wait Until Element Is Visible,    │
                     │  Swipe, Capture Page Screenshot    │
                     └───────────────┬────────────────────┘
                                     │ Appium Protocol (HTTP/JSON Wire)
                     ┌───────────────▼────────────────────┐
                     │         APPIUM SERVER               │
                     │         localhost:4723              │
                     └───────────────┬────────────────────┘
                                     │
                     ┌───────────────▼────────────────────┐
                     │     Android / iOS Device            │
                     │     (Emulator or Real Device)       │
                     └────────────────────────────────────┘
```

**The key rule:** Tests only call Page Object keywords. Page Objects only call Common Keywords or AppiumLibrary. This separation means a UI change only requires updating one file.

---

## Locator Strategies

Appium supports several ways to find elements. Use them in this priority order:

### 1. accessibility_id (PREFERRED)

The most reliable locator. It uses the `content-desc` attribute on Android and `accessibilityLabel` on iOS.

```robot
# Robot Framework syntax
accessibility_id=Login Button

# In common_variables.robot
${LOGIN_BUTTON}    accessibility_id=Login Button
```

**How to set accessibility IDs in your app:**
- Android: add `android:contentDescription="Login Button"` to the View in XML
- iOS: add `.accessibilityLabel = "Login Button"` in Swift/ObjC, or `accessibilityLabel("Login Button")` in SwiftUI

### 2. id (resource-id)

Android resource IDs are stable and fast. Less reliable on iOS.

```robot
id=com.example.myapp:id/btn_login
```

### 3. xpath (FALLBACK ONLY)

Use xpath only when no accessibility_id or id is available. It is brittle (breaks when the view hierarchy changes) and slow.

```robot
# Android xpath
xpath=//android.widget.Button[@text='Login']

# iOS xpath
xpath=//XCUIElementTypeButton[@name='Login']
```

### 4. class_name

Useful for finding all elements of a type (e.g., all text fields).

```robot
class_name=android.widget.EditText
```

### Locator Format Reference

| Strategy | Robot Framework Format | When to Use |
|----------|----------------------|-------------|
| Accessibility ID | `accessibility_id=value` | Always try first |
| Resource ID | `id=com.pkg:id/view_id` | Android-specific |
| XPath | `xpath=//XCUIElementTypeButton` | Last resort |
| Class name | `class_name=android.widget.Button` | Finding groups |
| Android UIAutomator | `android_uiautomator=text("Login")` | Complex Android queries |
| iOS Predicate String | `ios_predicate=label == "Login"` | Complex iOS queries |

---

## Using Appium Inspector to Find Locators

Appium Inspector is a visual tool that lets you tap on any element in your running app and see all its locator attributes.

### Install Appium Inspector

Download from: https://github.com/appium/appium-inspector/releases

### Connect to Your Running Session

1. Start your Android emulator or iOS simulator
2. Start Appium: `appium`
3. Open Appium Inspector
4. Set the server URL: `http://localhost` port `4723`
5. Enter your capabilities (copy from your YAML config):

```json
{
  "platformName": "Android",
  "appium:deviceName": "Pixel_6_API_33",
  "appium:appPackage": "com.example.myapp",
  "appium:appActivity": ".MainActivity",
  "appium:automationName": "UiAutomator2"
}
```

6. Click **Start Session**

### Finding Element Locators

1. The app will appear in the Inspector window
2. Click the **pointer/cursor icon** in the toolbar
3. Click on any element in the app screenshot
4. The right panel shows all attributes:
   - `content-desc` → use as `accessibility_id=`
   - `resource-id` → use as `id=`
   - `text` → use in xpath: `//android.widget.TextView[@text='value']`

### Tips

- Prefer `content-desc` / accessibility ID whenever it has a meaningful value
- If `content-desc` is empty, ask your dev team to add accessibility labels — it benefits users with screen readers too
- Use the **search bar** in Inspector to test XPath expressions before putting them in your code

---

## Step 1 — Create a New Page Object File

Let's say you need to automate a **Profile screen**.

### 1a. Add the element locators to `common_variables.robot`

```robot
# resources/variables/common_variables.robot

# ─── Profile Page ──────────────────────────────────────────────────────────
${PROFILE_PAGE_INDICATOR}     accessibility_id=Profile Screen
${PROFILE_NAME_LABEL}         accessibility_id=Profile Name
${PROFILE_EMAIL_LABEL}        accessibility_id=Profile Email
${EDIT_PROFILE_BUTTON}        accessibility_id=Edit Profile Button
${SAVE_PROFILE_BUTTON}        accessibility_id=Save Profile Button
```

### 1b. Create the page object file

Create `resources/pages/profile_page.robot`:

```robot
*** Settings ***
Documentation    Page Object for the Profile Screen.
Library          AppiumLibrary
Resource         base_page.robot
Resource         ../variables/common_variables.robot
Resource         ../keywords/common_keywords.robot


*** Keywords ***
Verify Profile Page Is Loaded
    [Documentation]    Confirms the Profile screen is displayed.
    Verify Page Is Displayed    ${PROFILE_PAGE_INDICATOR}    Profile Page

Get Profile Name
    [Documentation]    Returns the display name shown on the profile screen.
    Wait Until Element Is Visible    ${PROFILE_NAME_LABEL}    timeout=${TIMEOUT}
    ${name}=    Get Text    ${PROFILE_NAME_LABEL}
    RETURN    ${name}

Tap Edit Profile Button
    [Documentation]    Opens the profile editing form.
    Wait And Click Element    ${EDIT_PROFILE_BUTTON}
```

---

## Step 2 — Add Keywords to a Page

Good keywords follow these principles:

1. **One action per keyword** — `Tap Login Button` not `Enter Credentials And Login`
   (except for deliberate compound keywords like `Login As`)
2. **Always document** — use `[Documentation]` to explain purpose, arguments, and examples
3. **Log important actions** — `Log    Tapped login button    level=INFO`
4. **Return values explicitly** — use `RETURN    ${value}` (Robot Framework 5+)
5. **Handle errors gracefully** — wrap risky calls in `Run Keyword And Return Status`

### Example — Adding an assertion keyword

```robot
Verify Profile Name Is
    [Documentation]    Asserts the profile name label shows the expected name.
    ...
    ...                Arguments:
    ...                    expected_name    — the name string expected on the profile
    ...
    ...                Example:
    ...                    Verify Profile Name Is    Test User
    [Arguments]    ${expected_name}
    ${actual_name}=    Get Profile Name
    Should Be Equal    ${actual_name}    ${expected_name}
    ...    msg=Wrong profile name. Expected: '${expected_name}' | Got: '${actual_name}'
    Log    Profile name verified: '${actual_name}'    level=INFO
```

---

## Step 3 — Write a New Test Case

### 3a. Choose the right test file

| Type | Location | When to use |
|------|----------|-------------|
| Smoke | `tests/smoke/` | Critical path, runs on every build |
| Regression | `tests/regression/` | Full coverage, runs before releases |

### 3b. Write the test case

Here is a complete example — a new test for the profile screen:

```robot
*** Settings ***
Documentation    Smoke Test Suite — Profile Screen
Library          AppiumLibrary
Resource         ../../resources/variables/common_variables.robot
Resource         ../../resources/keywords/common_keywords.robot
Resource         ../../resources/pages/login_page.robot
Resource         ../../resources/pages/home_page.robot
Resource         ../../resources/pages/profile_page.robot

Suite Setup      Run Keywords
...              Open Mobile Application
...              AND    Login As Valid User
Suite Teardown   Close Mobile Application
Test Setup       Take Screenshot With Timestamp
Test Teardown    Take Screenshot With Timestamp

Test Tags        smoke    profile


*** Test Cases ***
TC050 - Verify Profile Page Shows Correct User Name
    [Documentation]    After login, navigate to profile and verify the display name.
    ...
    ...                PASS CRITERIA:
    ...                    - Profile page loads without error
    ...                    - Name label shows the expected display name
    [Tags]    TC050    smoke    profile
    Verify Home Page Is Loaded
    Tap Menu Button
    # (add keyword to navigate to profile — add to home_page.robot)
    Verify Profile Page Is Loaded
    Verify Profile Name Is    Test User
    Log    TC050 PASSED: Profile name is correct.    level=INFO
```

### 3c. Run only your new test

```bash
robot --variable PLATFORM:android --include TC050 tests/
```

---

## Naming Conventions

### Files

| Item | Convention | Example |
|------|-----------|---------|
| Test suite files | `NN_descriptive_name.robot` | `01_login_smoke.robot` |
| Page object files | `screen_name_page.robot` | `profile_page.robot` |
| Keyword files | `topic_keywords.robot` | `network_keywords.robot` |
| Config files | `platform_capabilities.yaml` | `android_capabilities.yaml` |

### Test Cases

- Start with the test ID: `TC001 - Description Of What Is Verified`
- IDs in smoke suite: TC001–TC009
- IDs in regression suite: TC010+
- IDs in new feature suites: TC100+, TC200+, etc.
- IDs sourced from `docs/test-cases.xlsx` use the platform prefix format: `TC-AND-001 / TC-IOS-001 - Description`
  - Tag both IDs so the test is reachable with `--include TC-AND-001` **or** `--include TC-IOS-001`

### Keywords

- Verb-first: `Verify Login Page Is Loaded`, `Tap Menu Button`, `Get Welcome Message Text`
- Descriptive: `Wait And Click Element` not `Click`
- Compound keywords use "As" or "And": `Login As`, `Logout And Verify Login Screen`

### Variables

- Global constants: `${TIMEOUT}`, `${APPIUM_URL}` — ALL_CAPS in common_variables.robot
- Locators: `${LOGIN_BUTTON}`, `${USERNAME_FIELD}` — named by what they represent, not by type
- Local (within a keyword): `${actual_text}`, `${platform}` — lower_snake_case

---

## Tag Strategy

Tags let you run subsets of tests without editing files. Apply them at:
- The **suite level** with `Test Tags` (all tests in the file get these tags)
- The **test level** with `[Tags]` (in addition to, or overriding, suite tags)

### Standard Tags Used in This Project

| Tag | Meaning |
|-----|---------|
| `smoke` | Include in the quick smoke run |
| `regression` | Include in the full regression run |
| `TC001`, `TC002`... | Individual test IDs for original suites |
| `TC-AND-001`, `TC-IOS-001`... | Platform-specific IDs from `docs/test-cases.xlsx` |
| `login` | Tests related to the login feature |
| `products` | Tests related to the Products catalog screen |
| `home` | Tests related to the home screen |
| `happy-path` | Positive scenarios (valid inputs) |
| `negative` | Negative scenarios (invalid inputs, error paths) |
| `validation` | Form validation tests |
| `error-handling` | Error message / state tests |
| `security` | Security-related checks |
| `ux` | User experience checks (UX) |
| `edge-case` | Boundary conditions and unusual inputs |
| `content` | Tests that verify screen content (e.g., product count) |
| `logout` | Tests that exercise the logout flow |

### Running by Tag Examples

```bash
# Run all smoke tests
robot --include smoke tests/

# Run all tests tagged 'login' AND 'negative'
robot --include loginANDnegative tests/

# Run everything EXCEPT regression tests
robot --exclude regression tests/

# Run a single test by ID
robot --include TC013 tests/

# Run smoke tests but exclude security checks
robot --include smoke --exclude security tests/
```

---

## Data-Driven Tests with YAML

The `test_data/users.yaml` file stores test data separately from test logic. Use it like this:

```robot
*** Settings ***
Library    yaml    WITH NAME    YAML


*** Test Cases ***
Login With Valid User From YAML
    [Documentation]    Reads credentials from test_data/users.yaml at runtime.
    ${raw}=      Get File       ${TEST_DATA_FILE}
    ${data}=     YAML.Safe Load    ${raw}
    ${user}=     Get From Dictionary    ${data}    valid_user
    Login As    ${user}[username]    ${user}[password]
    Verify Home Page Is Loaded
```

### Using DataDriver for Table-Driven Tests

Install: `pip install robotframework-datadriver` (already in requirements.txt)

```robot
*** Settings ***
Library      DataDriver    test_data/users.yaml    selector=invalid_users
Test Template    Verify Invalid Login Shows Error


*** Test Cases ***
Login Fails For ${scenario}


*** Keywords ***
Verify Invalid Login Shows Error
    [Arguments]    ${username}    ${password}    ${expected_error}    ${scenario}
    Login As    ${username}    ${password}
    Verify Error Message Is    ${expected_error}
```

---

## Common Patterns

### Waiting for a screen transition

After tapping a button that navigates to a new screen, always verify the destination screen:

```robot
Tap Login Button
Verify Home Page Is Loaded    # This waits up to ${TIMEOUT} for the home screen
```

### Handling optional elements

Some elements may or may not appear (e.g., a "Rate Us" popup):

```robot
${popup_visible}=    Run Keyword And Return Status
...    Element Should Be Visible    accessibility_id=Rate Us Popup
Run Keyword If    ${popup_visible}    Click Element    accessibility_id=Not Now Button
```

### Scrolling to an off-screen element

```robot
Scroll Down To Find Element    accessibility_id=Submit Button
Wait And Click Element    accessibility_id=Submit Button
```

### Verifying text without caring about exact case

```robot
${text}=    Get Text    ${WELCOME_MESSAGE}
${text_lower}=    Convert To Lower Case    ${text}
Should Contain    ${text_lower}    hello
```

### Running different logic on Android vs iOS

```robot
Run Keyword For Platform
...    Android Specific Keyword    iOS Specific Keyword    optional_arg
```

### Navigation drawer flow (hamburger menu)

Some tests start from the Products screen and must navigate to Login via the hamburger menu.
Use `navigation_page.robot` for all drawer interactions — never call raw locators directly:

```robot
# Reach the Login screen via the navigation drawer
Verify Products Screen Is Loaded
Navigate To Login Via Menu        # opens drawer → taps "Log In"
Verify Login Page Is Loaded
Enter Username    ${DEMO_EMAIL}
Enter Password    ${DEMO_PASSWORD}
Tap Login Button
Verify Products Screen Is Loaded
```

Logout flow:

```robot
# Open drawer → tap "Log Out" → confirm dialog
Logout Via Menu
Verify Products Screen Is Loaded
Open Navigation Menu
Verify Login Menu Item Is Visible    # confirms session was cleared
Close Navigation Menu
```

Teardown for navigation drawer tests:

```robot
Test Teardown    Return To Products Screen Unauthenticated
```

`Return To Products Screen Unauthenticated` (defined in `navigation_page.robot`) handles all
post-test states: on Login screen, on authenticated Products screen, or drawer still open.

### Test credentials for xlsx-sourced tests

The suites in `02_products_smoke.robot` and `02_login_validation_regression.robot` use the
SauceLabs Demo App's built-in account defined in `test_data/users.yaml → demo_user`:

```robot
${DEMO_EMAIL}        bod@example.com
${DEMO_PASSWORD}     10203040
```

Expected field-level errors for this app:

| Scenario | Expected error text |
|---|---|
| Empty username | `Username is required` |
| Empty password | `Enter Password` |
