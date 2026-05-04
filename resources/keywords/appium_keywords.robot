*** Settings ***
Documentation    Low-level Appium helper keywords that abstract platform differences.
...              Use these when a behaviour differs between Android and iOS so that
...              higher-level keywords remain platform-agnostic.
Library          AppiumLibrary
Library          Collections
Resource         ../variables/common_variables.robot


*** Keywords ***
# ─────────────────────────────────────────────────────────────────────────────
# Platform Detection
# ─────────────────────────────────────────────────────────────────────────────

Get Current Platform
    [Documentation]    Returns the current platform string in lowercase.
    ...                Value comes from the ${PLATFORM} variable which is set either
    ...                in common_variables.robot or passed at runtime via --variable.
    ...
    ...                Returns: "android" or "ios"
    ...
    ...                Example:
    ...                    ${platform}=    Get Current Platform
    ...                    Log    Running on: ${platform}
    ${platform}=    Convert To Lower Case    ${PLATFORM}
    RETURN    ${platform}

Run Keyword For Platform
    [Documentation]    Executes a different keyword depending on the current platform.
    ...                This avoids IF/ELSE blocks cluttering your page objects.
    ...
    ...                Arguments:
    ...                    android_keyword    — name of the keyword to run on Android
    ...                    ios_keyword        — name of the keyword to run on iOS
    ...                    *args              — arguments passed to whichever keyword runs
    ...
    ...                Example:
    ...                    Run Keyword For Platform    Android Scroll Down    iOS Scroll Down
    ...                    Run Keyword For Platform    Android Tap    iOS Tap    accessibility_id=Foo
    [Arguments]    ${android_keyword}    ${ios_keyword}    @{args}
    ${platform}=    Get Current Platform
    Run Keyword If    '${platform}' == 'android'    Run Keyword    ${android_keyword}    @{args}
    ...    ELSE IF    '${platform}' == 'ios'         Run Keyword    ${ios_keyword}        @{args}
    ...    ELSE       Fail    Unknown platform: '${platform}'. Expected 'android' or 'ios'.

# ─────────────────────────────────────────────────────────────────────────────
# App Lifecycle
# ─────────────────────────────────────────────────────────────────────────────

Wait For App To Load
    [Documentation]    Waits for the application to finish loading by polling for the
    ...                expected launch indicator element.
    ...                Falls back to a simple sleep if no indicator element is defined.
    Log    Waiting for app to become ready...    level=INFO
    Sleep    2s    reason=Allow OS to hand control to the app process
    Log    App is ready.    level=INFO

Reset Application State
    [Documentation]    Resets the app to its initial state without closing the session.
    ...                On Android this sends the app to background and re-launches it.
    ...                On iOS it uses the XCUITest reset capability.
    ...
    ...                Use in Test Setup when noReset=true but you still want a clean state.
    ${platform}=    Get Current Platform
    Run Keyword If    '${platform}' == 'android'
    ...    Run Keywords
    ...        Background App    3
    ...    AND Launch Application
    ...    ELSE IF    '${platform}' == 'ios'
    ...    Run Keywords
    ...        Background App    3
    ...    AND Launch Application

Launch Application
    [Documentation]    Brings the app under test back to the foreground.
    ...                Equivalent to tapping the app icon from the home screen.
    Launch App

Background Application
    [Documentation]    Sends the app to the background for the given number of seconds,
    ...                then brings it back to the foreground automatically.
    ...
    ...                Arguments:
    ...                    seconds    — how long to leave the app in the background (default: 3)
    ...
    ...                Example:
    ...                    Background Application    5    # minimise for 5 seconds
    [Arguments]    ${seconds}=3
    Background App    ${seconds}
    Log    App was backgrounded for ${seconds} second(s).    level=INFO

# ─────────────────────────────────────────────────────────────────────────────
# Alert / Dialog Handling
# ─────────────────────────────────────────────────────────────────────────────

Accept Alert If Present
    [Documentation]    Accepts (taps OK / Allow) a native system alert dialog if one appears.
    ...                Safe to call when no alert is present — it will simply do nothing.
    ...                Handles both iOS permission dialogs and Android permission pop-ups.
    ...
    ...                Example:
    ...                    Accept Alert If Present    # call after triggering an action that may show a permission
    ${alert_visible}=    Run Keyword And Return Status    Alert Should Be Present
    Run Keyword If    ${alert_visible}
    ...    Run Keywords
    ...        Log    System alert detected — accepting it.    level=INFO
    ...    AND Accept Alert

Dismiss Alert If Present
    [Documentation]    Dismisses (taps Cancel / Deny) a native system alert if one appears.
    ...                Safe to call when no alert is present.
    ${alert_visible}=    Run Keyword And Return Status    Alert Should Be Present
    Run Keyword If    ${alert_visible}
    ...    Run Keywords
    ...        Log    System alert detected — dismissing it.    level=INFO
    ...    AND Dismiss Alert

Handle iOS Permission Dialog
    [Documentation]    Handles the iOS "Allow / Don't Allow" permission dialogs that appear
    ...                the first time an app requests camera, location, push notifications, etc.
    ...
    ...                Arguments:
    ...                    action    — "allow" or "deny" (default: "allow")
    ...
    ...                Example:
    ...                    Handle iOS Permission Dialog    allow
    [Arguments]    ${action}=allow
    ${platform}=    Get Current Platform
    Return From Keyword If    '${platform}' != 'ios'
    ${allow_btn_visible}=    Run Keyword And Return Status
    ...    Element Should Be Visible    xpath=//XCUIElementTypeButton[@name="Allow"]
    Run Keyword If    ${allow_btn_visible} and '${action}' == 'allow'
    ...    Click Element    xpath=//XCUIElementTypeButton[@name="Allow"]
    Run Keyword If    ${allow_btn_visible} and '${action}' == 'deny'
    ...    Click Element    xpath=//XCUIElementTypeButton[@name="Don't Allow"]

# ─────────────────────────────────────────────────────────────────────────────
# Device Information
# ─────────────────────────────────────────────────────────────────────────────

Get Device Screen Size
    [Documentation]    Returns a dictionary with 'width' and 'height' keys (in pixels).
    ...
    ...                Example:
    ...                    ${size}=    Get Device Screen Size
    ...                    Log    Width: ${size}[width]  Height: ${size}[height]
    ${size}=    Get Window Size
    Log    Screen size: ${size}[width] x ${size}[height]    level=INFO
    RETURN    ${size}

Log Device Information
    [Documentation]    Logs useful device/session information to the Robot Framework report.
    ...                Call once at the beginning of the suite for traceability.
    ${platform}=    Get Current Platform
    ${size}=        Get Window Size
    Log    Platform  : ${platform}                        level=INFO
    Log    Screen    : ${size}[width] x ${size}[height]   level=INFO

# ─────────────────────────────────────────────────────────────────────────────
# Scroll Helpers (platform-aware)
# ─────────────────────────────────────────────────────────────────────────────

Scroll To Element
    [Documentation]    Scrolls the screen until the given element becomes visible.
    ...                Uses UiScrollable on Android and a swipe loop on iOS.
    ...
    ...                Arguments:
    ...                    locator    — AppiumLibrary locator for the target element
    ...                    direction  — "up" or "down" (default: "down")
    [Arguments]    ${locator}    ${direction}=down
    ${platform}=    Get Current Platform
    Run Keyword If    '${platform}' == 'android'
    ...    Android Scroll To Element    ${locator}    ${direction}
    ...    ELSE IF    '${platform}' == 'ios'
    ...    iOS Scroll To Element    ${locator}    ${direction}

Android Scroll To Element
    [Documentation]    Android-specific: uses UIScrollable to scroll to an element by text.
    ...                Falls back to swipe loop if UIScrollable is not suitable.
    [Arguments]    ${locator}    ${direction}=down
    ${element_visible}=    Run Keyword And Return Status    Element Should Be Visible    ${locator}
    Return From Keyword If    ${element_visible}
    # Try UIScrollable scroll
    ${text}=    Run Keyword And Return Status    Get Text    ${locator}
    Swipe Until Element Is Visible    ${locator}    ${direction}

iOS Scroll To Element
    [Documentation]    iOS-specific: swipes until the element is visible.
    [Arguments]    ${locator}    ${direction}=down
    Swipe Until Element Is Visible    ${locator}    ${direction}

Swipe Until Element Is Visible
    [Documentation]    Swipes in the given direction until the locator is visible,
    ...                or the maximum number of swipes is reached.
    ...
    ...                Arguments:
    ...                    locator        — AppiumLibrary locator
    ...                    direction      — "up" or "down" (default: "down")
    ...                    max_swipes     — safety limit to avoid infinite loops (default: 10)
    [Arguments]    ${locator}    ${direction}=down    ${max_swipes}=10
    ${size}=      Get Window Size
    ${width}=     Get From Dictionary    ${size}    width
    ${height}=    Get From Dictionary    ${size}    height
    ${center_x}=  Evaluate    int(${width} / 2)
    ${start_y}=   Run Keyword If    '${direction}' == 'down'    Evaluate    int(${height} * 0.75)
    ...           ELSE    Evaluate    int(${height} * 0.25)
    ${end_y}=     Run Keyword If    '${direction}' == 'down'    Evaluate    int(${height} * 0.25)
    ...           ELSE    Evaluate    int(${height} * 0.75)
    FOR    ${i}    IN RANGE    ${max_swipes}
        ${found}=    Run Keyword And Return Status    Element Should Be Visible    ${locator}
        Exit For Loop If    ${found}
        Swipe    ${center_x}    ${start_y}    ${center_x}    ${end_y}    duration=600
        Sleep    0.5s
    END
    Element Should Be Visible    ${locator}
    ...    msg=Element '${locator}' not found after ${max_swipes} swipes in direction '${direction}'.
