from dotenv import load_dotenv
import os
import sys
import time
import requests
import json


def main():

    # Clear the console
    os.system('cls' if os.name=='nt' else 'clear')

    try:

        # Get the business card schema
        with open("biz-card.json", "r") as file:
            schema_json = json.load(file)
        
        card_schema = json.dumps(schema_json)

        # Get config settings
        load_dotenv()
        ai_svc_endpoint = os.getenv('ENDPOINT')
        ai_svc_key = os.getenv('KEY')
        analyzer = os.getenv('ANALYZER_NAME')

        # Create the analyzer
        create_analyzer (card_schema, analyzer, ai_svc_endpoint, ai_svc_key)

        print("\n")

    except Exception as ex:
        print(ex)



def create_analyzer (schema, analyzer, endpoint, key):
    
    # Create a Content Understanding analyzer

    print(f"Creating analyzer '{analyzer}'...")
    CU_VERSION = "2024-12-01-preview"
    headers = {
        "Ocp-Apim-Subscription-Key": key,
        "Content-Type": "application/json"
    }
    url = f"{endpoint}/contentunderstanding/analyzers/{analyzer}?api-version={CU_VERSION}"
    response = requests.delete(url, headers=headers)
    print(f"Delete existing analyzer response: {response.status_code}")
    time.sleep(5)
    
    # Now create it
    response = requests.put(url, headers=headers, data=(schema))
    print(response.status_code)

    # Check if the request was successful
    if response.status_code not in [200, 201, 202]:
        print("Analyzer creation failed.")
        print(response.text)
        return

    # Get the response and extract the callback URL
    callback_url = response.headers.get("Operation-Location")
    if not callback_url:
        print("No Operation-Location header found.")
        return

    # Check the status of the operation
    time.sleep(1)
    result_response = requests.get(callback_url, headers=headers)

    # Keep polling until the operation is no longer running
    status = result_response.json().get("status")
    while status == "Running":
        time.sleep(1)
        result_response = requests.get(callback_url, headers=headers)
        status = result_response.json().get("status")

    result = result_response.json().get("status")
    print(result)
    if result == "Succeeded":
        print(f"Analyzer '{analyzer}' created successfully.")
    else:
        print("Analyzer creation failed.")
        print(result_response.json())
    
    
if __name__ == "__main__":
    main()        
