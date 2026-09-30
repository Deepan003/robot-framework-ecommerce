*** Settings ***
Library     SeleniumLibrary
Resource    ../common.resource

*** Variables ***
${EMAIL_INPUT}       css:input[data-qa="login-email"]
${PASSWORD_INPUT}    css:input[data-qa="login-password"]
${LOGIN_BUTTON}      css:button[data-qa="login-button"]
${LOGIN_ERROR}       css:form[action="/login"] p

*** Keywords ***
Login With Credentials
    [Arguments]    ${email}    ${password}
    Wait Until Element Is Visible    ${EMAIL_INPUT}    timeout=${TIMEOUT}
    Input Text       ${EMAIL_INPUT}       ${email}
    Input Password    ${PASSWORD_INPUT}    ${password}
    Click Element Safely    ${LOGIN_BUTTON}

Login Error Message Should Contain
    [Arguments]    ${expected_text}
    Wait Until Element Contains    ${LOGIN_ERROR}    ${expected_text}    timeout=${TIMEOUT}
