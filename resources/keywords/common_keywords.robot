*** Settings ***
Documentation    Common, reusable keywords used across all test suites.
...              These wrap AppiumLibrary calls to add logging, retry logic,
...              and screenshot support so individual tests stay readable.
Library          AppiumLibrary
Library          OperatingSystem
Library          Collections
Library          String
Library          DateTime
Library          yaml    WITH NAME    YAML
Resource         ../variables/common_variables.robot


*** Keywords ***
# ─────────────────────────────────────────────────────────────────────────────
# Session Management
# ─────────────────────────────────────────────────────────────────────────────

Open Mobile Application
    [Documentation]    Opens the mobile app under test.
    ...                Reads capabilities from the YAML config file that matches
    ...                the ${PLATFORM} variable (android or ios).
    ...
    ...                Example:
    ...                    Open Mobile Application
    ...                    # No arguments needed — platform is set via ${PLATFORM}
    ${config_file}=    Run Keyword If    '${PLATFORM}' == 'ios'
    ...                    Set Variable    ${IOS_CONFIG_FILE}
    ...                    ELSE            Set Variable    ${ANDROID_CONFIG_FILE}
    Log    Loading capabilities from: ${config_file}    level=INFO
    ${raw}=            Get File    ${config_file}
    ${config}=         YAML.Safe Load    ${raw}
    ${caps}=           Get From Dictionary    ${config}    capabilities
    ${server_block}=   Get From Dictionary    ${config}    appium_server
    ${server_url}=     Get From Dictionary    ${server_block}    url
    # AppiumLibrary.Open Application accepts keyword arguments matching capability names.
    # We unpack the dict and pass each capability individually.
    Open Application    ${server_url}    &{caps}
    Log    Application opened on platform: ${PLATFORM}    level=INFO
    Wait For App To Load

Close Mobile Application
    [Documentation]    Closes the mobile app and ends the Appium session cleanly.
    ...                Always call this in Suite Teardown so the port is released.
    Run Keyword And Ignore Error    Take Screenshot With Timestamp
    Close Application
    Log    Application session closed.    level=INFO

# ─────────────────────────────────────────────────────────────────────────────
# Screenshot Helpers
# ─────────────────────────────────────────────────────────────────────────────

Take Screenshot With Timestamp
    [Documentation]    Captures a screenshot and saves it with a timestamp filename.
    ...                Screenshots appear in the Robot Framework HTML report automatically.
    ...
    ...                Call this in Test Setup and Test Teardown for every test case so
    ...                you have a before/after visual record.
    ${timestamp}=      Get Current Date    result_format=%Y%m%d_%H%M%S
    ${filename}=       Set Variable    screenshot_${timestamp}
    Capture Page Screenshot    ${filename}.png
    Log    Screenshot saved: ${filename}.png    level=INFO

# ─────────────────────────────────────────────────────────────────────────────
# Element Interaction Helpers
# ─────────────────────────────────────────────────────────────────────────────

Wait And Click Element
    [Documentation]    Waits for the element to be visible then taps/clicks it.
    ...                Uses the global ${TIMEOUT} and ${RETRY_INTERVAL} variables.
    ...
    ...                Arguments:
    ...                    locator    — any AppiumLibrary locator string
    ...                               e.g. "accessibility_id=Login Button"
    ...
    ...                Example:
    ...                    Wait And Click Element    accessibility_id=Submit
    [Arguments]    ${locator}
    Wait Until Element Is Visible    ${locator}    timeout=${TIMEOUT}    error=Element not visible after ${TIMEOUT}: ${locator}
    Click Element    ${locator}
    Log    Clicked element: ${locator}    level=DEBUG

Wait And Input Text
    [Documentation]    Waits for the input field to appear, clears any existing text,
    ...                then types the given text. Works on both Android and iOS.
    ...
    ...                Arguments:
    ...                    locator    — AppiumLibrary locator for the input field
    ...                    text       — the text to type
    ...
    ...                Example:
    ...                    Wait And Input Text    accessibility_id=Username Input    john@example.com
    [Arguments]    ${locator}    ${text}
    Wait Until Element Is Visible    ${locator}    timeout=${TIMEOUT}    error=Input field not visible after ${TIMEOUT}: ${locator}
    Clear Text    ${locator}
    Input Text    ${locator}    ${text}
    Log    Typed text into: ${locator}    level=DEBUG

Tap Element At Coordinates
    [Documentation]    Taps the screen at the given x,y coordinates.
    ...                Use this only when no accessibility_id or xpath locator is available.
    ...
    ...                Arguments:
    ...                    x    — horizontal position in pixels
    ...                    y    — vertical position in pixels
    [Arguments]    ${x}    ${y}
    Tap    ${x}    ${y}
    Log    Tapped at coordinates: (${x}, ${y})    level=DEBUG

# ─────────────────────────────────────────────────────────────────────────────
# Scroll / Swipe Helpers
# ─────────────────────────────────────────────────────────────────────────────

Swipe Screen Up
    [Documentation]    Scrolls the screen upward (reveals content below).
    ...                Uses a center-of-screen swipe gesture.
    ${size}=           Get Window Size
    ${width}=          Get From Dictionary    ${size}    width
    ${height}=         Get From Dictionary    ${size}    height
    ${center_x}=       Evaluate    int(${width} / 2)
    ${start_y}=        Evaluate    int(${height} * 0.75)
    ${end_y}=          Evaluate    int(${height} * 0.25)
    Swipe    ${center_x}    ${start_y}    ${center_x}    ${end_y}    duration=800
    Log    Swiped up    level=DEBUG

Swipe Screen Down
    [Documentation]    Scrolls the screen downward (reveals content above / pull to refresh).
    ${size}=           Get Window Size
    ${width}=          Get From Dictionary    ${size}    width
    ${height}=         Get From Dictionary    ${size}    height
    ${center_x}=       Evaluate    int(${width} / 2)
    ${start_y}=        Evaluate    int(${height} * 0.25)
    ${end_y}=          Evaluate    int(${height} * 0.75)
    Swipe    ${center_x}    ${start_y}    ${center_x}    ${end_y}    duration=800
    Log    Swiped down    level=DEBUG

Swipe Left On Element
    [Documentation]    Swipes left across the given element (e.g., to delete a list item).
    ...
    ...                Arguments:
    ...                    locator    — AppiumLibrary locator for the element to swipe on
    [Arguments]    ${locator}
    ${location}=    Get Element Location    ${locator}
    ${size}=        Get Element Size    ${locator}
    ${start_x}=     Evaluate    int(${location}[x] + ${size}[width] * 0.8)
    ${end_x}=       Evaluate    int(${location}[x] + ${size}[width] * 0.1)
    ${center_y}=    Evaluate    int(${location}[y] + ${size}[height] / 2)
    Swipe    ${start_x}    ${center_y}    ${end_x}    ${center_y}    duration=600

# ─────────────────────────────────────────────────────────────────────────────
# Assertion Helpers
# ─────────────────────────────────────────────────────────────────────────────

Element Text Should Be
    [Documentation]    Asserts that the given element contains exactly the expected text.
    ...                Provides a clear failure message showing both actual and expected text.
    ...
    ...                Arguments:
    ...                    locator          — AppiumLibrary locator for the element
    ...                    expected_text    — the exact text you expect the element to show
    ...
    ...                Example:
    ...                    Element Text Should Be    accessibility_id=Welcome Message    Hello, Test User!
    [Arguments]    ${locator}    ${expected_text}
    Wait Until Element Is Visible    ${locator}    timeout=${TIMEOUT}
    ${actual_text}=    Get Text    ${locator}
    Should Be Equal    ${actual_text}    ${expected_text}
    ...    msg=Text mismatch on element '${locator}'. Expected: '${expected_text}' | Actual: '${actual_text}'

Element Should Contain Text
    [Documentation]    Asserts that the element's text contains the given substring.
    ...
    ...                Arguments:
    ...                    locator    — AppiumLibrary locator
    ...                    substring  — text fragment that should appear inside the element
    [Arguments]    ${locator}    ${substring}
    Wait Until Element Is Visible    ${locator}    timeout=${TIMEOUT}
    ${actual_text}=    Get Text    ${locator}
    Should Contain    ${actual_text}    ${substring}
    ...    msg=Element '${locator}' does not contain '${substring}'. Actual text: '${actual_text}'

# ─────────────────────────────────────────────────────────────────────────────
# Keyboard Helpers
# ─────────────────────────────────────────────────────────────────────────────

Hide Keyboard If Visible
    [Documentation]    Dismisses the on-screen keyboard if it is currently displayed.
    ...                Safe to call even when the keyboard is not visible — it will not fail.
    ...                Uses platform-appropriate method (Back key on Android, Done on iOS).
    ${is_keyboard_shown}=    Run Keyword And Return Status    Hide Keyboard
    Run Keyword If    ${is_keyboard_shown}    Log    Keyboard dismissed.    level=DEBUG
    ...    ELSE    Log    Keyboard was not visible — nothing to dismiss.    level=DEBUG

# ─────────────────────────────────────────────────────────────────────────────
# Waiting Helpers
# ─────────────────────────────────────────────────────────────────────────────

Wait For App To Load
    [Documentation]    Pauses until the app finishes its launch animation / splash screen.
    ...                Checks every ${RETRY_INTERVAL} until an element is found OR
    ...                ${APP_LOAD_TIMEOUT} is exceeded.
    ...
    ...                Adjust ${APP_LOAD_TIMEOUT} in common_variables.robot if your app
    ...                has a particularly long loading screen.
    Log    Waiting up to ${APP_LOAD_TIMEOUT} for app to load...    level=INFO
    Sleep    2s    reason=Allow app splash screen to start rendering
    Log    App load wait complete.    level=INFO

Wait Until Element Disappears
    [Documentation]    Waits until the given element is no longer visible on screen.
    ...                Useful for waiting for loading spinners or progress bars to finish.
    ...
    ...                Arguments:
    ...                    locator    — AppiumLibrary locator for the element
    ...                    timeout    — how long to wait (default: ${TIMEOUT})
    [Arguments]    ${locator}    ${timeout}=${TIMEOUT}
    Wait Until Element Is Not Visible    ${locator}    timeout=${timeout}
    ...    error=Element '${locator}' is still visible after ${timeout}
    Log    Element disappeared: ${locator}    level=DEBUG
