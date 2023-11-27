#!/usr/bin/env python3

import argparse
import csv
import json
import logging
import os
import requests
import sys

import smtplib, ssl

from datetime import datetime, timedelta, timezone
from shared import sharedFunctions as sf

class ProjectMapping:
    def __init__(self, orgID, orgName, projID, projName, projUrl, scanDate):
        self.orgID = orgID
        self.orgName = orgName
        self.projID = projID
        self.projName = projName
        self.projUrl = projUrl
        self.scanDate = scanDate

def get_orgs(domain, token):
    return sf.process_api_request(f'{domain}/orgs', 'GET', sf._set_headers(api_key=token))

def get_projects(orgID, domain, token):
    return sf.process_api_request(f'{domain}/org/{orgID}/projects', 'GET', sf._set_headers(api_key=token))

def get_sbom(orgID, projID, domain, token):

    # curl --get -H "Authorization: token <token>" --data-urlencode "version=2023-03-20" --data-urlencode "format=cyclonedx1.4+json" https://api.snyk.io/rest/orgs/a7a0554f-e3a9-4649-b574-dbbd0678b6ce/projects/81aad013-edae-47b4-83e0-db36febecf75/sbom
    return sf.process_api_request(f'{domain}/org/{orgID}/projects/{projID}/sbom', 'GET', sf._set_headers(api_key=token))

def parseArgs():
    parser = argparse.ArgumentParser(description='Audit Snyk Scans', usage="%(prog)s [options]",)
    
    parser.add_argument("--snykToken", "-st", required=False, default=os.getenv('SNYK_TOKEN', "NONE"), type=str)
    parser.add_argument("--gitToken", "-gt", required=False, default=os.getenv('GIT_TOKEN', "NONE"), type=str, help="Gitlab PAT. Ideally don't set this value with the switch, use an env var.  Default is to read from the var GIT_TOKEN.")
    
    args = parser.parse_args()
    return args

def main(args):
    sf.configure_logging()

    # pip install cyclonedx-bom
    # python3.10 -m pip install --upgrade pip
    # cyclonedx-py -r --format json -o sbom.json

    print("-----Starting-----")

    token = args.snykToken
    domain = "https://app.snyk.io/api/v1"
    api_domain = "https://api.snyk.io/rest"

    org_list = [] # list of org
    dept_orgs = get_orgs(domain, token)
    if dept_orgs is None: 
        sys.exit(1)

    for orgs in dept_orgs.items():
        for org in orgs[1]:
            orgID = org['id']
            org_list.append(orgID)

    sf.logging.info(f'organization details retrieved')

    project_list = [] # list of project
    for org in org_list:
        projects = get_projects(org, domain, token)
        
        for project in projects.items():
            projectCount = 0
            for project_def in project[1]:
                if isinstance(project_def, dict):
                    nameSplit = str(project_def['name']).split("/", 1)
                    project_list.append(ProjectMapping(org, nameSplit[0], project_def['id'], project_def['name'], project_def['browseUrl'], ""))
                
                projectCount +=1
                if projectCount >= 10:
                    break

    sf.logging.info(f'currently has {len(project_list)}') # get project count

    for project in project_list:
        sbom = get_sbom(project.orgID, project.projID, api_domain, token)
        with open(f"{project.projName}_{datetime.now()}.json", "a") as f:
            json.dump(sbom, f)
            f.close()
    
    print("-----Completed-----")

if __name__ == '__main__':
    main(args=parseArgs())