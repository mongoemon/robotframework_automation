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
Resource         ../../resources/pages/navigation_page.robot
Resource         ../../resources/pages/products_page.robot

# ── Suite-level setup / teardown ──────────────────────────────────────────────
# App launches to Products screen — navigate to Login via hamburger menu.
Suite Setup       Run Keywords    Open Mobile Application    AND    Navigate To Login Via Menu
Suite Teardown    Close Mobile Application

# ── Test-level setup / teardown ───────────────────────────────────────────────
Test Setup        Run Keywords
...               Start Test Video Recording
...               AND    Log Device Information
...               AND    Take Screenshot With Timestamp

Test Teardown     Run Keywords
...               Stop And Save Test Video
...               AND    Take Screenshot With Timestamp
...               AND    Run Keyword If Test Failed
...                   Log    TEST FAILED — video and screenshot saved above.    level=WARN
...               AND    Return To Login Screen

# ── Default tags ──────────────────────────────────────────────────────────────
Test Tags         regression    login


*** Variables ***
# ── Valid credentials — SauceLabs My Demo App v2.2.0 ─────────────────────────
${VALID_USERNAME}           bod@example.com
${VALID_PASSWORD}           10203040

# ── Edge-case inputs ──────────────────────────────────────────────────────────
${SPECIAL_CHAR_USERNAME}    test+user.name@sub-domain.example.co.uk
${SQL_INJECTION_INPUT}      admin' OR '1'='1
${VERY_LONG_USERNAME}       averylongusernamethatexceedsthenormallimitofcharactersandshouldbehandledgracefully@example.com

# ── Expected field-level error messages (from UIAutomator dump) ───────────────
${ERROR_EMPTY_USERNAME}     Username is required
${ERROR_EMPTY_PASSWORD}     Enter Password


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

TC011 - Login With Valid Credentials Navigates To Products Screen
    [Documentation]    End-to-end happy path: valid credentials → Products catalog.
    ...
    ...                NOTE: SauceLabs Demo App v2.2.0 returns to the Products screen
    ...                after login. There is no separate Home screen.
    ...
    ...                PASS CRITERIA:
    ...                    - Credentials accepted without error
    ...                    - Products catalog screen is displayed after login
    [Tags]    TC011    regression    login    happy-path
    Login As    ${VALID_USERNAME}    ${VALID_PASSWORD}
    Verify Products Screen Is Loaded
    Log    TC011 PASSED: Valid login shows the Products screen.    level=INFO

TC012 - Login With Empty Username Shows Validation Error
    [Documentation]    Submits the form with an empty username field and a valid password.
    ...                Verifies the app shows the field-level required error.
    ...
    ...                PASS CRITERIA:
    ...                    - Username error message appears: "${ERROR_EMPTY_USERNAME}"
    ...                    - User stays on the Login screen
    [Tags]    TC012    regression    login    negative    validation
    Clear Username Field
    Enter Password    ${VALID_PASSWORD}
    Tap Login Button
    Wait Until Element Is Visible    ${USERNAME_ERROR_MESSAGE}    timeout=${TIMEOUT}
    ${msg}=    Get Text    ${USERNAME_ERROR_MESSAGE}
    Should Be Equal    ${msg}    ${ERROR_EMPTY_USERNAME}
    Verify Login Page Is Loaded
    Log    TC012 PASSED: Empty username shows required error: '${msg}'.    level=INFO

TC013 - Login With Empty Password Shows Validation Error
    [Documentation]    Submits the form with a valid username but empty password.
    ...                Verifies the app shows the field-level password required error.
    ...
    ...                PASS CRITERIA:
    ...                    - Password error message appears: "${ERROR_EMPTY_PASSWORD}"
    ...                    - User stays on the Login screen
    [Tags]    TC013    regression    login    negative    validation
    Enter Username    ${VALID_USERNAME}
    Clear Password Field
    Tap Login Button
    Wait Until Element Is Visible    ${PASSWORD_ERROR_MESSAGE}    timeout=${TIMEOUT}
    ${msg}=    Get Text    ${PASSWORD_ERROR_MESSAGE}
    Should Be Equal    ${msg}    ${ERROR_EMPTY_PASSWORD}
    Verify Login Page Is Loaded
    Log    TC013 PASSED: Empty password shows required error: '${msg}'.    level=INFO

TC014 - Login With Both Fields Empty Shows Username Validation Error First
    [Documentation]    Submits the form with both fields empty.
    ...                Verifies the app shows the username required error (checked first).
    ...
    ...                PASS CRITERIA:
    ...                    - Username error message appears
    ...                    - User stays on the Login screen
    [Tags]    TC014    regression    login    negative    validation
    Clear Username Field
    Clear Password Field
    Tap Login Button
    Wait Until Element Is Visible    ${USERNAME_ERROR_MESSAGE}    timeout=${TIMEOUT}
    Verify Login Page Is Loaded
    Log    TC014 PASSED: Both fields empty — username error appears.    level=INFO

TC015 - Login With Valid Credentials Then Logout Via Nav Drawer
    [Documentation]    Verifies the complete login → logout round trip via the
    ...                navigation drawer. After logout the Products screen must still
    ...                be visible and the "Log In" drawer item must be present.
    ...
    ...                PASS CRITERIA:
    ...                    - Successful login shows the Products screen
    ...                    - Logout via hamburger menu succeeds
    ...                    - "Log In" item is visible in the nav drawer after logout
    [Tags]    TC015    regression    login    logout    happy-path
    Login As    ${VALID_USERNAME}    ${VALID_PASSWORD}
    Verify Products Screen Is Loaded
    Logout Via Menu
    Verify Products Screen Is Loaded
    Open Navigation Menu
    Verify Login Menu Item Is Visible
    Close Navigation Menu
    Log    TC015 PASSED: Login → Logout round trip via nav drawer works.    level=INFO

TC016 - Login With Special Characters In Username Accepted By Field
    [Documentation]    Verifies the username field accepts RFC 5321-valid email addresses
    ...                containing special characters (plus-sign, dots, hyphens, sub-domains).
    ...
    ...                NOTE: SauceLabs Demo App accepts any non-empty credentials.
    ...                The test verifies the field does not reject the format — the app
    ...                should proceed past the login form without a format-validation error.
    ...
    ...                PASS CRITERIA:
    ...                    - Special-character username is accepted by the field
    ...                    - App processes the form (no format-validation error shown)
    [Tags]    TC016    regression    login    edge-case    special-characters
    Enter Username    ${SPECIAL_CHAR_USERNAME}
    Enter Password    ${VALID_PASSWORD}
    Tap Login Button
    # App accepts any credentials — if the Products screen appears, the field accepted the input.
    # If a format-validation error appeared, we'd still be on the Login page.
    Verify Products Screen Is Loaded
    Log    TC016 PASSED: Special-character username accepted — no format error.    level=INFO

TC017 - Login Credentials Are Accepted And Products Screen Is Shown
    [Documentation]    Verifies the login flow end-to-end: credentials accepted → Products.
    ...
    ...                NOTE: Renamed from TC017 (Login → Logout → Login screen) because
    ...                SauceLabs Demo App v2.2.0 returns to Products (not a Login screen)
    ...                after logout. The logout round-trip is covered by TC015.
    ...
    ...                PASS CRITERIA:
    ...                    - Login with valid credentials shows Products screen
    [Tags]    TC017    regression    login    happy-path
    Login As    ${VALID_USERNAME}    ${VALID_PASSWORD}
    Verify Products Screen Is Loaded
    Log    TC017 PASSED: Valid credentials accepted, Products screen shown.    level=INFO

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

TC019 - Username Field Retains Value After Validation Error
    [Documentation]    After a validation error (empty password submitted), verifies that
    ...                the username field still contains the text the user typed.
    ...                This is a UX requirement — users should not have to retype their
    ...                email after correcting a password.
    ...
    ...                PASS CRITERIA:
    ...                    - Username entered, password left empty
    ...                    - Password validation error appears
    ...                    - Username input field still contains the original value
    [Tags]    TC019    regression    login    ux    field-persistence
    Enter Username    ${VALID_USERNAME}
    Clear Password Field
    Tap Login Button
    Wait Until Element Is Visible    ${PASSWORD_ERROR_MESSAGE}    timeout=${TIMEOUT}
    ${username_after_error}=    Get Text    ${USERNAME_FIELD}
    Should Be Equal    ${username_after_error}    ${VALID_USERNAME}
    ...    msg=Username field was cleared after validation error. Expected: '${VALID_USERNAME}' | Got: '${username_after_error}'
    Log    TC019 PASSED: Username is retained after password validation error.    level=INFO


*** Keywords ***
Return To Login Screen
    [Documentation]    Teardown helper — ensures the next test starts on the Login screen.
    ...
    ...                SauceLabs Demo App flow:
    ...                    1. If already on the Login screen → done.
    ...                    2. If on the Products screen and authenticated → logout via nav drawer,
    ...                       then navigate back to Login via hamburger menu.
    ...                    3. If on the Products screen, unauthenticated → navigate to Login via menu.
    ...                    4. If somewhere else → navigate back and retry.
    # Already on the login screen — nothing to do.
    ${on_login}=    Run Keyword And Return Status
    ...    Element Should Be Visible    ${LOGIN_PAGE_INDICATOR}
    Return From Keyword If    ${on_login}
    # Navigate back to Products if we're on a sub-screen.
    Run Keyword And Ignore Error    Navigate Back
    # If authenticated, log out first.
    ${on_products}=    Run Keyword And Return Status
    ...    Wait Until Element Is Visible    ${PRODUCTS_SCREEN_INDICATOR}    timeout=5s
    Run Keyword If    not ${on_products}
    ...    Log    Warning: Could not reach Products screen in teardown.    level=WARN
    Return From Keyword If    not ${on_products}
    # Check authentication state via nav drawer.
    Open Navigation Menu
    ${authenticated}=    Run Keyword And Return Status
    ...    Element Should Be Visible    ${LOGOUT_MENU_ITEM}
    Run Keyword If    ${authenticated}    Tap Logout Menu Item
    Run Keyword If    ${authenticated}    Confirm Logout
    Run Keyword If    not ${authenticated}    Close Navigation Menu
    # Now navigate to Login via menu.
    Open Navigation Menu
    ${login_item}=    Run Keyword And Return Status
    ...    Element Should Be Visible    ${LOGIN_MENU_ITEM}
    Run Keyword If    ${login_item}    Tap Login Menu Item
    ...    ELSE    Close Navigation Menu
    ${on_login_now}=    Run Keyword And Return Status
    ...    Wait Until Element Is Visible    ${LOGIN_PAGE_INDICATOR}    timeout=10s
    Run Keyword If    not ${on_login_now}
    ...    Log    Warning: Could not navigate back to Login screen for next test.    level=WARN
