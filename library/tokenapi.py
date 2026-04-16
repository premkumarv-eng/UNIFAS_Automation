from urllib import response

import requests
def access_token(url,payload,headers) :
  response = requests.request("POST", url, headers=headers, data=payload)
  if response.status_code == 200:
    # Extract the token from the response
    token = response.json().get('access_token')
    print(token)
  else:
    print('Failed to fetch the token:', response.status_code, response.text)
  return  token




def access_session(url,payload, headers):
  response = requests.request("POST", url, headers=headers, data=payload)
  if response.status_code == 200:
    # Extract the session from the response
    session_id = response.cookies().get('session')
    print(session_id)

    if not session_id:
      cookie=response.header.get('Set-Cookie')
      print(cookie)
    return session_id

  else:
    print('Failed to fetch the session:', response.status_code, response.text)
    return None







