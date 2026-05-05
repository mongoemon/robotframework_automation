*** Settings ***
Documentation    Base page object that all page-specific resource files inherit from.
...
...              PURPOSE:
...              This file defines generic navigation actions and a template for the
...              "Verify Page Is Displayed" pattern used consistently across all pages.
...              Every page object (login_page.robot, home_page.robot, etc.) should
...              Resource this file and implement their own "Verify ... Is Loaded" keyword
...              by calling "Verify Page Is Displayed" with their unique page indicator.
...
...              USAGE:
...              Resource    resources/pages/base_page.robot
Library          AppiumLibrary
Resource         ../keywords/common_keywords.robot
Resource         ../keywords/appium_keywords.robot
Resource         ../variables/common_variables.robot


*** Keywords ***
# ─────────────────────────────────────────────────────────────────────────────
# Navigation
# ─────────────────────────────────────────────────────────────────────────────

Navigate Back
    [Documentation]    Navigates back to the previous screen.
    ...
    ...                On Android this presses the hardware/software Back button.
    ...                On iOS this looks for a "Back" navigation bar button and taps it.
    ...
    ...                Use this instead of directly pressing Back so tests work on both platforms.
    ...
    ...                Example:
    ...                    Navigate Back    # go back from current screen
    ${platform}=    Get Current Platform
    Run Keyword If    '${platform}' == 'android'
    ...    Press Keycode    4
    ...    ELSE IF    '${platform}' == 'ios'
    ...    iOS Navigate Back

iOS Navigate Back
    [Documentation]    iOS-specific back navigation.
    ...                Tries the navigation bar "Back" button first; falls back to a swipe-from-left gesture.
    ${back_visible}=    Run Keyword And Return Status
    ...    Element Should Be Visible    xpath=//XCUIElementTypeButton[@name="Back"]
    Run Keyword If    ${back_visible}
    ...    Click Element    xpath=//XCUIElementTypeButton[@name="Back"]
    ...    ELSE    Swipe From Left Edge

Swipe From Left Edge
    [Documentation]    Performs an iOS "swipe from left edge" gesture to go back.
    ...                This is the interactive pop gesture used on iOS navigation controllers.
    ${size}=      Get Window Size
    ${height}=    Get From Dictionary    ${size}    height
    ${center_y}=  Evaluate    int(${height} / 2)
    Swipe    0    ${center_y}    200    ${center_y}    duration=300

# ─────────────────────────────────────────────────────────────────────────────
# Page Verification Template
# ─────────────────────────────────────────────────────────────────────────────

Verify Page Is Displayed
    [Documentation]    Template keyword that verifies the current screen is the expected page.
    ...                Call this from your page-specific "Verify ... Is Loaded" keyword,
    ...                passing in the locator of a unique element that only exists on that page.
    ...
    ...                Arguments:
    ...                    page_indicator    — AppiumLibrary locator for the unique page element
    ...                    page_name         — human-readable name used in log messages
    ...
    ...                Example (inside login_page.robot):
    ...                    Verify Login Page Is Loaded
    ...                        Verify Page Is Displayed    ${LOGIN_PAGE_INDICATOR}    Login Page
    [Arguments]    ${page_indicator}    ${page_name}
    ${status}=    Run Keyword And Return Status
    ...    Wait Until Element Is Visible    ${page_indicator}    timeout=${TIMEOUT}
    Run Keyword If    not ${status}    Take Screenshot With Timestamp
    Should Be True    ${status}
    ...    Expected to be on ${page_name} but the page indicator element was not found. Locator: '${page_indicator}'. Check your locators or app state.
    Log    Confirmed: ${page_name} is displayed.    level=INFO

# ─────────────────────────────────────────────────────────────────────────────
# Loading State Helpers
# ─────────────────────────────────────────────────────────────────────────────

Wait For Loading Indicator To Disappear
    [Documentation]    Waits for a progress spinner / loading indicator to disappear
    ...                before continuing with the test.
    ...                If the indicator is not present, this keyword does nothing.
    ...
    ...                Arguments:
    ...                    loading_locator    — locator for the loading spinner element
    ...                    timeout            — max wait time (default: ${TIMEOUT})
    ...
    ...                Example:
    ...                    Wait For Loading Indicator To Disappear    accessibility_id=Loading Spinner
    [Arguments]    ${loading_locator}    ${timeout}=${TIMEOUT}
    ${is_loading}=    Run Keyword And Return Status    Element Should Be Visible    ${loading_locator}
    Return From Keyword If    not ${is_loading}
    Log    Loading indicator found — waiting for it to disappear.    level=INFO
    Wait Until Page Does Not Contain Element    ${loading_locator}    timeout=${timeout}
    ...    error=Loading indicator '${loading_locator}' did not disappear after ${timeout}

# ─────────────────────────────────────────────────────────────────────────────
# Scroll to Element (page-level helper)
# ─────────────────────────────────────────────────────────────────────────────

Scroll Down To Find Element
    [Documentation]    Scrolls the current page downward until the given element is visible.
    ...                Delegates to the platform-aware 'Scroll To Element' keyword.
    ...
    ...                Arguments:
    ...                    locator    — AppiumLibrary locator for the target element
    ...
    ...                Example:
    ...                    Scroll Down To Find Element    accessibility_id=Submit Button
    [Arguments]    ${locator}
    Scroll To Element    ${locator}    direction=down

Scroll Up To Find Element
    [Documentation]    Scrolls the current page upward until the given element is visible.
    ...
    ...                Arguments:
    ...                    locator    — AppiumLibrary locator for the target element
    [Arguments]    ${locator}
    Scroll To Element    ${locator}    direction=up
