*** Settings ***
Documentation    Page Object for the Navigation Drawer (hamburger menu ☰).
...
...              This file encapsulates ALL interactions with the app's slide-out
...              navigation drawer.  Tests should never reference raw locators —
...              call these keywords instead.
...
...              FLOW OVERVIEW:
...              The app always opens to the Products screen (unauthenticated).
...              To reach the Login screen, the user must open the drawer and tap
...              the "Log In" menu item.  After login the drawer shows "Log Out".
...
...              LOCATORS are defined in resources/variables/common_variables.robot.
Library          AppiumLibrary
Resource         base_page.robot
Resource         ../variables/common_variables.robot
Resource         ../keywords/common_keywords.robot


*** Keywords ***
# ─────────────────────────────────────────────────────────────────────────────
# Menu Open / Close
# ─────────────────────────────────────────────────────────────────────────────

Open Navigation Menu
    [Documentation]    Opens the navigation drawer by tapping the hamburger menu (☰) button.
    ...                Waits for the button to be visible before tapping.
    ...
    ...                Example:
    ...                    Open Navigation Menu
    ...                    # navigation drawer is now visible
    Wait And Click Element    ${HAMBURGER_MENU}
    Log    Navigation drawer opened.    level=INFO

Close Navigation Menu
    [Documentation]    Closes the navigation drawer by pressing Back (Android) or
    ...                swiping left (iOS).  Safe to call if the drawer is already closed.
    ...
    ...                Example:
    ...                    Close Navigation Menu
    Navigate Back
    Log    Navigation drawer closed.    level=INFO

# ─────────────────────────────────────────────────────────────────────────────
# Menu Item Taps
# ─────────────────────────────────────────────────────────────────────────────

Tap Login Menu Item
    [Documentation]    Taps the "Log In" item inside an already-open navigation drawer.
    ...                This navigates the user to the Login screen.
    ...
    ...                Prerequisite: call Open Navigation Menu first.
    ...
    ...                Example:
    ...                    Open Navigation Menu
    ...                    Tap Login Menu Item
    Wait And Click Element    ${LOGIN_MENU_ITEM}
    Log    Tapped Login menu item — navigating to Login screen.    level=INFO

Tap Logout Menu Item
    [Documentation]    Taps the "Log Out" item inside an already-open navigation drawer.
    ...                This triggers the logout confirmation dialog.
    ...
    ...                Prerequisite: call Open Navigation Menu first.
    ...
    ...                Example:
    ...                    Open Navigation Menu
    ...                    Tap Logout Menu Item
    Wait And Click Element    ${LOGOUT_MENU_ITEM}
    Log    Tapped Logout menu item — confirmation dialog should appear.    level=INFO

Confirm Logout
    [Documentation]    Confirms the logout action by tapping the "LOGOUT" button
    ...                inside the confirmation dialog.
    ...
    ...                Example:
    ...                    Confirm Logout
    Wait And Click Element    ${LOGOUT_CONFIRM_BUTTON}
    Log    Logout confirmed in dialog.    level=INFO

# ─────────────────────────────────────────────────────────────────────────────
# Compound Flows
# ─────────────────────────────────────────────────────────────────────────────

Navigate To Login Via Menu
    [Documentation]    Opens the navigation drawer and taps the Login menu item.
    ...                One-step shortcut to reach the Login screen from anywhere
    ...                the Products screen is visible.
    ...
    ...                After this keyword the app is on the Login screen.
    ...
    ...                Example:
    ...                    Navigate To Login Via Menu
    ...                    # user is now on the Login screen
    Open Navigation Menu
    Tap Login Menu Item
    Log    Navigated to Login screen via hamburger menu.    level=INFO

Logout Via Menu
    [Documentation]    Performs a full logout via the navigation drawer:
    ...                opens menu → taps Log Out → confirms in dialog.
    ...
    ...                After this keyword the user is unauthenticated.
    ...                The Products screen remains visible; the drawer now shows
    ...                the "Log In" item instead of "Log Out".
    ...
    ...                Example:
    ...                    Logout Via Menu
    ...                    # user is unauthenticated; Products screen is still shown
    Open Navigation Menu
    Tap Logout Menu Item
    Confirm Logout
    Log    Logged out successfully via navigation menu.    level=INFO

# ─────────────────────────────────────────────────────────────────────────────
# Assertions
# ─────────────────────────────────────────────────────────────────────────────

Verify Login Menu Item Is Visible
    [Documentation]    Asserts that the "Log In" item is visible in an open navigation drawer.
    ...                A visible "Log In" item confirms the user is NOT authenticated.
    ...
    ...                Example:
    ...                    Open Navigation Menu
    ...                    Verify Login Menu Item Is Visible
    Wait Until Element Is Visible    ${LOGIN_MENU_ITEM}    timeout=${TIMEOUT}
    ...    error=Login menu item not found after ${TIMEOUT}. The user may still be authenticated or the drawer is not open.
    Log    Login menu item is visible — user is unauthenticated.    level=INFO

Verify Logout Menu Item Is Visible
    [Documentation]    Asserts that the "Log Out" item is visible in an open navigation drawer.
    ...                A visible "Log Out" item confirms the user IS authenticated.
    ...
    ...                Example:
    ...                    Open Navigation Menu
    ...                    Verify Logout Menu Item Is Visible
    Wait Until Element Is Visible    ${LOGOUT_MENU_ITEM}    timeout=${TIMEOUT}
    ...    error=Logout menu item not found after ${TIMEOUT}. The user may not be authenticated or the drawer is not open.
    Log    Logout menu item is visible — user is authenticated.    level=INFO

# ─────────────────────────────────────────────────────────────────────────────
# Teardown Helper
# ─────────────────────────────────────────────────────────────────────────────

Return To Products Screen Unauthenticated
    [Documentation]    Teardown helper that resets the app to the initial state:
    ...                Products screen visible and user NOT authenticated.
    ...
    ...                Handles all possible post-test states:
    ...                    - On Login screen     → Navigate Back to Products
    ...                    - On Products, logged in  → Logout Via Menu
    ...                    - On Products, logged out → Already in correct state
    ...                    - Drawer open, any auth   → Close drawer, then handle auth
    ...
    ...                Safe to call at the end of any test that uses the nav-drawer flow.
    # If on the Login screen, go back to the Products screen first.
    ${on_login}=    Run Keyword And Return Status
    ...    Element Should Be Visible    ${LOGIN_PAGE_INDICATOR}
    Run Keyword If    ${on_login}    Navigate Back
    # Wait to land on Products screen.
    ${on_products}=    Run Keyword And Return Status
    ...    Wait Until Element Is Visible    ${PRODUCTS_SCREEN_INDICATOR}    timeout=10s
    Run Keyword If    not ${on_products}
    ...    Log    Warning: Could not navigate back to Products screen for teardown.    level=WARN
    Return From Keyword If    not ${on_products}
    # Open the menu to check authentication state.
    Open Navigation Menu
    ${authenticated}=    Run Keyword And Return Status
    ...    Element Should Be Visible    ${LOGOUT_MENU_ITEM}
    Run Keyword If    ${authenticated}    Tap Logout Menu Item
    Run Keyword If    ${authenticated}    Confirm Logout
    Run Keyword If    not ${authenticated}    Navigate Back
    Log    Teardown complete: Products screen, unauthenticated.    level=INFO
