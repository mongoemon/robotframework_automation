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

# ── Suite-level setup / teardown ──────────────────────────────────────────────
Suite Setup       Open Mobile Application
Suite Teardown    Close Mobile Application

# ── Test-level setup / teardown ───────────────────────────────────────────────
# Take a screenshot before each test (precondition state) and after (result state).
# Screenshots are embedded in the HTML report automatically.
Test Setup        Take Screenshot With Timestamp
Test Teardown     Run Keywords
...               Take Screenshot With Timestamp
...               AND    Run Keyword If Test Failed    Log    TEST FAILED — screenshot saved above.    level=WARN

# ── Default tags applied to every test in this file ───────────────────────────
Test Tags         smoke    login


*** Variables ***
# Inline test data — matches structure in test_data/users.yaml
${VALID_USERNAME}       testuser@example.com
${VALID_PASSWORD}       ValidPass123!
${INVALID_PASSWORD}     wrongpassword99
${EXPECTED_ERROR}       Invalid credentials. Please try again.


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

TC002 - Login With Valid Credentials Should Navigate To Home
    [Documentation]    Performs a full login with valid credentials and verifies the
    ...                user is redirected to the Home screen.
    ...
    ...                PASS CRITERIA:
    ...                    - Username and password accepted without error
    ...                    - Home screen is displayed after tapping Login
    ...                    - Welcome message is visible on the Home screen
    ...
    ...                FAILURE INVESTIGATION:
    ...                    1. Confirm valid credentials match what is in your test environment
    ...                    2. Check if the error message element appeared (screenshot)
    ...                    3. Verify ${HOME_PAGE_INDICATOR} locator is correct
    [Tags]    TC002    smoke    login    happy-path
    Login As    ${VALID_USERNAME}    ${VALID_PASSWORD}
    Verify Home Page Is Loaded
    Verify Home Page Elements Are Present
    Log    TC002 PASSED: Successful login navigated to Home page.    level=INFO

TC003 - Login With Invalid Password Should Show Error Message
    [Documentation]    Attempts login with a correct username but wrong password,
    ...                and verifies that an appropriate error message is shown.
    ...
    ...                PASS CRITERIA:
    ...                    - User remains on the Login screen (no navigation to Home)
    ...                    - Error message element appears with the expected text
    ...
    ...                FAILURE INVESTIGATION:
    ...                    1. Check if the app navigated away (it should NOT)
    ...                    2. Check if the error message has a different locator or text
    ...                    3. Verify ${LOGIN_ERROR_MESSAGE} locator in common_variables.robot
    [Tags]    TC003    smoke    login    error-handling
    Login As    ${VALID_USERNAME}    ${INVALID_PASSWORD}
    Verify Error Message Is    ${EXPECTED_ERROR}
    Verify Login Page Is Loaded
    Log    TC003 PASSED: Invalid password shows correct error message.    level=INFO
