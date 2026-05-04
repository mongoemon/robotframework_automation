*** Settings ***
Documentation    Smoke Test Suite — Products Catalog & Navigation Drawer
...
...              WHAT IS A SMOKE TEST?
...              Smoke tests are fast, high-level checks that verify the most critical
...              paths work at all. Run these after every build to catch showstopper bugs.
...              They should complete in under 5 minutes.
...
...              SOURCE: docs/test-cases.xlsx
...              These tests implement the HIGH PRIORITY test cases defined in the xlsx:
...
...              TC-AND-001 / TC-IOS-001 — Login via navigation drawer → Products screen
...              TC-AND-002 / TC-IOS-002 — Products list is not empty after login
...              TC-AND-005 / TC-IOS-005 — Logout returns the Login item to the menu
...
...              APP FLOW (differs from 01_login_smoke.robot):
...              The app launches to the Products screen (unauthenticated).
...              Login is reached by: hamburger menu (☰) → "Log In" menu item.
...              Logout is reached by: hamburger menu (☰) → "Log Out" → confirm dialog.
...
...              TEST DATA:
...              email: bod@example.com  /  password: 10203040
...              (standard demo credentials — see test_data/users.yaml → demo_user)
...
...              HOW TO RUN:
...              Android:  robot --variable PLATFORM:android --include smoke tests/smoke/02_products_smoke.robot
...              iOS:      robot --variable PLATFORM:ios     --include smoke tests/smoke/02_products_smoke.robot
...              By ID:    robot --variable PLATFORM:android --include TC-AND-001 tests/
Metadata         Version     1.0
Metadata         Platform    ${PLATFORM}
Metadata         Source      docs/test-cases.xlsx

# ── Library imports ────────────────────────────────────────────────────────────
Library          AppiumLibrary
Library          yaml    WITH NAME    YAML

# ── Resource imports ──────────────────────────────────────────────────────────
Resource         ../../resources/variables/common_variables.robot
Resource         ../../resources/keywords/common_keywords.robot
Resource         ../../resources/keywords/appium_keywords.robot
Resource         ../../resources/pages/login_page.robot
Resource         ../../resources/pages/navigation_page.robot
Resource         ../../resources/pages/products_page.robot

# ── Suite-level setup / teardown ──────────────────────────────────────────────
Suite Setup       Open Mobile Application
Suite Teardown    Close Mobile Application

# ── Test-level setup / teardown ───────────────────────────────────────────────
Test Setup        Take Screenshot With Timestamp

Test Teardown     Run Keywords
...               Take Screenshot With Timestamp
...               AND    Run Keyword If Test Failed    Log    TEST FAILED — screenshot saved above.    level=WARN
...               AND    Return To Products Screen Unauthenticated

# ── Default tags applied to every test in this file ───────────────────────────
Test Tags         smoke    login    products


*** Variables ***
# Credentials from test-cases.xlsx — standard SauceLabs Demo App test account.
${DEMO_EMAIL}        bod@example.com
${DEMO_PASSWORD}     10203040


*** Test Cases ***
TC-AND-001 / TC-IOS-001 - Login With Valid Credentials Navigates To Products Screen
    [Documentation]    Verifies the end-to-end login flow using the navigation drawer.
    ...
    ...                STEPS (from xlsx):
    ...                    1. Launch the app.
    ...                    2. Tap the hamburger menu (☰).
    ...                    3. Tap "Login Menu Item".
    ...                    4. Enter email: bod@example.com
    ...                    5. Enter password: 10203040
    ...                    6. Tap the login button.
    ...
    ...                PASS CRITERIA:
    ...                    - Products catalog screen is displayed after login.
    ...                    - Home page indicator (Products Screen) is visible.
    ...
    ...                FAILURE INVESTIGATION:
    ...                    1. Confirm ${HAMBURGER_MENU} accessibility_id matches the app.
    ...                    2. Confirm ${LOGIN_MENU_ITEM} accessibility_id is correct.
    ...                    3. Verify credentials are valid in the test environment.
    ...                    4. Check ${PRODUCTS_SCREEN_INDICATOR} locator.
    [Tags]    TC-AND-001    TC-IOS-001    smoke    login    happy-path
    Verify Products Screen Is Loaded
    Navigate To Login Via Menu
    Verify Login Page Is Loaded
    Enter Username    ${DEMO_EMAIL}
    Enter Password    ${DEMO_PASSWORD}
    Tap Login Button
    Verify Products Screen Is Loaded
    Log    TC-AND-001/TC-IOS-001 PASSED: Login via nav drawer showed Products screen.    level=INFO

TC-AND-002 / TC-IOS-002 - Products List Is Shown After Login
    [Documentation]    Verifies that after a successful login the Products catalog
    ...                contains at least one visible item.
    ...
    ...                STEPS (from xlsx):
    ...                    1. Launch the app.
    ...                    2. Navigate to Login screen via hamburger menu.
    ...                    3. Enter valid credentials (bod@example.com / 10203040).
    ...                    4. Tap the login button.
    ...                    5. Wait for the Products screen.
    ...                    6. Count visible product items.
    ...
    ...                PASS CRITERIA:
    ...                    - Product count is greater than 0.
    ...                    - At least one product title is visible.
    ...
    ...                FAILURE INVESTIGATION:
    ...                    1. Confirm login succeeded (check screenshot).
    ...                    2. Verify ${PRODUCT_ITEM} locator matches the product card element.
    ...                    3. Verify ${PRODUCT_TITLE} locator matches the title element.
    [Tags]    TC-AND-002    TC-IOS-002    smoke    products    content
    Verify Products Screen Is Loaded
    Navigate To Login Via Menu
    Verify Login Page Is Loaded
    Enter Username    ${DEMO_EMAIL}
    Enter Password    ${DEMO_PASSWORD}
    Tap Login Button
    Verify Products Screen Is Loaded
    Verify Products List Is Not Empty
    Log    TC-AND-002/TC-IOS-002 PASSED: Product list is not empty after login.    level=INFO

TC-AND-005 / TC-IOS-005 - Logout Returns Login Option To Menu
    [Documentation]    Verifies the complete login → logout round-trip.
    ...                After logout the navigation drawer must show the "Log In"
    ...                item again, confirming the user session was cleared.
    ...
    ...                STEPS (from xlsx):
    ...                    1. Log in with valid credentials.
    ...                    2. Wait for the Products screen.
    ...                    3. Tap the hamburger menu (☰).
    ...                    4. Tap "Logout Menu Item".
    ...                    5. Tap "LOGOUT" in the confirmation dialog.
    ...                    6. Wait for the Products screen.
    ...                    7. Tap the hamburger menu (☰) again.
    ...                    8. Verify "Login Menu Item" is visible.
    ...
    ...                PASS CRITERIA:
    ...                    - "Login Menu Item" is visible in the drawer after logout,
    ...                      confirming the user is no longer authenticated.
    ...
    ...                FAILURE INVESTIGATION:
    ...                    1. Verify ${LOGOUT_MENU_ITEM} locator is correct.
    ...                    2. Verify ${LOGOUT_CONFIRM_BUTTON} locator matches the dialog button.
    ...                    3. Check the screenshot taken after the confirmation tap.
    [Tags]    TC-AND-005    TC-IOS-005    smoke    logout    happy-path
    # Step 1-2: Login
    Verify Products Screen Is Loaded
    Navigate To Login Via Menu
    Verify Login Page Is Loaded
    Enter Username    ${DEMO_EMAIL}
    Enter Password    ${DEMO_PASSWORD}
    Tap Login Button
    Verify Products Screen Is Loaded
    # Steps 3-6: Logout via menu
    Open Navigation Menu
    Verify Logout Menu Item Is Visible
    Tap Logout Menu Item
    Confirm Logout
    Verify Products Screen Is Loaded
    # Steps 7-8: Verify Login item is back in the menu
    Open Navigation Menu
    Verify Login Menu Item Is Visible
    Close Navigation Menu
    Log    TC-AND-005/TC-IOS-005 PASSED: Login item visible in menu after logout.    level=INFO


