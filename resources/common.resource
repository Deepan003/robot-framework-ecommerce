*** Settings ***
Library    SeleniumLibrary

*** Variables ***
${BASE_URL}       https://automationexercise.com
${BROWSER}        chrome
${TIMEOUT}        10s

*** Keywords ***
Open Application
    Open Browser    ${BASE_URL}    ${BROWSER}
    Maximize Browser Window
    Set Selenium Timeout    ${TIMEOUT}

Close Application
    Close Browser

Click Element Safely
    [Documentation]    automationexercise.com runs live ad slots that can slide
    ...    over a button mid-click and cause a normal Click Element to fail with
    ...    ElementClickInterceptedException. Falling back to a JS click bypasses
    ...    whatever is overlapping the element instead of failing the test over
    ...    an ad the site itself put there.
    [Arguments]    ${locator}
    Wait Until Element Is Visible    ${locator}    timeout=${TIMEOUT}
    TRY
        Click Element    ${locator}
    EXCEPT    *ElementClickInterceptedException*    type=GLOB
        ${element}=    Get WebElement    ${locator}
        Execute Javascript    arguments[0].click();    ARGUMENTS    ${element}
    END
