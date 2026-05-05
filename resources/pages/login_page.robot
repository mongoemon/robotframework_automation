*** Settings ***
Documentation    Page Object for the Login Screen.
...
...              This file encapsulates ALL interactions with the login screen.
...              Tests should never reference raw locators — they call these keywords instead.
...              This means if the app's UI changes, you only update locators in ONE place.
...
...              LOCATORS are defined in resources/variables/common_variables.robot.
...              Modify them there when you update your app's accessibility labels.
Library          AppiumLibrary
Resource         base_page.robot
Resource         ../variables/common_variables.robot
Resource         ../keywords/common_keywords.robot


*** Keywords ***
# ─────────────────────────────────────────────────────────────────────────────
# Page Verification
# ─────────────────────────────────────────────────────────────────────────────

Verify Login Page Is Loaded
    [Documentation]    Asserts that the Login screen is currently displayed.
    ...                Fails with a screenshot if the login page indicator is not found.
    ...
    ...                When to call:
    ...                    - At the start of every test case that begins on the login screen
    ...                    - After logout, to confirm the user was returned to login
    ...
    ...                Example:
    ...                    Verify Login Page Is Loaded
    Verify Page Is Displayed    ${LOGIN_PAGE_INDICATOR}    Login Page

# ─────────────────────────────────────────────────────────────────────────────
# Individual Field Interactions
# ─────────────────────────────────────────────────────────────────────────────

Enter Username
    [Documentation]    Types the given username/email into the username input field.
    ...                Clears any previously entered text before typing.
    ...
    ...                Arguments:
    ...                    username    — the email or username string to enter
    ...
    ...                Example:
    ...                    Enter Username    testuser@example.com
    [Arguments]    ${username}
    Wait And Input Text    ${USERNAME_FIELD}    ${username}
    Log    Entered username: ${username}    level=INFO

Enter Password
    [Documentation]    Types the given password into the password input field.
    ...                The text is masked in the app UI but logged at DEBUG level.
    ...                To prevent password leakage in logs, use a credential variable.
    ...
    ...                Arguments:
    ...                    password    — the password string to enter
    ...
    ...                Example:
    ...                    Enter Password    ${VALID_USER_PASSWORD}
    [Arguments]    ${password}
    Wait And Input Text    ${PASSWORD_FIELD}    ${password}
    Log    Password entered (value masked in report)    level=INFO

Clear Username Field
    [Documentation]    Clears the username input field without entering any text.
    ...                Useful for verifying empty-field validation.
    Wait Until Element Is Visible    ${USERNAME_FIELD}    timeout=${TIMEOUT}
    Clear Text    ${USERNAME_FIELD}
    Log    Username field cleared.    level=DEBUG

Clear Password Field
    [Documentation]    Clears the password input field without entering any text.
    Wait Until Element Is Visible    ${PASSWORD_FIELD}    timeout=${TIMEOUT}
    Clear Text    ${PASSWORD_FIELD}
    Log    Password field cleared.    level=DEBUG

# ─────────────────────────────────────────────────────────────────────────────
# Actions
# ─────────────────────────────────────────────────────────────────────────────

Tap Login Button
    [Documentation]    Taps the Login / Sign In button to submit the login form.
    ...                Waits for the button to be visible before tapping.
    ...
    ...                Example:
    ...                    Tap Login Button
    Wait And Click Element    ${LOGIN_BUTTON}
    Log    Login button tapped.    level=INFO

Tap Forgot Password Link
    [Documentation]    Taps the "Forgot Password?" link on the login screen.
    ...                Use in regression tests to verify the forgot password flow opens.
    Wait And Click Element    ${FORGOT_PASSWORD_LINK}
    Log    Forgot Password link tapped.    level=INFO

# ─────────────────────────────────────────────────────────────────────────────
# Compound Keyword (most tests should use this)
# ─────────────────────────────────────────────────────────────────────────────

Login As
    [Documentation]    Performs a complete login flow: enters username, enters password,
    ...                and taps the Login button. This is the primary keyword for logging in.
    ...
    ...                Arguments:
    ...                    username    — the email or username to log in with
    ...                    password    — the password to use
    ...
    ...                Example — using variables from test_data/users.yaml:
    ...                    Login As    ${VALID_USER}[username]    ${VALID_USER}[password]
    ...
    ...                Example — inline:
    ...                    Login As    admin@example.com    Secret123!
    [Arguments]    ${username}    ${password}
    Verify Login Page Is Loaded
    Enter Username    ${username}
    Enter Password    ${password}
    Tap Login Button
    Log    Login attempted for: ${username}    level=INFO

Login As Valid User
    [Documentation]    Convenience keyword that reads valid credentials from test_data/users.yaml
    ...                and performs a complete login.
    ...                Use this when a test just needs to be "logged in" and doesn't care about
    ...                the credentials themselves.
    ${raw}=             Get File    ${TEST_DATA_FILE}
    ${data}=            YAML.Safe Load    ${raw}
    ${user}=            Get From Dictionary    ${data}    valid_user
    ${username}=        Get From Dictionary    ${user}    username
    ${password}=        Get From Dictionary    ${user}    password
    Login As    ${username}    ${password}

# ─────────────────────────────────────────────────────────────────────────────
# Assertions
# ─────────────────────────────────────────────────────────────────────────────

Verify Error Message Is
    [Documentation]    Asserts that the login error message element shows the expected text.
    ...                Call this after a failed login attempt to verify the correct error
    ...                message is displayed to the user.
    ...
    ...                Arguments:
    ...                    expected_message    — the exact error text you expect
    ...
    ...                Example:
    ...                    Verify Error Message Is    Invalid credentials. Please try again.
    [Arguments]    ${expected_message}
    Wait Until Element Is Visible    ${LOGIN_ERROR_MESSAGE}    timeout=${TIMEOUT}
    ...    error=Login error message did not appear after ${TIMEOUT}. Expected: '${expected_message}'
    ${actual_message}=    Get Text    ${LOGIN_ERROR_MESSAGE}
    Should Be Equal    ${actual_message}    ${expected_message}
    ...    msg=Wrong error message. Expected: '${expected_message}' | Got: '${actual_message}'
    Log    Error message verified: '${actual_message}'    level=INFO

Verify Error Message Contains
    [Documentation]    Asserts that the login error message contains the given substring.
    ...                Less strict than 'Verify Error Message Is' — useful when the exact
    ...                wording may vary slightly between OS versions.
    ...
    ...                Arguments:
    ...                    expected_substring    — text fragment that must appear in the error
    [Arguments]    ${expected_substring}
    Wait Until Element Is Visible    ${LOGIN_ERROR_MESSAGE}    timeout=${TIMEOUT}
    ${actual_message}=    Get Text    ${LOGIN_ERROR_MESSAGE}
    Should Contain    ${actual_message}    ${expected_substring}
    ...    msg=Error message '${actual_message}' does not contain '${expected_substring}'

Verify No Error Message Is Displayed
    [Documentation]    Asserts that no error message is visible on the login screen.
    ...                Use after a successful login to confirm the error label is gone.
    ${error_visible}=    Run Keyword And Return Status
    ...    Element Should Be Visible    ${LOGIN_ERROR_MESSAGE}
    Should Not Be True    ${error_visible}
    ...    msg=An unexpected error message is displayed on the Login page.

Verify Login Button Is Displayed
    [Documentation]    Asserts that the Login button is visible on screen.
    ...                Use in smoke tests to confirm the login form rendered correctly.
    Element Should Be Visible    ${LOGIN_BUTTON}
    Log    Login button is visible.    level=INFO

Verify Username Field Is Empty
    [Documentation]    Asserts that the username input field contains no text.
    ${text}=    Get Text    ${USERNAME_FIELD}
    Should Be Empty    ${text}
    ...    msg=Username field is not empty. Current value: '${text}'
