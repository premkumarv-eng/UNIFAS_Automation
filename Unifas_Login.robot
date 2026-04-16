*** Settings ***
Library    RequestsLibrary
Library    Collections
Library    String
Library    BuiltIn
Library    JSONLibrary
Library    OperatingSystem
Variables    argument_file.py
Library    ssh_utils.py
Resource    ap_ssh.robot

Suite Setup       Create Test Session
Suite Teardown    Clean Up Setup

*** Variables ***
${BASE_URL}    ${Login_Creds["BASE_URL"]}
${ENDPOINT_URL}    ${Login_Creds["ENDPOINT_URL"]}
${USERNAME}    ${Login_Creds["USERNAME"]}
${PASSWORD}    ${Login_Creds["PASSWORD"]}
${SITE}    ${Login_Creds["SITE"]}
${api_session}    ${Login_Creds["SESSION_NAME"]}    
${site_id}    ${Login_Creds["SITE_ID"]}
${aid}    ${Login_Creds["AP_AID"]}
@{SESSION_IDS} 
${LOGIN_PAGE}         admin/login.php
${LOGIN_API}          ${ENDPOINT_URL}authenticate.php
${LOGOUT_API}         ${ENDPOINT_URL}authenticate.php?logout
${ACCESS_POINT_API}   ${ENDPOINT_URL}accessPointList.php
${EDIT_API}           ${ENDPOINT_URL}accessPointEdit.php?context=update
${SWITCH_SUBTITLE}    ${ENDPOINT_URL}switch-subsites.php
${GET_AP_DATA}    ${ENDPOINT_URL}accessPointEdit.php?
${GET_AP_STATUS}    ${ENDPOINT_URL}accessPointList.php?context=list


${COMMON_HEADERS}=    Create Dictionary    
...    User-Agent=Mozilla/5.0
...    Accept=application/json, text/javascript, */*; q=0.01

*** Test Cases ***
Session Login And Access Point Flow
    Login To Application    ${api_session}    
    Validate Session        ${api_session}
    Call Access Point API   ${api_session}

Get ALL AccessPoint Status
    Switch Subsite    ${site_id}
    ${resp}=    GET On Session
    ...    ${api_session}
    ...    ${GET_AP_STATUS}
    Log    ${resp}
    Log    ${resp.content}
    ${ap_data}=    Remove HTML Junk Value    ${resp.content}    ${columns}
    ${len_results}=    Get Length    ${ap_data}
    Log    ${ap_data}
    FOR    ${index}    IN RANGE    ${len_results}
        ${row}=    Get From List    ${ap_data}    ${index}
        Log    Row ${index}: ${row}
    END

    Validate Status Code By Operation    ${resp}    GET


Get And Verify AP Basic Details
    ${resp}=    GET On Session
    ...    ${api_session}
    ...    ${GET_AP_STATUS}
    
    Log    ${resp}
    Log    ${resp.content}
    ${results}=    Remove HTML Junk Value    ${resp.content}    ${columns}
    Log    ${results}
    ${target}=    Set Variable    ${AP_DETAILS["NAME"]}

    FOR    ${item}    IN    @{results}
        IF    '${item["AP Name"]}' == '${target}'
            ${ap_data}=    Set Variable    ${item}
            BREAK
        END
    END
    Log    ${ap_data}

    Log    ${ap_data["AP Name"]}
    Log    ${ap_data["Status"]}
    Log    ${ap_data["Model"]}
    Log    ${ap_data["Version"]}
    Log    ${ap_data["Serial Number"]}
    Log    ${ap_data["MAC"]}
    Log    ${ap_data["Last Boot-Updated Time"]}

    Should Be Equal    ${ap_data["AP Name"]}    ${AP_DETAILS["NAME"]}
    Should Be Equal    ${ap_data["Model"]}    ${AP_DETAILS["MODEL"]}
    Should Be Equal    ${ap_data["Serial Number"]}    ${AP_DETAILS["SERIAL NUMBER"]}
    Should Be Equal    ${ap_data["MAC"]}    ${AP_DETAILS["MAC"]}
    Should Be Equal    ${ap_data["Status"]}    UP
    

Get AP Current Running Configurations 
    Switch Subsite    ${site_id}
    ${results}=    Get AP Data    ${aid}
    Should Not Be Empty    ${results}
    Log    ${results}
    FOR    ${section}    ${section_data}    IN    &{results}
        Log    ===== ${section} =====

        ${is_dict}=    Evaluate    isinstance($section_data, dict)
        IF    ${is_dict}
            FOR    ${key}    ${value}    IN    &{section_data}
                Log    ${key} = ${value}
            END
        ELSE
            Log    ${section} = ${section_data}
        END
    END

AP Firmware Check
    ${resp}=    GET On Session
    ...    ${api_session}
    ...    ${GET_AP_STATUS}
    
    Log    ${resp}
    Log    ${resp.content}
    ${results}=    Remove HTML Junk Value    ${resp.content}    ${columns}
    Log    ${results}
    ${target}=    Set Variable    ${AP_DETAILS["NAME"]}

    FOR    ${item}    IN    @{results}
        IF    '${item["AP Name"]}' == '${target}'
            ${ap_data}=    Set Variable    ${item}
            BREAK
        END
    END
    Log    ${ap_data}
    Log    "AP Is Currently Running With Software Version" : ${ap_data["Version"]}
    ${Command_Output}=    Execute Command On AP    cat /etc/version
    Log    ${Command_Output}
    ${Results}=    cli_output_parser    ${Command_Output}    =    list
    ${Ap_SW_Version}=    Set Variable    ${Results[0]}
    Log    ${Ap_SW_Version}
    Should Be Equal    ${ap_data["Version"]}    ${Ap_SW_Version}


Configure 5G SSID and Password in AP
    ${csrf_token}=    Generate_CSRF_Token
    Should Not Be Empty    ${csrf_token}
    
    ${Modify_Dictionary}=    Copy Dictionary    ${VALUE_DICT}
    Set To Dictionary    ${Modify_Dictionary}    csrfToken       ${csrf_token}
    Set To Dictionary    ${Modify_Dictionary}    aid             ${aid}
    Set To Dictionary    ${Modify_Dictionary}    wlan1_grp[]     ${RADIO_5G_WLAN1_CONFIG["SSID_5G_Value"]}
    Log    ${Modify_Dictionary}
    ${status}=    Run Keyword And Return Status    Update AP Config    ${csrf_token}    ${Modify_Dictionary}
    Run Keyword IF    ${status}    Log    AP configuration is done successfully    ELSE    Log    AP config is failed...!    level=ERROR
    Sleep With Message    180s    Waiting 180s for Wi-Fi driver to reload
    ${Command_Output}=    Execute Command On AP    ${RADIO_5G_WLAN1_CONFIG["Radio 5G ATH0 DETAILS"]}
    Log    Command Output: ${Command_Output}
    ${Results}=    cli_output_parser    ${Command_Output}    =    dict
    Log    ${Results}
    Log    ${Results["wireless.ath0.ifname"]}
    Log    ${Results["wireless.ath0.ssid"]}
    Log    ${Results["wireless.ath0.key"]}
    Should Be Equal    ${Results["wireless.ath0.ssid"]}    '${RADIO_5G_WLAN1_CONFIG["SSID"]}'
    Should Be Equal    ${Results["wireless.ath0.key"]}    '${RADIO_5G_WLAN1_CONFIG["PSK"]}'

Configure 2.4G SSID and Password in AP
    ${csrf_token}=    Generate_CSRF_Token
    Should Not Be Empty    ${csrf_token}
    
    ${Modify_Dictionary}=    Copy Dictionary    ${VALUE_DICT}
    Set To Dictionary    ${Modify_Dictionary}    csrfToken       ${csrf_token}
    Set To Dictionary    ${Modify_Dictionary}    aid             ${aid}
    Set To Dictionary    ${Modify_Dictionary}    wlan2_grp[]     ${RADIO_24G_WLAN2_CONFIG["SSID_2.4G_Value"]}
    Log    ${Modify_Dictionary}

    ${Results}=    Update AP Config    ${csrf_token}    ${Modify_Dictionary}
    Log To Console    ${Results}
    Sleep With Message    300s    Waiting 180s for Wi-Fi driver to reload
    ${Command_Output}=    Execute Command On AP    ${RADIO_24G_WLAN2_CONFIG["Radio 2.4G ATH1 DETAILS"]}
    Log    Command Output: ${Command_Output}
    ${Results}=    cli_output_parser    ${Command_Output}    =    dict
    Log    ${Results}
    Log    ${Results["wireless.ath1.ifname"]}
    Log    ${Results["wireless.ath1.ssid"]}
    Log    ${Results["wireless.ath1.key"]}
    Should Be Equal    ${Results["wireless.ath1.ssid"]}    '${RADIO_24G_WLAN2_CONFIG["SSID"]}'
    Should Be Equal    ${Results["wireless.ath1.key"]}    '${RADIO_24G_WLAN2_CONFIG["PSK"]}'

Diable Beamforming and MU-MIMO Feature in 5G Radio
    ${csrf_token}=    Generate_CSRF_Token
    Should Not Be Empty    ${csrf_token}
    ${Modify_Dictionary}=    Copy Dictionary    ${VALUE_DICT}
    Set To Dictionary    ${Modify_Dictionary}    csrfToken       ${csrf_token}
    Set To Dictionary    ${Modify_Dictionary}    aid             ${aid}
    Set To Dictionary    ${Modify_Dictionary}    wlan1_beamforming    0   
    Set To Dictionary    ${Modify_Dictionary}    wlan1_mu_mimo    0
    Log    ${Modify_Dictionary}
    ${status}=    Run Keyword And Return Status    Update AP Config    ${csrf_token}    ${Modify_Dictionary}
    Run Keyword IF    ${status}    Log    AP configuration is done successfully    ELSE    Log    AP config is failed...!    level=ERROR
    Sleep With Message    30s    Waiting 30s for Wi-Fi driver to reload
    ${results}=    Get AP Data    ${aid}
    Should Not Be Empty    ${results}
    Log    ${results}
    Log    "Radio 5G [wlan1_beamforming] Value": ${results["value"]["wlan1_beamforming"]}
    Log    "Radio 5G [wlan1_mu_mimo] Value": ${results["value"]["wlan1_mu_mimo"]}
    Should Be Equal    ${results["value"]["wlan1_beamforming"]}    ${flag_values["diable"]}
    Should Be Equal    ${results["value"]["wlan1_mu_mimo"]}    ${flag_values["diable"]}

Enable Beamforming and MU-MIMO Feature in 5G Radio
    ${csrf_token}=    Generate_CSRF_Token
    Should Not Be Empty    ${csrf_token}
    ${Modify_Dictionary}=    Copy Dictionary    ${VALUE_DICT}
    Set To Dictionary    ${Modify_Dictionary}    csrfToken       ${csrf_token}
    Set To Dictionary    ${Modify_Dictionary}    aid             ${aid}
    Set To Dictionary    ${Modify_Dictionary}    wlan1_beamforming    1   
    Set To Dictionary    ${Modify_Dictionary}    wlan1_mu_mimo    1
    Log    ${Modify_Dictionary}
    ${status}=    Run Keyword And Return Status    Update AP Config    ${csrf_token}    ${Modify_Dictionary}
    Run Keyword IF    ${status}    Log    AP configuration is done successfully    ELSE    Log    AP config is failed...!    level=ERROR
    Sleep With Message    30s    Waiting 30s for Wi-Fi driver to reload
    ${results}=    Get AP Data    ${aid}
    Should Not Be Empty    ${results}
    Log    ${results}
    Log    "Radio 5G [wlan1_beamforming] Value": ${results["value"]["wlan1_beamforming"]}
    Log    "Radio 5G [wlan1_mu_mimo] Value": ${results["value"]["wlan1_mu_mimo"]}
    Should Be Equal    ${results["value"]["wlan1_beamforming"]}    ${flag_values["enable"]}
    Should Be Equal    ${results["value"]["wlan1_mu_mimo"]}    ${flag_values["enable"]}

Diable Beamforming and MU-MIMO Feature in 2.4G Radio
    ${csrf_token}=    Generate_CSRF_Token
    Should Not Be Empty    ${csrf_token}
    ${Modify_Dictionary}=    Copy Dictionary    ${VALUE_DICT}
    Set To Dictionary    ${Modify_Dictionary}    csrfToken       ${csrf_token}
    Set To Dictionary    ${Modify_Dictionary}    aid             ${aid}
    Set To Dictionary    ${Modify_Dictionary}    wlan2_beamforming    0   
    Set To Dictionary    ${Modify_Dictionary}    wlan2_mu_mimo    0
    Log    ${Modify_Dictionary}
    ${status}=    Run Keyword And Return Status    Update AP Config    ${csrf_token}    ${Modify_Dictionary}
    Run Keyword IF    ${status}    Log    AP configuration is done successfully    ELSE    Log    AP config is failed...!    level=ERROR
    Sleep With Message    30s    Waiting 30s for Wi-Fi driver to reload
    ${results}=    Get AP Data    ${aid}
    Should Not Be Empty    ${results}
    Log    ${results}
    Log    "Radio 2.4G [wlan2_beamforming] Value": ${results["value"]["wlan2_beamforming"]}
    Log    "Radio 2.4G [wlan2_mu_mimo] Value": ${results["value"]["wlan2_mu_mimo"]}
    Should Be Equal    ${results["value"]["wlan2_beamforming"]}    ${flag_values["diable"]}
    Should Be Equal    ${results["value"]["wlan2_mu_mimo"]}    ${flag_values["diable"]}

Enable Beamforming and MU-MIMO Feature in 2.4G Radio
    ${csrf_token}=    Generate_CSRF_Token
    Should Not Be Empty    ${csrf_token}
    ${Modify_Dictionary}=    Copy Dictionary    ${VALUE_DICT}
    Set To Dictionary    ${Modify_Dictionary}    csrfToken       ${csrf_token}
    Set To Dictionary    ${Modify_Dictionary}    aid             ${aid}
    Set To Dictionary    ${Modify_Dictionary}    wlan2_beamforming    1   
    Set To Dictionary    ${Modify_Dictionary}    wlan2_mu_mimo    1
    Log    ${Modify_Dictionary}
    ${status}=    Run Keyword And Return Status    Update AP Config    ${csrf_token}    ${Modify_Dictionary}
    Run Keyword IF    ${status}    Log    AP configuration is done successfully    ELSE    Log    AP config is failed...!    level=ERROR
    Sleep With Message    30s    Waiting 30s for Wi-Fi driver to reload
    ${results}=    Get AP Data    ${aid}
    Should Not Be Empty    ${results}
    Log    ${results}
    Log    "Radio 2.4G [wlan2_beamforming] Value": ${results["value"]["wlan2_beamforming"]}
    Log    "Radio 2.4G [wlan2_mu_mimo] Value": ${results["value"]["wlan2_mu_mimo"]}
    Should Be Equal    ${results["value"]["wlan2_beamforming"]}    ${flag_values["enable"]}
    Should Be Equal    ${results["value"]["wlan2_mu_mimo"]}    ${flag_values["enable"]}


Diable BandSteering Feature
    ${csrf_token}=    Generate_CSRF_Token
    Should Not Be Empty    ${csrf_token}
    ${Modify_Dictionary}=    Copy Dictionary    ${VALUE_DICT}
    Set To Dictionary    ${Modify_Dictionary}    csrfToken       ${csrf_token}
    Set To Dictionary    ${Modify_Dictionary}    aid             ${aid}
    Set To Dictionary    ${Modify_Dictionary}    band_steering    0   
    Log    ${Modify_Dictionary}
    ${status}=    Run Keyword And Return Status    Update AP Config    ${csrf_token}    ${Modify_Dictionary}
    Run Keyword IF    ${status}    Log    AP configuration is done successfully    ELSE    Log    AP config is failed...!    level=ERROR
    Sleep With Message    30s    Waiting 30s for Wi-Fi driver to reload
    ${results}=    Get AP Data    ${aid}
    Should Not Be Empty    ${results}
    Log    ${results}
    Log    "BandSteering Feature Value": ${results["value"]["band_steering"]}
    Should Be Equal    ${results["value"]["band_steering"]}    ${flag_values["diable"]}

Enable BandSteering Feature
    ${csrf_token}=    Generate_CSRF_Token
    Should Not Be Empty    ${csrf_token}
    ${Modify_Dictionary}=    Copy Dictionary    ${VALUE_DICT}
    Set To Dictionary    ${Modify_Dictionary}    csrfToken       ${csrf_token}
    Set To Dictionary    ${Modify_Dictionary}    aid             ${aid}
    Set To Dictionary    ${Modify_Dictionary}    band_steering    1   
    Log    ${Modify_Dictionary}
    ${status}=    Run Keyword And Return Status    Update AP Config    ${csrf_token}    ${Modify_Dictionary}
    Run Keyword IF    ${status}    Log    AP configuration is done successfully    ELSE    Log    AP config is failed...!    level=ERROR
    Sleep With Message    30s    Waiting 30s for Wi-Fi driver to reload
    ${results}=    Get AP Data    ${aid}
    Should Not Be Empty    ${results}
    Log    ${results}
    Log    "BandSteering Feature Value": ${results["value"]["band_steering"]}
    Should Be Equal    ${results["value"]["band_steering"]}    ${flag_values["enable"]}


Reboot AP
    # ${csrf_token}=    Generate_CSRF_Token
    # Should Not Be Empty    ${csrf_token}
    # ${resp}=    GET On Session
    # ...    ${api_session}
    # ...    ${GET_AP_STATUS}
    
*** Keywords ***

Create Test Session
    Create Session    ${api_session}    ${BASE_URL}    verify=False    timeout=10
    Track Session    ${api_session}

Track Session
    [Arguments]    ${session_id}
    Append To List    ${SESSION_IDS}    ${session_id}

Login To Application
    [Arguments]    ${session}
    ${resp}=    GET On Session    ${session}    ${LOGIN_PAGE}
    Validate Status Code By Operation    ${resp}    GET
    Log    Login Page Status: ${resp.status_code}

    # Login payload as string (x-www-form-urlencoded)
    ${login_payload}=    Set Variable    SITE=${SITE}&LID=${USERNAME}&LPWD=${PASSWORD}

    # Headers for login
    &{login_headers}=    Create Dictionary
    ...    Content-Type=application/x-www-form-urlencoded
    ...    Referer=${BASE_URL}${LOGIN_PAGE}
    ...    Origin=${BASE_URL}
    ...    User-Agent=Mozilla/5.0

    ${login_resp}=    POST On Session
    ...    ${session}
    ...    ${LOGIN_API}
    ...    data=${login_payload}
    ...    headers=${login_headers}

    Validate Status Code By Operation    ${login_resp}    POST    authenticate.php

    # Validate login cookie
    ${cookie_exists}=    Run Keyword And Return Status
    ...    Dictionary Should Contain Key    ${login_resp.headers}    Set-Cookie
    Run Keyword If    not ${cookie_exists}    Fail    ❌ Login Failed

    ${cookie}=    Get From Dictionary    ${login_resp.headers}    Set-Cookie
    Log    Cookie: ${cookie}

   # ${json}=    Load JSON From String    ${login_resp.text}
   # Should Be Equal    ${json["status"]}    success

Remove HTML Junk Value
    [Arguments]    ${data}    ${columns}
    ${json}=    RequestsLibrary.To Json    ${data}
    Run Keyword If    not ${json["data"]}    Fail    "No AP data found in response"
    @{ap_data}=    Create List
    FOR    ${row}    IN    @{json["data"]}
        @{clean_row}=    Evaluate    [re.sub(r'<[^>]+>', '', str(x)).strip() for x in ${row}]    modules=re
        ${lan_index}=    Get Index From List    ${columns}    LAN Info
        ${clean_row[${lan_index}]}=    Replace String    ${clean_row[${lan_index}]}    <br>    ' '
        ${row_dict}=    Evaluate    dict(zip(${columns}, ${clean_row}))    modules=builtins
        Append To List    ${ap_data}    ${row_dict}
    END
    [Return]    ${ap_data}

Switch Subsite
    [Arguments]    ${site_id}
    &{payload}=    Create Dictionary    siteid=${site_id}
    &{headers}=    Create Dictionary    Content-Type=application/x-www-form-urlencoded

    ${resp}=    POST On Session
    ...    ${api_session}
    ...    ${SWITCH_SUBTITLE}
    ...    data=${payload}
    ...    headers=${headers}

    Log    Switch Status: ${resp.status_code}
    Log    Switch Response: ${resp.content}


Get AP Data
    [Arguments]    ${aid}
    &{params}=    Create Dictionary
    ...    context=getdata
    ...    aid=${aid}

    ${resp}=    GET On Session
    ...    ${api_session}
    ...    ${GET_AP_DATA}
    ...    params=${params}

    Validate Status Code By Operation    ${resp}    GET

    ${status}    ${json}=    Parse AP Response To JSON    ${resp.content}
    Run Keyword If    '${status}' != 'PASS'    Fail    API Parsing Failed

    ${ap_data}=    Convert Output Into Dictionary Format    ${json}

    Return From Keyword    ${ap_data}

Sleep With Message
    [Arguments]    ${seconds}    ${message}
    Log    ${message}
    Sleep    ${seconds}

Execute Command On AP
    [Arguments]    ${command}
    ${session}=    SSH To AP
    Log    Session ID: ${session}
    Should Not Be Empty    ${session}
    ${output}=    send_command    ${session}    ${command}
    [Return]    ${output}

Generate_CSRF_Token
    # Switch to the Subsite
    Switch Subsite    ${site_id}   

    # ── Step 5: Visit Dashboard After Switch ────────────────────────────────
    ${resp_dashboard}=    GET On Session    ${api_session}    /admin/dashboard.php
    Log    Dashboard Status: ${resp_dashboard.status_code}
    # ── Step 6: Get Fresh CSRF Token from accessPointList AFTER switch ───────
    ${headers_list}=    Create Dictionary
    ...    Accept=text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8
    ...    Referer=${BASE_URL}admin/dashboard.php
    ...    User-Agent=Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:148.0) Gecko/20100101 Firefox/148.0

    ${resp_list}=    GET On Session    ${api_session}
    ...    /admin/accessPointList.php
    ...    headers=${headers_list}

    Log    List Page Status: ${resp_list.status_code}

    ${csrf_matches}=    Get Regexp Matches
    ...    ${resp_list.text}
    ...    csrfToken:\\s*'([a-f0-9]+)'    1

    Should Not Be Empty    ${csrf_matches}    msg=CSRF token not found in accessPointList!
    ${csrf_token}=    Set Variable    ${csrf_matches[0]}
    Log To Console    CSRF TOKEN FROM LIST: ${csrf_token}

    # ── Step 7: POST to Edit Page to Get Fresh Token ─────────────────────────
    ${headers_html}=    Create Dictionary
    ...    Content-Type=application/x-www-form-urlencoded
    ...    Accept=text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8
    ...    Referer=${BASE_URL}admin/accessPointList.php
    ...    Origin=https://uf17-fdev.unifas.jp
    ...    User-Agent=Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:148.0) Gecko/20100101 Firefox/148.0
    ...    Upgrade-Insecure-Requests=1

    ${html_payload}=    Set Variable    csrfToken=${csrf_token}&aid=${aid}

    ${resp_html}=    POST On Session    ${api_session}
    ...    /admin/accessPointEdit.php
    ...    data=${html_payload}
    ...    headers=${headers_html}

    Log    Edit HTML Status: ${resp_html.status_code}
    Log    Edit HTML Body: ${resp_html.text}

    # ── Step 8: Extract Fresh CSRF Token from Edit Page ──────────────────────
    ${csrf_matches2}=    Get Regexp Matches
    ...    ${resp_html.text}
    ...    csrfToken:\\s*'([a-f0-9]+)'    1

    Should Not Be Empty    ${csrf_matches2}    msg=CSRF token not found in edit page!
    ${csrf_token}=    Set Variable    ${csrf_matches2[0]}
    Log To Console    CSRF TOKEN FROM EDIT PAGE: ${csrf_token}
    [Return]    ${csrf_token}

Update AP Config
    [Arguments]    ${csrf_token}    ${Updated_Dictionary}

    &{headers}=    Create Dictionary
    ...    Content-Type=application/x-www-form-urlencoded
    ...    Referer=${BASE_URL}admin/accessPointEdit.php
    ...    Origin=${BASE_URL}
    ...    X-Requested-With=XMLHttpRequest
    ...    User-Agent=Mozilla/5.0

    ${resp}=    POST On Session
    ...    ${api_session}
    ...    url=${EDIT_API}
    ...    data=${Updated_Dictionary}
    ...    headers=${headers}

    Log    Status: ${resp.status_code}
    ${resp.status_code}=    Convert To String    ${resp.status_code}
    Should Be Equal    ${resp.status_code}    200
    Log    Response: ${resp.content}
    Should Contain    ${resp.content}    "success":true

Validate Session
    [Arguments]    ${session}
    ${ui_resp}=    GET On Session    ${session}    admin/accessPointList.php
    Validate Status Code By Operation    ${ui_resp}    GET
    Log    UI Page Status: ${ui_resp.status_code}
    Should Not Contain    ${ui_resp.url}    login.php

Call Access Point API
    [Arguments]    ${session}
    ${timestamp}=    Evaluate    int(time.time()*1000)    modules=time

    # Headers for API call
    &{api_headers}=    Create Dictionary
    ...    User-Agent=Mozilla/5.0
    ...    Accept=application/json, text/javascript, */*; q=0.01
    ...    Referer=${BASE_URL}admin/accessPointList.php
    ...    X-Requested-With=XMLHttpRequest

    # Query parameters
    &{params}=    Create Dictionary
    ...    context=list
    ...    _=${timestamp}

    # GET Access Point API
    ${api_resp}=    GET On Session
    ...    ${session}
    ...    ${ACCESS_POINT_API}
    ...    params=${params}
    ...    headers=${api_headers}

    Validate Status Code By Operation    ${api_resp}    GET
    Log    Access Point API Response: ${api_resp.content}

    # Optional JSON parsing using Python's json module
    ${json}=    To JSON    ${api_resp.content}
    Log    ${json}
  #  ${json}=    Load JSON From String    ${api_resp.text}
  #  Should Contain    ${json}    accessPoints

Parse AP Response To JSON
    [Arguments]    ${response_content}
    ${content_str}=    Convert To String    ${response_content}
    ${status}    ${json_output}=    Run Keyword And Ignore Error    To JSON    ${content_str}
    Return From Keyword    ${status}    ${json_output}


Convert Output Into Dictionary Format
    [Arguments]    ${ap_dict}
    ${updated_dict}=    Create Dictionary
    FOR    ${section}    IN    @{ap_dict.keys()}
        ${sub_dict}=    Get From Dictionary    ${ap_dict}    ${section}
        ${nested_dict}=    Create Dictionary
        FOR    ${key}    IN    @{sub_dict.keys()}
            ${value}=    Get From Dictionary    ${sub_dict}    ${key}
            Set To Dictionary    ${nested_dict}    ${key}    ${value}
        END
        Set To Dictionary    ${updated_dict}    ${section}    ${nested_dict}
    END
    Return From Keyword    ${updated_dict}

Validate Status Code By Operation
    [Arguments]    ${response}    ${operation}    ${endpoint}=None

    ${operation}=    Convert To Uppercase    ${operation}

    IF    $operation == 'GET'
        ${expected}=    Set Variable    200
    ELSE IF    $operation == 'POST' and $endpoint == 'authenticate.php'
        ${expected}=    Set Variable    200
    ELSE IF    $operation == 'POST'
        ${expected}=    Set Variable    201
    ELSE IF    $operation == 'PUT'
        ${expected}=    Set Variable    200
    ELSE IF    $operation == 'DELETE'
        ${expected}=    Set Variable    200
    ELSE
        Fail    Unsupported HTTP method: ${operation}
    END
    ${response.status_code}=    Convert To String    ${response.status_code}
    Should Be Equal    ${response.status_code}    ${expected}
    Log    ✅ ${operation} request returned expected status code ${expected}

Logout From Application
    [Arguments]    ${session}
    ${resp}=    GET On Session    ${session}    ${LOGOUT_API}
    Validate Status Code By Operation    ${resp}    GET
    Log    Logout Status: ${resp.status_code}

Delete Session If Exists
    [Arguments]    ${session_id}
    ${status}    ${msg}=    Run Keyword And Ignore Error    Delete On Session    ${session_id}    ${BASE_URL} 
    Log    Deleting session '${session_id}' → ${status}
    Validate Status Code By Operation    ${msg}    DELETE

Clean Up Setup
    Log    ===== Starting Suite Cleanup =====
    Logout From Application    ${api_session}
    FOR    ${session}    IN    @{SESSION_IDS}
        Delete Session If Exists    ${session}
    END
    Log    ===== Cleanup Completed Successfully ✅ =====
