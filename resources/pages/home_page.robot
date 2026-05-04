*** Settings ***
Documentation    Page Object for the Home Screen.
...
...              This file encapsulates ALL interactions with the home/dashboard screen
...              that the user lands on after a successful login.
...
...              Following the Page Object Model pattern:
...              - Tests call keywords from this file (NOT raw AppiumLibrary calls)
...              - Locators are centralised in common_variables.robot
...              - If the UI changes, update the locator in ONE place only
Library          AppiumLibrary
Resource         base_page.robot
Resource         ../variables/common_variables.robot
Resource         ../keywords/common_keywords.robot


*** Keywords ***
# ─────────────────────────────────────────────────────────────────────────────
# Page Verification
# ─────────────────────────────────────────────────────────────────────────────

Verify Home Page Is Loaded
    [Documentation]    Asserts that the Home screen is currently displayed.
    ...                Waits up to ${TIMEOUT} for the home screen indicator element.
    ...                Fails with a screenshot if the home screen is not found.
    ...
    ...                When to call:
    ...                    - Immediately after a successful login
    ...                    - After navigating back to the home screen from a sub-screen
    ...
    ...                Example:
    ...                    Verify Home Page Is Loaded
    Verify Page Is Displayed    ${HOME_PAGE_INDICATOR}    Home Page

# ─────────────────────────────────────────────────────────────────────────────
# Content Verification
# ─────────────────────────────────────────────────────────────────────────────

Get Welcome Message Text
    [Documentation]    Returns the text content of the welcome/greeting message element.
    ...                Use this to verify the personalised greeting shown after login.
    ...
    ...                Returns:
    ...                    The welcome message text string (e.g. "Hello, Test User!")
    ...
    ...                Example:
    ...                    ${greeting}=    Get Welcome Message Text
    ...                    Should Contain    ${greeting}    Test User
    Wait Until Element Is Visible    ${WELCOME_MESSAGE}    timeout=${TIMEOUT}
    ${text}=    Get Text    ${WELCOME_MESSAGE}
    Log    Welcome message text: '${text}'    level=INFO
    RETURN    ${text}

Verify Welcome Message Contains
    [Documentation]    Asserts that the welcome message contains the given name or substring.
    ...
    ...                Arguments:
    ...                    expected_name    — text that should appear in the welcome message
    ...
    ...                Example:
    ...                    Verify Welcome Message Contains    Test User
    [Arguments]    ${expected_name}
    ${greeting}=    Get Welcome Message Text
    Should Contain    ${greeting}    ${expected_name}
    ...    msg=Welcome message '${greeting}' does not contain the expected name '${expected_name}'
    Log    Welcome message contains '${expected_name}' — OK.    level=INFO

Verify Welcome Message Is
    [Documentation]    Asserts that the welcome message matches exactly the expected text.
    ...
    ...                Arguments:
    ...                    expected_text    — the full, exact welcome message string
    [Arguments]    ${expected_text}
    Element Text Should Be    ${WELCOME_MESSAGE}    ${expected_text}

# ─────────────────────────────────────────────────────────────────────────────
# Navigation Actions
# ─────────────────────────────────────────────────────────────────────────────

Tap Menu Button
    [Documentation]    Opens the navigation/hamburger menu by tapping the Menu button.
    ...                After calling this, use the navigation keywords to go to other sections.
    ...
    ...                Example:
    ...                    Tap Menu Button
    ...                    # navigation drawer / sidebar is now open
    Wait And Click Element    ${MENU_BUTTON}
    Log    Navigation menu opened.    level=INFO

Close Menu
    [Documentation]    Closes the navigation menu by swiping left or tapping outside it.
    ...                Safe to call even when the menu is already closed.
    ${platform}=    Get Current Platform
    Run Keyword If    '${platform}' == 'android'    Navigate Back
    ...    ELSE    Swipe Screen Down

# ─────────────────────────────────────────────────────────────────────────────
# Logout Flow
# ─────────────────────────────────────────────────────────────────────────────

Logout
    [Documentation]    Performs a complete logout flow from the Home screen.
    ...                Opens the menu, taps Logout, and waits to be returned to Login.
    ...
    ...                After this keyword completes, the Login screen should be displayed.
    ...                Verify with: Verify Login Page Is Loaded (from login_page.robot)
    ...
    ...                Example:
    ...                    Logout
    ...                    Verify Login Page Is Loaded
    Tap Menu Button
    Wait And Click Element    ${LOGOUT_BUTTON}
    Log    Logout tapped — waiting for Login screen.    level=INFO
    # Wait for the logout transition animation to complete
    Sleep    1s    reason=Allow logout animation to complete
    Log    Logout complete.    level=INFO

Logout And Verify Login Screen
    [Documentation]    Compound keyword: logs out and verifies the Login page is shown.
    ...                Use this as a single step in regression tests.
    Logout
    # Import login page here to avoid circular resource dependency
    Run Keyword    Verify Page Is Displayed    ${LOGIN_PAGE_INDICATOR}    Login Page
    Log    Successfully logged out and returned to Login screen.    level=INFO

# ─────────────────────────────────────────────────────────────────────────────
# Home Screen Content Helpers
# ─────────────────────────────────────────────────────────────────────────────

Scroll To Bottom Of Home Screen
    [Documentation]    Scrolls to the bottom of the home screen content.
    ...                Use when testing content that requires scrolling to be visible.
    Swipe Screen Up
    Swipe Screen Up
    Log    Scrolled to bottom of home screen.    level=DEBUG

Scroll To Top Of Home Screen
    [Documentation]    Scrolls back to the top of the home screen content.
    Swipe Screen Down
    Swipe Screen Down
    Log    Scrolled to top of home screen.    level=DEBUG

Verify Home Page Elements Are Present
    [Documentation]    Performs a quick sanity check that the key home page elements
    ...                are all visible. Use in smoke tests after login.
    ...
    ...                Verifies:
    ...                    - Home screen indicator
    ...                    - Welcome message
    ...                    - Menu button
    Element Should Be Visible    ${HOME_PAGE_INDICATOR}
    Element Should Be Visible    ${WELCOME_MESSAGE}
    Element Should Be Visible    ${MENU_BUTTON}
    Log    All home page elements are visible.    level=INFO
