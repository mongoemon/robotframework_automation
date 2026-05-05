*** Settings ***
Documentation    Regression Test Suite — Login Field Validation (Navigation Drawer Flow)
...
...              WHAT IS A REGRESSION SUITE?
...              Regression tests cover edge cases and negative paths to ensure that
...              new changes haven't broken existing functionality.
...
...              SOURCE: docs/test-cases.xlsx
...              These tests implement the MEDIUM PRIORITY test cases defined in the xlsx:
...
...              TC-AND-003 / TC-IOS-003 — Empty username shows field-level error
...              TC-AND-004 / TC-IOS-004 — Empty password shows field-level error
...
...              APP FLOW (navigation drawer):
...              The app launches to the Products screen (unauthenticated).
...              Login screen is reached via: hamburger menu (☰) → "Log In" menu item.
...
...              EXPECTED ERROR MESSAGES (from xlsx / demo app):
...              Empty username: "Username is required"
...              Empty password: "Enter Password"
...              (These match the SauceLabs Demo App — see test_data/users.yaml → demo_app_ui_strings)
...
...              HOW TO RUN:
...              Android:  robot --variable PLATFORM:android --include regression tests/regression/02_login_validation_regression.robot
...              iOS:      robot --variable PLATFORM:ios     --include regression tests/regression/02_login_validation_regression.robot
...              By ID:    robot --variable PLATFORM:android --include TC-AND-003 tests/
Metadata         Version     1.0
Metadata         Platform    ${PLATFORM}
Metadata         Source      docs/test-cases.xlsx

# ── Library imports ────────────────────────────────────────────────────────────
Library          AppiumLibrary
Library          yaml    WITH NAME    YAML

# ── Resource imports ──────────────────────────────────────────────────────────
Resource         ../../resources/variables/common_variables.robot
Resource         ../../resources/keywords/common_keywords.robot
Resource         ../../resources/keywords/appium_keywords.robot
Resource         ../../resources/pages/login_page.robot
Resource         ../../resources/pages/navigation_page.robot
Resource         ../../resources/pages/products_page.robot

# ── Suite-level setup / teardown ──────────────────────────────────────────────
Suite Setup       Open Mobile Application
Suite Teardown    Close Mobile Application

# ── Test-level setup / teardown ───────────────────────────────────────────────
Test Setup        Run Keywords
...               Start Test Video Recording
...               AND    Log Device Information
...               AND    Take Screenshot With Timestamp

Test Teardown     Run Keywords
...               Stop And Save Test Video
...               AND    Take Screenshot With Timestamp
...               AND    Run Keyword If Test Failed    Log    TEST FAILED — video and screenshot saved above.    level=WARN
...               AND    Return To Products Screen Unauthenticated

# ── Default tags applied to every test in this file ───────────────────────────
Test Tags         regression    login    validation


*** Variables ***
# Credentials from test-cases.xlsx — standard SauceLabs Demo App test account.
${DEMO_EMAIL}                   bod@example.com
${DEMO_PASSWORD}                10203040

# Expected field-level error messages (from xlsx / SauceLabs Demo App).
${ERROR_EMPTY_USERNAME}         Username is required
${ERROR_EMPTY_PASSWORD}         Enter Password


*** Test Cases ***
TC-AND-003 / TC-IOS-003 - Username Field Shows Error When Left Empty
    [Documentation]    Submits the login form with an empty username field and a valid
    ...                password, then verifies a field-level validation error appears.
    ...
    ...                STEPS (from xlsx):
    ...                    1. Launch the app.
    ...                    2. Navigate to Login screen via hamburger menu.
    ...                    3. Leave the username field blank.
    ...                    4. Enter password: 10203040
    ...                    5. Tap the login button.
    ...
    ...                PASS CRITERIA:
    ...                    - "Username is required" error is displayed below the username field.
    ...                    - User remains on the Login screen.
    ...
    ...                FAILURE INVESTIGATION:
    ...                    1. Check ${USERNAME_ERROR_MESSAGE} locator in common_variables.robot.
    ...                    2. Confirm the app shows a field-level error (not a toast/snackbar).
    ...                    3. Verify the expected error text matches the app's actual message.
    [Tags]    TC-AND-003    TC-IOS-003    regression    login    negative    validation
    Verify Products Screen Is Loaded
    Navigate To Login Via Menu
    Verify Login Page Is Loaded
    Clear Username Field
    Enter Password    ${DEMO_PASSWORD}
    Tap Login Button
    Verify Username Field Error Is    ${ERROR_EMPTY_USERNAME}
    Verify Login Page Is Loaded
    Log    TC-AND-003/TC-IOS-003 PASSED: Empty username shows "${ERROR_EMPTY_USERNAME}".    level=INFO

TC-AND-004 / TC-IOS-004 - Password Field Shows Error When Left Empty
    [Documentation]    Submits the login form with a valid username and an empty password
    ...                field, then verifies a field-level validation error appears.
    ...
    ...                STEPS (from xlsx):
    ...                    1. Launch the app.
    ...                    2. Navigate to Login screen via hamburger menu.
    ...                    3. Enter email: bod@example.com
    ...                    4. Leave the password field blank.
    ...                    5. Tap the login button.
    ...
    ...                PASS CRITERIA:
    ...                    - "Enter Password" error is displayed below the password field.
    ...                    - User remains on the Login screen.
    ...
    ...                FAILURE INVESTIGATION:
    ...                    1. Check ${PASSWORD_ERROR_MESSAGE} locator in common_variables.robot.
    ...                    2. Confirm the app shows a field-level error (not a toast/snackbar).
    ...                    3. Verify the expected error text matches the app's actual message.
    [Tags]    TC-AND-004    TC-IOS-004    regression    login    negative    validation
    Verify Products Screen Is Loaded
    Navigate To Login Via Menu
    Verify Login Page Is Loaded
    Enter Username    ${DEMO_EMAIL}
    Clear Password Field
    Tap Login Button
    Verify Password Field Error Is    ${ERROR_EMPTY_PASSWORD}
    Verify Login Page Is Loaded
    Log    TC-AND-004/TC-IOS-004 PASSED: Empty password shows "${ERROR_EMPTY_PASSWORD}".    level=INFO


*** Keywords ***
Verify Username Field Error Is
    [Documentation]    Asserts that the validation error label below the username field
    ...                shows the expected text.
    ...
    ...                Arguments:
    ...                    expected_error    — the exact error string to match
    ...
    ...                Example:
    ...                    Verify Username Field Error Is    Username is required
    [Arguments]    ${expected_error}
    Wait Until Element Is Visible    ${USERNAME_ERROR_MESSAGE}    timeout=${TIMEOUT}
    ...    error=Username field error did not appear after ${TIMEOUT}. Expected: '${expected_error}'
    ${actual}=    Get Text    ${USERNAME_ERROR_MESSAGE}
    Should Be Equal    ${actual}    ${expected_error}
    ...    msg=Wrong username error. Expected: '${expected_error}' | Got: '${actual}'
    Log    Username field error verified: '${actual}'    level=INFO

Verify Password Field Error Is
    [Documentation]    Asserts that the validation error label below the password field
    ...                shows the expected text.
    ...
    ...                Arguments:
    ...                    expected_error    — the exact error string to match
    ...
    ...                Example:
    ...                    Verify Password Field Error Is    Enter Password
    [Arguments]    ${expected_error}
    Wait Until Element Is Visible    ${PASSWORD_ERROR_MESSAGE}    timeout=${TIMEOUT}
    ...    error=Password field error did not appear after ${TIMEOUT}. Expected: '${expected_error}'
    ${actual}=    Get Text    ${PASSWORD_ERROR_MESSAGE}
    Should Be Equal    ${actual}    ${expected_error}
    ...    msg=Wrong password error. Expected: '${expected_error}' | Got: '${actual}'
    Log    Password field error verified: '${actual}'    level=INFO
