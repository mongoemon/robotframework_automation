*** Settings ***
Documentation    Page Object for the Products Catalog Screen.
...
...              The Products screen is the landing screen of the app.  It is
...              visible in both authenticated and unauthenticated states.
...              After a successful login the catalog reflects the logged-in user.
...
...              Following the Page Object Model pattern:
...              - Tests call keywords from this file (NOT raw AppiumLibrary calls)
...              - Locators are centralised in common_variables.robot
...              - If the UI changes, update the locator in ONE place only
...
...              LOCATORS are defined in resources/variables/common_variables.robot.
Library          AppiumLibrary
Resource         base_page.robot
Resource         ../variables/common_variables.robot
Resource         ../keywords/common_keywords.robot


*** Keywords ***
# ─────────────────────────────────────────────────────────────────────────────
# Page Verification
# ─────────────────────────────────────────────────────────────────────────────

Verify Products Screen Is Loaded
    [Documentation]    Asserts that the Products catalog screen is currently displayed.
    ...                Waits up to ${TIMEOUT} for the screen indicator element.
    ...                Fails with a screenshot if the screen is not found.
    ...
    ...                When to call:
    ...                    - After app launch (first screen the user sees)
    ...                    - After a successful login
    ...                    - After confirming a logout (screen stays on Products)
    ...
    ...                Example:
    ...                    Verify Products Screen Is Loaded
    Verify Page Is Displayed    ${PRODUCTS_SCREEN_INDICATOR}    Products Screen

# ─────────────────────────────────────────────────────────────────────────────
# Content Verification
# ─────────────────────────────────────────────────────────────────────────────

Get Product Count
    [Documentation]    Returns the number of product items currently visible on screen
    ...                without scrolling.
    ...
    ...                Returns:
    ...                    Integer — count of visible product card elements.
    ...
    ...                Example:
    ...                    ${count}=    Get Product Count
    ...                    Should Be True    ${count} > 0
    ${elements}=    Get WebElements    ${PRODUCT_ITEM}
    ${count}=       Get Length    ${elements}
    Log    Visible product count: ${count}    level=INFO
    RETURN    ${count}

Verify Products List Is Not Empty
    [Documentation]    Asserts that at least one product item is visible on the screen
    ...                and that a product title element is present.
    ...
    ...                PASS CRITERIA:
    ...                    - At least one ${PRODUCT_ITEM} element is found
    ...                    - ${PRODUCT_TITLE} element is visible
    ...
    ...                FAILURE INVESTIGATION:
    ...                    1. Check the screenshot — is the catalog loading or empty?
    ...                    2. Verify ${PRODUCT_ITEM} locator in common_variables.robot
    ...                    3. Confirm login succeeded (catalog may differ when authenticated)
    ...
    ...                Example:
    ...                    Verify Products List Is Not Empty
    ${count}=    Get Product Count
    Should Be True    ${count} > 0
    ...    msg=Products list is empty. Expected at least 1 product item. Count: ${count}
    Element Should Be Visible    ${PRODUCT_TITLE}
    Log    Products list is not empty — ${count} product(s) visible.    level=INFO
