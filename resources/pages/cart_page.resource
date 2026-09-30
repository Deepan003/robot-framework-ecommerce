*** Settings ***
Library     SeleniumLibrary
Resource    ../common.resource

*** Variables ***
${CART_TABLE}    id:cart_info_table

*** Keywords ***
Cart Should Contain Product
    [Arguments]    ${product_name}
    Wait Until Element Is Visible    ${CART_TABLE}    timeout=${TIMEOUT}
    Element Should Contain    ${CART_TABLE}    ${product_name}

Get Cart Item Quantity
    [Arguments]    ${product_id}
    ${quantity}=    Get Text    css:#product-${product_id} .cart_quantity button
    RETURN    ${quantity}

Get Cart Item Total
    [Arguments]    ${product_id}
    ${total}=    Get Text    css:#product-${product_id} .cart_total_price
    RETURN    ${total}
