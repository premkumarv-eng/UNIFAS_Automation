*** Settings ***
Library    ${CURDIR}/ssh_utils.py

*** Variables ***
${HOST}        ${AP_SSH_CREDS["HOST"]}
${USER}        ${AP_SSH_CREDS["USER"]}
${PORT}        ${AP_SSH_CREDS["PORT"]}
${KEY_PATH}    ${CURDIR}/key
${SUDO_PASS}   ${AP_SSH_CREDS["SUDO_PASS"]}

*** Keywords ***
SSH To AP
    ${session}=    ssh_sudo_session    ${HOST}    ${USER}    ${PORT}    ${KEY_PATH}    ${SUDO_PASS}
    [Return]    ${session}

Close SSH Session
    [Arguments]    ${session}
    close_session    ${session}
    Log    Closed SSH session: ${session}