*** Settings ***
Documentation    End-to-end shopping flow: login, search for a product, add the
...              first result to the cart, verify the cart contents, then log
...              out. Mirrors the business flow in the capstone brief:
...              Launch Browser -> Login -> Search -> Add To Cart -> Verify
...              Cart -> Logout -> Close Browser.
...
...              Uses Test Template (a suite-level setting) rather than a
...              per-test [Template]. With [Template] on a single test case,
...              Robot folds every data row into that one test and they end up
...              sharing a single browser/session — which silently carried a
...              cart item over between search terms the first time this was
...              tried. Test Template gives each row its own named test case,
...              so Test Setup/Teardown (a fresh browser and account) run once
...              per search term instead of once for all of them combined.
Resource         ../resources/pages/home_page.resource
Resource         ../resources/pages/login_page.resource
Resource         ../resources/pages/product_page.resource
Resource         ../resources/pages/cart_page.resource
Library          ../libraries/AccountApi.py

Suite Setup       Create Test Account
Suite Teardown    Delete Test Account
Test Setup        Open Application
Test Teardown     Close Application
Test Template     Login Search Add To Cart Verify And Logout
# One account is shared across all three tests below (Suite Setup, not Test
# Setup) to avoid three throwaway signups for what's otherwise identical
# coverage. Its cart is server-side and carries items over between tests as a
# result, which is fine here since each test only asserts the cart contains
# the item it just added, not that the cart contains only that item.

*** Test Cases ***           SEARCH TERM
Shop For A Top                Top
Shop For A Dress              Dress
Shop For A Tshirt             Tshirt

*** Keywords ***
Login Search Add To Cart Verify And Logout
    [Arguments]    ${search_term}
    ${email}=       Get Test Account Email
    ${password}=    Get Test Account Password
    ${name}=        Get Test Account Name

    Go To Login Page
    Login With Credentials    ${email}    ${password}
    User Should Be Logged In As    ${name}

    Go To Products Page
    Search For Product    ${search_term}
    Searched Products Heading Should Be Visible
    @{names}=    Get Product Result Names
    Should Not Be Empty    ${names}
    ${first_result}=    Get From List    ${names}    0

    Add First Result To Cart And Go To Cart Page
    Cart Should Contain Product    ${first_result}

    Go To Home Page
    Logout
