#AccessPoint Details
AP_DETAILS = {
    "NAME" : "WN9875",
    "MODEL": "ACERA1310",
    "SERIAL NUMBER": "7151-9875",
    "MAC": "00:D0:1D:6B:E5:EC"
}
# SSH Details
AP_SSH_CREDS = {
    "HOST" : "172.20.254.121",
    "USER" : "ssh-maint",
    "PORT" : 8022,
    "SUDO_PASS" : "noessymusurFt0528!"
}

# UNIFAS TESTBED CONFIG
LOGIN_CREDS = {
    "BASE_URL": "https://uf17-fdev.unifas.jp/UNIFAS/MS/",
    "ENDPOINT_URL": "/webapi/v1/admin/",
    "USERNAME": "vvdn",
    "PASSWORD": "vvdn",
    "SITE": "vvdn.mysite",
    "SESSION_NAME": "get_on_unifas",
    "AP_AID": "1362",
    "SITE_ID": "91"
}

RADIO_5G_WLAN1_CONFIG = {
    "SSID" : "Mahesh_5G_SSID",
    "PSK" : "Mahesh@123",
    "SSID_5G_Value": "3073",
    "Radio 5G ATH0 DETAILS":"uci show wireless.ath0"
}

RADIO_24G_WLAN2_CONFIG = {
    "SSID" : "Mahesh_2G_SSID",
    "PSK" : "Mahesh@12345",
    "SSID_2.4G_Value": "3074",
    "Radio 2.4G ATH1 DETAILS":"uci show wireless.ath1"
}

VALUE_DICT = {
    "context": "update",
    "csrfToken": "",
    "aid": "",
    "mcode": "4650516",
    "type_name": "ACERA1310",
    "apname": "WN9875",
    "serno": "7151-9875",
    "ccode": "",
    "memo": "",
    "location": "0",
    "lldp": "2",
    "dhcp": "1",
    "msurl": "https://uf17-fdev.unifas.jp/UNIFAS/MS/",
    "proxy": "",
    "proxy_port": "",
    "eth1_setting": "0",
    "vlan_hybrid": "1",
    "station": "0",
    "link_check_priority": "0",
    "wlan_setting_essid": "2",
    "wlan1_band": "3",
    "wlan1_11n_type": "2",
    "wlan1_11n_mode": "0",
    "wlan1_sgi": "0",
    "wlan1_11n_pkt_collect": "2",
    "wlan1_ch": "0",
    "wlan1_power": "4",
    "wlan1_airtime": "1",
    "wlan1_bcast_rate": "24",
    "wlan1_mcast_rate": "24",
    "wlan1_grp_sg_check_num": "1",
    "wlan1_off_grp_sg_check_num": "0",
    "wlan1_beamforming": "0",
    "wlan1_mu_mimo": "0",
    "wlan1_block": "0",
    "wlan1_block_channel_list[]": ["36"],
    "wlan1_grp[]": "2930",
    "wlan2_band": "4",
    "wlan2_11n_type": "3",
    "wlan2_11n_mode": "0",
    "wlan2_sgi": "0",
    "wlan2_11n_pkt_collect": "2",
    "wlan2_ch": "1",
    "wlan2_power": "4",
    "wlan2_airtime": "1",
    "wlan2_bcast_rate": "11",
    "wlan2_mcast_rate": "11",
    "wlan2_beamforming": "1",
    "wlan2_mu_mimo": "1",
    "wlan2_bss_color": "0",
    "wlan2_grp_sg_check_num": "1",
    "wlan2_off_grp_sg_check_num": "0",
    "wlan2_grp[]": "2931",
    "uap_wlan": "1",
    "spec_memo": ""
}
columns = ["Checkbox","AP Name","Status","Location","Forms","Model","Version","Serial Number",
           "Static_Or_DHCP","MAC","LAN Info","VLAN Info","Mode","Last Boot-Updated Time"]