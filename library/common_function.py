import requests
import json

def get_common(url_get, headers):
    # group_id_list = []
    # print(url_get)
    response = requests.request("GET", url_get, headers=headers)
    print(f"Status Code: {response.status_code}")
    if response.status_code == 200:
        print("Fetched the Security group list successfully", response.text)
        response_json = response.json()
        response_json = response.json()
        body = response_json.get('body', [])
        for item in body:
            group_id = item.get('groupId')
            group_id_list.append(group_id)
        return group_id_list
    else:
        print("Failed to fetch the security group list:", response.text)

def post_common(url, headers, payload,updated_orgid,updated_subsiteid):
    data = json.dumps(payload)
    update_data = json.loads(data)
    update_data['siteId'] = updated_subsiteid
    update_data['tenantId'] = updated_orgid
    # # Now use json.dumps() on the dictionary
    json_data = json.dumps(update_data)
    print(json_data)
    response = requests.request("POST", url, headers=headers, data=json_data)
    if response.status_code == 400:
        status = "pass"
        print("subsite.Invalid certPassAddress", response.text)
    return status

def data_filter(response, data_var):
    response = json.dumps(response)
    data = json.loads(response)
    print(data)
    # Fetch the templateId
    filter_data = data['body'][data_var]
    # Print the templateId
    print(f"filter_data: {filter_data}")
    return filter_data

def update_field_payload(payload,elem_to_update, elem_value):
    print(payload)
    payload[elem_to_update] = elem_value
    print(payload)
    return payload