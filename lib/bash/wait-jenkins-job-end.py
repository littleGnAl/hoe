import requests
import sys
from time import sleep

requestUrl = str(sys.argv[1])
print(f'request url: {requestUrl}')

def waitJobEnd(url: str):
    x = requests.get(url)

    if x.status_code == 200:
        j = x.json()

        if ('result' in j):
            if j.get('result') == 'SUCCESS':
                print(j.get('result'))
                return

        print(f'Can not get result, attempt again. url: {url}')
        sleep(10)
        waitJobEnd(url)

waitJobEnd(requestUrl)
