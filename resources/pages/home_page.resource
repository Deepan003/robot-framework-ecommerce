*** Settings ***
Library     SeleniumLibrary
Resource    ../common.resource

*** Variables ***
${SIGNUP_LOGIN_LINK}     css:a[href="/login"]
${LOGGED_IN_AS_LABEL}    xpath://a[contains(text(),'Logged in as')]
${LOGOUT_LINK}           css:a[href="/logout"]

*** Keywords ***
Go To Home Page
    Go To    ${BASE_URL}

Go To Login Page
    Click Element Safely    ${SIGNUP_LOGIN_LINK}

User Should Be Logged In As
    [Arguments]    ${username}
    # Wait Until Element Contains re-locates the element on every retry, which
    # Wait Until Element Is Visible + a separate assertion doesn't: the nav bar
    # here can still be settling right after the post-login redirect, and a
    # handle grabbed a moment too early goes stale before the assertion runs.
    Wait Until Element Contains    ${LOGGED_IN_AS_LABEL}    ${username}    timeout=${TIMEOUT}

Logout
    Click Element Safely    ${LOGOUT_LINK}
