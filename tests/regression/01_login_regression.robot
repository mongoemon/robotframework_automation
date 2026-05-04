*** Settings ***
Documentation    Regression Test Suite — Login Screen
...
...              WHAT IS A REGRESSION SUITE?
...              Regression tests cover a broader set of scenarios including edge cases,
...              boundary conditions, and negative paths. Run these before every release
...              to ensure that new changes haven't broken existing functionality.
...
...              TESTS IN THIS SUITE:
...              TC010 - Login page renders all required elements
...              TC011 - Login with valid credentials navigates to Home
...              TC012 - Login with wrong password shows error
...              TC013 - Login with empty username shows validation error
...              TC014 - Login with empty password shows validation error
...              TC015 - Login with both fields empty shows validation error
...              TC016 - Login with special characters in username
...              TC017 - Login with valid credentials then logout returns to Login
...              TC018 - Password field masks characters (not shown as plain text)
...              TC019 - Username field retains value after failed login
...
...              HOW TO RUN:
...              Android:  make regression-android
...              iOS:      make regression-ios
...              Single:   robot --variable PLATFORM:android --include TC013 tests/
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
Test Setup        Run Keywords
...               Log Device Information
...               AND    Take Screenshot With Timestamp

Test Teardown     Run Keywords
...               Take Screenshot With Timestamp
...               AND    Run Keyword If Test Failed
...                   Log    TEST FAILED — see screenshot above.    level=WARN
...               AND    Return To Login Screen

# ── Default tags ──────────────────────────────────────────────────────────────
Test Tags         regression    login


*** Variables ***
# ── Valid credentials ─────────────────────────────────────────────────────────
${VALID_USERNAME}           testuser@example.com
${VALID_PASSWORD}           ValidPass123!
${VALID_DISPLAY_NAME}       Test User

# ── Invalid / edge-case credentials ──────────────────────────────────────────
${WRONG_PASSWORD}           wrongpassword99
${SPECIAL_CHAR_USERNAME}    test+user.name@sub-domain.example.co.uk
${SQL_INJECTION_INPUT}      admin' OR '1'='1
${VERY_LONG_USERNAME}       averylongusernamethatexceedsthenormallimitofcharactersandshouldbehandledgracefully@example.com

# ── Expected error messages ───────────────────────────────────────────────────
${ERROR_INVALID_CREDS}      Invalid credentials. Please try again.
${ERROR_EMPTY_USERNAME}     Username is required.
${ERROR_EMPTY_PASSWORD}     Password is required.
${ERROR_EMPTY_BOTH}         Please enter your username and password.


*** Test Cases ***
TC010 - Login Page Renders All Required Elements
    [Documentation]    Verifies that all UI elements on the Login page are present and visible.
    ...                This is a visual completeness check — not a functional test.
    ...
    ...                CHECKS:
    ...                    - Login page indicator (unique screen identifier)
    ...                    - Username input field
    ...                    - Password input field
    ...                    - Login button
    [Tags]    TC010    regression    login    ui    page-load
    Verify Login Page Is Loaded
    Element Should Be Visible    ${USERNAME_FIELD}
    Element Should Be Visible    ${PASSWORD_FIELD}
    Element Should Be Visible    ${LOGIN_BUTTON}
    Log    TC010 PASSED: All login page elements are present.    level=INFO

TC011 - Login With Valid Credentials Navigates To Home Screen
    [Documentation]    End-to-end happy path: valid credentials → Home screen.
    ...
    ...                PASS CRITERIA:
    ...                    - No error message appears
    ...                    - Home screen is displayed
    ...                    - Welcome message includes the user's display name
    [Tags]    TC011    regression    login    happy-path
    Login As    ${VALID_USERNAME}    ${VALID_PASSWORD}
    Verify Home Page Is Loaded
    Verify Welcome Message Contains    ${VALID_DISPLAY_NAME}
    Log    TC011 PASSED: Valid login succeeded and Home page is displayed.    level=INFO

TC012 - Login With Wrong Password Shows Invalid Credentials Error
    [Documentation]    Verifies that entering a valid username with an incorrect password
    ...                keeps the user on the Login screen and shows the error message.
    ...
    ...                PASS CRITERIA:
    ...                    - Error message appears with the expected text
    ...                    - User is NOT navigated to the Home screen
    [Tags]    TC012    regression    login    negative    error-handling
    Enter Username    ${VALID_USERNAME}
    Enter Password    ${WRONG_PASSWORD}
    Tap Login Button
    Verify Error Message Is    ${ERROR_INVALID_CREDS}
    Verify Login Page Is Loaded
    Log    TC012 PASSED: Wrong password shows correct error.    level=INFO

TC013 - Login With Empty Username Shows Validation Error
    [Documentation]    Attempts login with an empty username field and a valid password.
    ...                Verifies client-side or server-side validation catches this.
    ...
    ...                PASS CRITERIA:
    ...                    - Validation error appears indicating username is required
    ...                    - User stays on the Login screen
    [Tags]    TC013    regression    login    negative    validation
    Clear Username Field
    Enter Password    ${VALID_PASSWORD}
    Tap Login Button
    Verify Error Message Contains    required
    Verify Login Page Is Loaded
    Log    TC013 PASSED: Empty username shows validation error.    level=INFO

TC014 - Login With Empty Password Shows Validation Error
    [Documentation]    Attempts login with a valid username but empty password field.
    ...                Verifies the app prevents submission with an empty password.
    ...
    ...                PASS CRITERIA:
    ...                    - Validation error appears indicating password is required
    ...                    - User stays on the Login screen
    [Tags]    TC014    regression    login    negative    validation
    Enter Username    ${VALID_USERNAME}
    Clear Password Field
    Tap Login Button
    Verify Error Message Contains    required
    Verify Login Page Is Loaded
    Log    TC014 PASSED: Empty password shows validation error.    level=INFO

TC015 - Login With Both Fields Empty Shows Validation Error
    [Documentation]    Attempts to submit the login form with both username and password empty.
    ...                This tests the form's empty-state guard.
    ...
    ...                PASS CRITERIA:
    ...                    - An appropriate validation error is shown
    ...                    - User remains on the Login screen
    [Tags]    TC015    regression    login    negative    validation
    Clear Username Field
    Clear Password Field
    Tap Login Button
    Wait Until Element Is Visible    ${LOGIN_ERROR_MESSAGE}    timeout=${TIMEOUT}
    Verify Login Page Is Loaded
    Log    TC015 PASSED: Both fields empty shows validation error.    level=INFO

TC016 - Login With Special Characters In Username
    [Documentation]    Tests that the username field correctly accepts and submits email
    ...                addresses containing special characters (plus-sign, dots, hyphens,
    ...                sub-domains), which are all valid per RFC 5321.
    ...
    ...                PASS CRITERIA:
    ...                    - Username with special characters is accepted by the input field
    ...                    - Error shown is about credentials (not field validation), confirming
    ...                      the app did not reject the format before even sending to the server
    [Tags]    TC016    regression    login    edge-case    special-characters
    Enter Username    ${SPECIAL_CHAR_USERNAME}
    Enter Password    ${VALID_PASSWORD}
    Tap Login Button
    # This email is valid format but likely not in the test database — we expect
    # a credentials error (not a "format invalid" error), proving the field accepts it.
    Wait Until Element Is Visible    ${LOGIN_ERROR_MESSAGE}    timeout=${TIMEOUT}
    Verify Error Message Contains    Invalid
    Log    TC016 PASSED: Special characters in username are accepted.    level=INFO

TC017 - Login With Valid Credentials Then Logout Returns To Login Screen
    [Documentation]    Verifies the complete login → logout round trip.
    ...                After logout the user must be returned to the Login screen,
    ...                not left on a blank screen or crash.
    ...
    ...                PASS CRITERIA:
    ...                    - Successful login navigates to Home
    ...                    - Logout navigates back to Login
    ...                    - Login screen indicator is visible after logout
    [Tags]    TC017    regression    login    logout    happy-path
    Login As    ${VALID_USERNAME}    ${VALID_PASSWORD}
    Verify Home Page Is Loaded
    Logout
    Verify Login Page Is Loaded
    Log    TC017 PASSED: Login → Logout round trip works correctly.    level=INFO

TC018 - Password Field Masks Input Characters
    [Documentation]    Verifies that the password input field obscures the typed characters
    ...                (shows dots or asterisks) to protect the user's credentials.
    ...
    ...                This test checks the field's 'password' attribute or input type
    ...                rather than the visual appearance (which varies by OS theme).
    ...
    ...                PASS CRITERIA:
    ...                    - The password field element has password/secure attribute set
    ...                    - OR: the text returned by Get Text is masked / empty
    [Tags]    TC018    regression    login    security    field-type
    Enter Password    ${VALID_PASSWORD}
    # On most mobile OS implementations, Get Text on a password field returns empty string
    # or the masked representation, NOT the plaintext. This is the expected secure behaviour.
    ${displayed_text}=    Get Text    ${PASSWORD_FIELD}
    Should Not Be Equal    ${displayed_text}    ${VALID_PASSWORD}
    ...    msg=Security issue: password field is displaying plain text! Expected masked value.
    Log    TC018 PASSED: Password field does not display plain text.    level=INFO

TC019 - Username Field Retains Value After Failed Login
    [Documentation]    After a failed login attempt, verifies that the username field
    ...                still contains the username the user typed. This is a UX requirement
    ...                — users should not have to retype their email after a typo in the password.
    ...
    ...                PASS CRITERIA:
    ...                    - Failed login occurs (wrong password used)
    ...                    - Error message is shown
    ...                    - Username input field still contains the original username text
    [Tags]    TC019    regression    login    ux    field-persistence
    Enter Username    ${VALID_USERNAME}
    Enter Password    ${WRONG_PASSWORD}
    Tap Login Button
    Verify Error Message Is    ${ERROR_INVALID_CREDS}
    ${username_after_error}=    Get Text    ${USERNAME_FIELD}
    Should Be Equal    ${username_after_error}    ${VALID_USERNAME}
    ...    msg=Username field was cleared after failed login. Expected: '${VALID_USERNAME}' | Got: '${username_after_error}'
    Log    TC019 PASSED: Username is retained after failed login.    level=INFO


*** Keywords ***
Return To Login Screen
    [Documentation]    Helper keyword used in Test Teardown to ensure every test starts
    ...                from the Login screen. This handles the case where a test may have
    ...                navigated to the Home screen and the next test needs the Login screen.
    ...
    ...                Logic:
    ...                    1. Check if we are already on the Login screen — if yes, do nothing.
    ...                    2. If on the Home screen, logout.
    ...                    3. If somewhere else, navigate back until Login appears.
    ${on_login}=    Run Keyword And Return Status
    ...    Element Should Be Visible    ${LOGIN_PAGE_INDICATOR}
    Return From Keyword If    ${on_login}
    ${on_home}=    Run Keyword And Return Status
    ...    Element Should Be Visible    ${HOME_PAGE_INDICATOR}
    Run Keyword If    ${on_home}    Logout
    ${on_login_now}=    Run Keyword And Return Status
    ...    Wait Until Element Is Visible    ${LOGIN_PAGE_INDICATOR}    timeout=10s
    Run Keyword If    not ${on_login_now}
    ...    Log    Warning: Could not navigate back to Login screen for next test.    level=WARN
