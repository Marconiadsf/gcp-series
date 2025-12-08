#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

if [ -f ./env_vars.sh ]; then
    echo -e "${BLUE}ℹ️ Loading environment variables from env_vars.sh${NC}"
else
    echo -e " ${RED}❌ Error: env_vars.sh file not found!${NC}"
    exit 1
fi

source ./env_vars.sh


# If the first argument is "clean", run the cleaning flow and exit
if [ "$1" == "clean" ]; then
    echo -e "${YELLOW}🧹 Cleaning...${NC}"
    ERROR_COUNTER=0

    # Delete the Artifact Registry repository
    #if ! gcloud artifacts repositories delete cloud-run-source-deploy --location=$GCP_PROJECT_REGION --quiet; then
    #    echo -e "${RED}❌ Failed to delete Artifact Registry repository. It may not exist or there was an error.${NC}"
    #    ERROR_COUNTER=$((ERROR_COUNTER + 1))
    #else
    #    echo -e "${GREEN}✅ Artifact Registry repository deleted successfully.${NC}"
    #fi
   
    # Delete the Cloud Run service 
    if ! gcloud run services delete $GCP_PROJECT_PREFIX --region=$GCP_PROJECT_REGION; then
        echo -e "${RED}❌ Failed to delete Cloud Run service. It may not exist or there was an error.${NC}"
        ERROR_COUNTER=$((ERROR_COUNTER + 1))
    else
        echo -e "${GREEN}✅ Cloud Run service deleted successfully.${NC}"
    fi

    # Delete the GCP project
    if gcloud projects delete $GCP_PROJECT_ID ; then
        echo -e "${GREEN}✅ Project $GCP_PROJECT_ID deleted successfully.${NC}"
    else
        echo -e "${RED}❌ Failed to delete project $GCP_PROJECT_ID. It may not exist or there was an error.${NC}"
        ERROR_COUNTER=$((ERROR_COUNTER + 1))
    fi
    

    # Revoke all gcloud credentials
    if ! gcloud auth revoke --all; then
        echo -e "${RED}❌ Failed to revoke gcloud credentials.${NC}"
        ERROR_COUNTER=$((ERROR_COUNTER + 1))
    else
        echo -e "${GREEN}✅ gcloud credentials revoked successfully.${NC}"
    fi


    echo -e "${GREEN}✅ Cleaning completed. Total errors: $ERROR_COUNTER. Check logs above for details.${NC}"
    exit 0
fi


if [ -z "$GCP_PROJECT_ID" ] || [ -z "$GCP_PROJECT_REGION" ] || [ -z "$GCP_PROJECT_NAME" ] || [ -z "$GCP_PROJECT_PREFIX" ]; then
    echo -e "${RED}❌ Error: Required environment variables are not set!${NC}"
    exit 1
fi

if ! gcloud auth login; then
    echo -e "${RED}❌ Authentication failed. You need to be logged in to deploy the application.${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Authentication successful.${NC}"

if ! gcloud projects create "$GCP_PROJECT_ID" --name="$GCP_PROJECT_NAME"; then
    # Verifica se o projeto já existe
    if gcloud projects describe "$GCP_PROJECT_ID" &>/dev/null; then
        echo "⚠️ O projeto $GCP_PROJECT_ID já existe."
        read -p "Deseja continuar usando este projeto? (Y/n): " choice
        case "$choice" in
            [Yy]*|"")
                echo "✅ Continuando com o projeto existente: $GCP_PROJECT_ID"
                gcloud config set project "$GCP_PROJECT_ID"
                ;;
            *)
                echo "❌ Abortando conforme solicitado."
                exit 1
                ;;
        esac
    else
        echo -e "${RED}❌ Falha ao criar projeto $GCP_PROJECT_ID. Verifique os logs do gcloud.${NC}"
        exit 1
    fi
fi

if ! gcloud config set project $GCP_PROJECT_ID; then
    echo -e "${RED}❌ Failed to set project $GCP_PROJECT_ID. Check gcloud logs for details.${NC}"
    exit 1
fi


read -p "Enter your billing account ID: " GCP_BILLING_ACCOUNT_ID

if ! gcloud beta billing projects link $GCP_PROJECT_ID --billing-account=$GCP_BILLING_ACCOUNT_ID; then
    echo -e "${RED}❌ Failed to link billing account $GCP_BILLING_ACCOUNT_ID to project $GCP_PROJECT_ID. Check gcloud logs for details.${NC}"
    unset GCP_BILLING_ACCOUNT_ID
    exit 1
fi

unset GCP_BILLING_ACCOUNT_ID


if ! gcloud services enable run.googleapis.com cloudbuild.googleapis.com; then
    echo -e "${RED}❌ Failed to enable required services. Check gcloud logs for details.${NC}"
    exit 1
fi 

#if ! gcloud artifacts repositories create cloud-run-source-deploy \
#  --repository-format=docker \
#  --location=$GCP_PROJECT_REGION \
#  --description="Default repo for Cloud Run source deploy"; then
#    echo -e "${RED}❌ Failed to create Artifact Registry repository. Check gcloud logs for details.${NC}"
#    exit 1
#fi

cd src

PROJECT_NUMBER=$(gcloud projects describe $GCP_PROJECT_ID --format="value(projectNumber)")
gcloud projects add-iam-policy-binding $GCP_PROJECT_ID \
  --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
  --role="roles/editor"

if ! gcloud run deploy $GCP_PROJECT_PREFIX --region=$GCP_PROJECT_REGION  --platform=managed --source .; then
    echo -e "${RED}❌ Deployment failed. Check gcloud logs for details.${NC}"
    exit 1
fi
cd ..
