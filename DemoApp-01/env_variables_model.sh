## ------------------------------------------------- ##
## How to edit and use this file: 
## 1. Make a copy of this file naming it env_vars.sh
## 2. Remove the leading '#' characters 
##    from the variable definitions below
## 3. Edit the variables with your own values
## 4. Source your terminal or scripts: 
##      source ./env_vars.sh
## ------------------------------------------------- ##


## ------------------------------------------------- ##
## Edit the following variables with your own values:
## ------------------------------------------------- ##

#GCP_PROJECT_ID="your-unique-gcp-project-id"
#GCP_PROJECT_REGION="your-preferred-region" 


## ------------------------------------------------- ##
## You can keep the variables bellow
## as is.
## ------------------------------------------------- ##

#GCP_PROJECT_NAME="DemoApp-01"
#GCP_PROJECT_PREFIX="demoapp-01"
#TAG="v1" 

## ------------------------------------------------- ##
## Don`t touch. It`s and art!		
## ------------------------------------------------- ##

#GCP_PROJECT_REPOSITORY="$GCP_PROJECT_PREFIX-repo" 
#GCP_IMAGE_NAME="$GCP_PROJECT_PREFIX-image" 
#GCP_IMAGE="$GCP_PROJECT_REGION-docker.pkg.dev/$GCP_PROJECT_ID/$GCP_PROJECT_REPOSITORY/$GCP_IMAGE_NAME:$TAG" 