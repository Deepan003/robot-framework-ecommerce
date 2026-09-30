*** Settings ***
Library     SeleniumLibrary
Library     Collections
Resource    ../common.resource

*** Variables ***
${SEARCH_INPUT}         id:search_product
${SEARCH_BUTTON}        id:submit_search
${RESULTS_HEADING}      xpath://h2[contains(text(),'Searched Products')]
${PRODUCT_NAMES}        css:.features_items .productinfo p
${FIRST_ADD_TO_CART}    css:.features_items .product-image-wrapper .add-to-cart
${VIEW_CART_LINK}       css:#cartModal .modal-body a[href="/view_cart"]

*** Keywords ***
Go To Products Page
    Go To    ${BASE_URL}/products

Search For Product
    [Arguments]    ${term}
    Wait Until Element Is Visible    ${SEARCH_INPUT}    timeout=${TIMEOUT}
    Input Text      ${SEARCH_INPUT}    ${term}
    Click Element Safely    ${SEARCH_BUTTON}

Searched Products Heading Should Be Visible
    Wait Until Element Is Visible    ${RESULTS_HEADING}    timeout=${TIMEOUT}

Get Product Result Names
    @{elements}=    Get WebElements    ${PRODUCT_NAMES}
    @{names}=    Create List
    FOR    ${element}    IN    @{elements}
        ${raw_text}=    Get Text    ${element}
        # The search-results markup for a handful of product names contains a
        # double space (e.g. "Sleeveless  Dress") that the main /products grid
        # doesn't have. Collapsing repeated whitespace here means a later exact
        # "does the cart contain this name" check isn't tripped up by that.
        ${text}=    Evaluate    ' '.join("""${raw_text}""".split())
        Append To List    ${names}    ${text}
    END
    RETURN    ${names}

Add First Result To Cart And Go To Cart Page
    Click Element Safely    ${FIRST_ADD_TO_CART}
    Click Element Safely    ${VIEW_CART_LINK}
