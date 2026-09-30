*** Settings ***
Documentation     Login functionality: a valid account plus a set of data-driven
...               negative cases, using Robot's Template mechanism.
Resource          ../resources/pages/home_page.resource
Resource          ../resources/pages/login_page.resource
Library           ../libraries/AccountApi.py

Suite Setup       Create Test Account
Suite Teardown    Delete Test Account
Test Setup        Open Application
Test Teardown     Close Application

*** Variables ***
${WRONG_PASSWORD}    not-the-real-password

*** Test Cases ***
Valid Login Succeeds
    ${email}=       Get Test Account Email
    ${password}=    Get Test Account Password
    ${name}=        Get Test Account Name
    Go To Login Page
    Login With Credentials    ${email}    ${password}
    User Should Be Logged In As    ${name}

Login With Wrong Password Is Rejected
    ${email}=    Get Test Account Email
    Go To Login Page
    Login With Credentials    ${email}    ${WRONG_PASSWORD}
    Login Error Message Should Contain    Your email or password is incorrect

Login Rejected For Invalid Credentials
    [Template]    Attempt Login And Expect Error
    definitely.not.a.real.user.qa@nowhere.test    SomePassword123
    ghost.user@thisdomaindoesnotexist987.test     AnotherPass123

*** Keywords ***
Attempt Login And Expect Error
    [Arguments]    ${email}    ${password}
    Go To Login Page
    Login With Credentials    ${email}    ${password}
    Login Error Message Should Contain    incorrect
