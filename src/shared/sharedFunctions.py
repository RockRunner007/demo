import logging
import csv
import requests
import json
import zipfile

def configure_logging():
    logging.basicConfig(format="%(asctime)s - %(levelname)s - %(message)s", level=logging.INFO)

def convert_csvToJson(csvFilePath: str, fileKey: str) -> dict:
    data = {}

    with open(csvFilePath, encoding='utf-8') as csvf:
        csvReader = csv.DictReader(csvf)

        for rows in csvReader:
            key = rows[fileKey]
            data[key] = rows            
    return data

def convert_zipToJson(zipFilePath: str, outputFile: str) -> None:
    with zipfile.ZipFile(zipFilePath, "r") as z:
        for filename in z.namelist():  
            with z.open(filename) as f:  
                data = json.loads(f.read().decode("utf-8"))

                with open(outputFile, 'w') as outfile:
                    json.dump(data, outfile)

def _set_headers(username: str = None, api_key: str = None):
    headers = {'Content-Type': 'application/json'}
    if username: headers['Authorization'] = f'Basic {username}'
    if api_key: headers['Authorization'] = f'token {api_key}'

    return headers

def process_api_request(url: str, verb: str, headers: dict, data: dict = None, params: dict = None):
    try:
        if data: r = getattr(requests, verb.lower())(url,headers=headers,data=json.dumps(data))
        elif params: r = getattr(requests, verb.lower())(url,headers=headers,params=json.dumps(params))
        else: r = getattr(requests, verb.lower())(url,headers=headers)

        r.raise_for_status()
    except Exception as e:
        logging.error(f'An error occured executing the API call: {e}')

    try:
        if r.status_code == 500 or r.status_code == 401: 
            logging.error(r.json())
            return None
        return r.json()
    except Exception as e:
        logging.error(f'An error occured loading the content: {e}')
        return None