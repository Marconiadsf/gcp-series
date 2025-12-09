#!/bin/bash

## ------------------------------------------------- ##
## How to edit and use this file: 
## 1. Make a copy of this file naming it env_vars.sh
##    cp env_variables_model.sh env_vars.sh
## 2. Edit the variables below with your own values
## 3. Source it in your terminal: 
##      source ./env_vars.sh
## ------------------------------------------------- ##


## ------------------------------------------------- ##
## REQUIRED: Edit with your own values
## ------------------------------------------------- ##

export GCP_PROJECT_ID="your-unique-gcp-project-id${GCP_PROJECT_TAG}"
export GCP_PROJECT_REGION="us-central1"


## ------------------------------------------------- ##
## OPTIONAL: You can keep the variables below as is
## ------------------------------------------------- ##

export GCP_PROJECT_NAME="DemoApp-02"
export GCP_PROJECT_PREFIX="demoapp-02"

## ------------------------------------------------- ##
## AUTOMATED: Don't touch. It's an art!
## ------------------------------------------------- ##

export GCP_PROJECT_REPOSITORY="${GCP_PROJECT_PREFIX}-repo" 
export GCP_IMAGE_NAME="${GCP_PROJECT_PREFIX}-image" 
export GCP_IMAGE="${GCP_PROJECT_REGION}-docker.pkg.dev/${GCP_PROJECT_ID}/${GCP_PROJECT_REPOSITORY}/${GCP_IMAGE_NAME}:${TAG}"
