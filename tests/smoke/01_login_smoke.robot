*** Settings ***
Documentation    Smoke Test Suite — Login Screen
...
...              WHAT IS A SMOKE TEST?
...              Smoke tests are fast, high-level checks that verify the most critical
...              paths work at all. Run these after every build to catch showstopper bugs.
...              They should complete in under 5 minutes.
...
...              TESTS IN THIS SUITE:
...              TC001 - Verify Login Page Is Displayed       (page renders correctly)
...              TC002 - Login With Valid Credentials          (happy path — must always work)
...              TC003 - Login With Invalid Password           (error handling — basic guard)
...
...              HOW TO RUN:
...              Android:  make smoke-android
...              iOS:      make smoke-ios
...              Manual:   robot --variable PLATFORM:android --include smoke tests/smoke/
...
...              TAGS:
...              smoke        — all tests in this file
...              TC001-TC003  — individual test IDs for targeted runs
Metadata         Version     1.0
Metadata         Platform    ${PLATFORM}

# ── Library imports ────────────────────────────────────────────────────────────
Library          AppiumLibrary
Library          yaml    WITH NAME    YAML

# ── Resource imports ──────────────────────────────────────────────────────────
Resource         ../../resources/variables/common_variables.robot
Resource         ../../resources/keywords/common_keywords.robot
Resource         ../../resources/keywords/appium_keywords.robot
Resource         ../../resources/pages/login_page.robot
Resource         ../../resources/pages/home_page.robot
Resource         ../../resources/pages/navigation_page.robot
Resource         ../../resources/pages/products_page.robot

# ── Suite-level setup / teardown ──────────────────────────────────────────────
# App launches to Products screen — navigate to Login via hamburger menu.
Suite Setup       Run Keywords    Open Mobile Application    AND    Navigate To Login Via Menu
Suite Teardown    Close Mobile Application

# ── Test-level setup / teardown ───────────────────────────────────────────────
# Video recording wraps each test; screenshot is taken as a still precondition/result frame.
# Videos are saved to the output directory as <TestName>.mp4 and embedded in log.html.
# Each teardown returns to the Login screen so the next test always starts there.
Test Setup        Run Keywords    Start Test Video Recording    AND    Take Screenshot With Timestamp
Test Teardown     Run Keywords
...               Stop And Save Test Video
...               AND    Take Screenshot With Timestamp
...               AND    Run Keyword If Test Failed    Log    TEST FAILED — video and screenshot saved above.    level=WARN
...               AND    Return To Login Screen In Smoke

# ── Default tags applied to every test in this file ───────────────────────────
Test Tags         smoke    login


*** Variables ***
# SauceLabs My Demo App v2.2.0 credentials (pre-filled on the login screen)
${VALID_USERNAME}       bod@example.com
${VALID_PASSWORD}       10203040
${LOCKED_USERNAME}      alice@example.com
${LOCKED_PASSWORD}      10203040


*** Test Cases ***
TC001 - Verify Login Page Is Displayed
    [Documentation]    Confirms that launching the app shows the Login screen with all
    ...                expected UI elements: username field, password field, and login button.
    ...
    ...                PASS CRITERIA:
    ...                    - Login page indicator element is visible
    ...                    - Login button is present and tappable
    ...
    ...                FAILURE INVESTIGATION:
    ...                    1. Check the screenshot in the report
    ...                    2. Confirm the app launched (check Appium logs)
    ...                    3. Verify ${LOGIN_PAGE_INDICATOR} locator is correct for your app
    [Tags]    TC001    smoke    login    page-load
    Verify Login Page Is Loaded
    Verify Login Button Is Displayed
    Log    TC001 PASSED: Login page is displayed correctly.    level=INFO

TC002 - Login With Valid Credentials Should Navigate To Products Screen
    [Documentation]    Performs a full login with valid credentials and verifies the
    ...                user lands on the Products catalog screen.
    ...
    ...                NOTE: SauceLabs Demo App v2.2.0 returns to the Products screen
    ...                after login (there is no separate Home screen).
    ...
    ...                PASS CRITERIA:
    ...                    - Username and password accepted without error
    ...                    - Products catalog screen is displayed after tapping Login
    ...
    ...                FAILURE INVESTIGATION:
    ...                    1. Confirm credentials match the app (bod@example.com / 10203040)
    ...                    2. Verify ${PRODUCTS_SCREEN_INDICATOR} locator is correct
    [Tags]    TC002    smoke    login    happy-path
    Login As    ${VALID_USERNAME}    ${VALID_PASSWORD}
    Verify Products Screen Is Loaded
    Log    TC002 PASSED: Successful login shows the Products screen.    level=INFO

TC003 - Empty Login Form Shows Field Validation Errors
    [Documentation]    Submits the login form with both fields empty and verifies
    ...                that the username field shows a required-field error.
    ...
    ...                NOTE: SauceLabs Demo App v2.2.0 accepts any non-empty credentials
    ...                without server-side validation. Field-level errors appear only
    ...                when fields are left empty.
    ...
    ...                PASS CRITERIA:
    ...                    - Tapping Login with empty fields shows the username error
    ...                    - User remains on the Login screen
    ...
    ...                FAILURE INVESTIGATION:
    ...                    1. Verify ${USERNAME_ERROR_MESSAGE} locator is correct
    [Tags]    TC003    smoke    login    validation
    Tap Login Button
    Wait Until Element Is Visible    ${USERNAME_ERROR_MESSAGE}    timeout=${TIMEOUT}
    Verify Login Page Is Loaded
    Log    TC003 PASSED: Empty form shows field validation error.    level=INFO


*** Keywords ***
Return To Login Screen In Smoke
    [Documentation]    Teardown helper — returns the app to the Login screen between tests.
    ...                Handles three states: already on Login, on Products authenticated, on Products unauthenticated.
    ${on_login}=    Run Keyword And Return Status
    ...    Wait Until Element Is Visible    ${LOGIN_PAGE_INDICATOR}    timeout=5s
    Return From Keyword If    ${on_login}
    Open Navigation Menu
    ${authenticated}=    Run Keyword And Return Status
    ...    Wait Until Element Is Visible    ${LOGOUT_MENU_ITEM}    timeout=3s
    Run Keyword If    ${authenticated}    Tap Logout Menu Item
    Run Keyword If    ${authenticated}    Confirm Logout
    Run Keyword If    not ${authenticated}    Close Navigation Menu
    Navigate To Login Via Menu
