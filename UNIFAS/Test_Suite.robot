*** Settings ***
Library    RequestsLibrary
Library    Collections
Library    String
Variables   Environments/payloads.yaml

*** Variables ***
${BASE_URL}       https://uf17-fdev.unifas.jp/UNIFAS/MS/
${LOGIN_PAGE}     admin/login.php
${LOGIN_API}      webapi/v1/admin/authenticate.php
${Logout_API}     webapi/v1/admin/authenticate.php?logout
${CONTENT_TYPE}   application/json


*** Test Cases ***
Session Login Test

    Create Session    mysession    ${BASE_URL}

    ${resp1}=    GET On Session    mysession    ${LOGIN_PAGE}
    Log To Console    Login Page Status: ${resp1.status_code}

    ${headers}=    Create Dictionary
    ...    Content-Type=application/x-www-form-urlencoded
    ...    Referer=${BASE_URL}${LOGIN_PAGE}
    ...    Origin=${BASE_URL}
    ...    User-Agent=Mozilla/5.0

    ${payload}=    Set Variable     ${token_payload}

    ${response}=    POST On Session
    ...    mysession
    ...    ${LOGIN_API}
    ...    data=${payload}
    ...    headers=${headers}

    Log To Console    ---------------- LOGIN RESPONSE ----------------
    Log To Console    Status: ${response.status_code}
    Log To Console    Headers: ${response.headers}

    ${cookie_exists}=    Run Keyword And Return Status
    ...    Dictionary Should Contain Key    ${response.headers}    Set-Cookie
    Run Keyword If    '${cookie_exists}' == 'False'    Fail    ❌ Login Failed - No Cookie Returned
    ${set_cookie}=    Get From Dictionary    ${response.headers}    Set-Cookie
    Log To Console    Cookie: ${set_cookie}
    ${resp2}=    GET On Session    mysession    admin/accessPointList.php
    Log To Console    ---------------- NEXT API ----------------
    Log To Console    Status: ${resp2.status_code}
    Log To Console    Final URL: ${resp2.url}
    Should Not Contain    ${resp2.url}    login.php


#    GET On Session    mysession    ${Logout_API}











#*** Test Cases ***
#Session Login Test
#
#    # ✅ Step 1: Create session
#    Create Session    mysession    ${BASE_URL}
#
#    # ✅ Step 2: Open login page (VERY IMPORTANT)
#    ${resp1}=    GET On Session    mysession    ${LOGIN_PAGE}
#    Log    Login Page Status: ${resp1.status_code}
#
#    # ✅ Step 3: Prepare headers (important ones)
#    ${headers}=    Create Dictionary
#    ...    Content-Type=${CONTENT_TYPE}
#    ...    Referer=${BASE_URL}${LOGIN_PAGE}
#    ...    Origin=${BASE_URL}
#    ...    User-Agent=Mozilla/5.0
#
#    # ✅ Step 4: Payload (match EXACTLY from browser)
#    ${payload}=    Set Variable    ${token_payload}
#
#    # 🔐 Step 5: Login POST
#    ${response}=    POST On Session
#    ...    mysession
#    ...    ${LOGIN_API}
#    ...    json=${payload}
#    ...    headers=${headers}
#
#    Log    Login Status: ${response.status_code}
#    Log    Login Response: ${response.text}
#
#    # ✅ Step 6: Check cookie exists
#    Dictionary Should Contain Key    ${response.headers}    Set-Cookie
#
#    ${set_cookie}=    Get From Dictionary    ${response.headers}    Set-Cookie
#    Log    ${set_cookie}
#
#    # ✅ Step 7: Verify login via protected API
#    ${resp2}=    GET On Session    mysession    /UNIFAS/MS/admin/accessPointList.php
#
#    Log    Final URL: ${resp2.url}
#    Log    Status: ${resp2.status_code}
#
#    Should Not Contain    ${resp2.url}    login.php
