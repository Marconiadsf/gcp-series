#!/bin/bash

# --- 1. Define Variables & Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check for env_vars.sh immediately
if [ -f ./env_vars.sh ]; then
    source ./env_vars.sh
else
    echo -e "${RED}❌ Error: env_vars.sh file not found!${NC}"
    exit 1
fi

# --- 2. Define Helper Functions ---

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

run_safe() {
    local error_msg="$1"
    local success_msg="$2"
    shift 2
    "$@"
    if [ $? -ne 0 ]; then
    echo -e "${RED}❌ $error_msg${NC}"
    exit 1
    else
        echo -e "${GREEN}✅ $success_msg${NC}"
    fi
}

# --- 3. Core Logic Functions ---

setup_project_and_billing() {
    log_info "Verifying project status..."

    # Check if project exists first
    if gcloud projects describe "$GCP_PROJECT_ID" &>/dev/null; then
        echo -e "${YELLOW}⚠️  Project $GCP_PROJECT_ID already exists. Using it.${NC}"
    else
        log_info "Project does not exist. Creating..."
        # If create fails here (e.g. invalid name), run_safe will exit the script
        run_safe "Project creation failed. Check if name is valid." \
                 "Project created successfully." \
                 gcloud projects create "$GCP_PROJECT_ID" --name="$GCP_PROJECT_NAME"
    fi

    # Set the project context
    run_safe "Failed to set project context." "Project context set." gcloud config set project $GCP_PROJECT_ID

    # Billing Setup
    if [ -z "$GCP_BILLING_ACCOUNT_ID" ]; then
        log_info "Listing your billing accounts..."
        gcloud beta billing accounts list
        read -p "Enter your billing account ID: " GCP_BILLING_ACCOUNT_ID
    fi

    log_info "Linking billing account..."
    run_safe "Failed to link billing." \
             "Billing linked successfully." \
             gcloud beta billing projects link $GCP_PROJECT_ID --billing-account=$GCP_BILLING_ACCOUNT_ID
    
    
    unset GCP_BILLING_ACCOUNT_ID

    log_info "Enabling APIs..."
    run_safe "Failed to enable APIs." "APIs enabled." \
             gcloud services enable run.googleapis.com cloudbuild.googleapis.com artifactregistry.googleapis.com
}

cleanup_resources() {
    local clean_mode="$1"
    echo -e "${YELLOW}🧹 Cleaning up resources ($clean_mode)...${NC}"

    log_info "Deleting Cloud Run service..." 
    gcloud run services delete $GCP_PROJECT_PREFIX --region=$GCP_PROJECT_REGION --quiet || true
    
    if [ "$clean_mode" == "fullclean" ]; then
        log_info "Deleting GCP Project..."
        gcloud projects delete $GCP_PROJECT_ID --quiet || true
    fi

    echo -e "${GREEN}✅ Cleanup finished.${NC}"
}

# --- 4. Deployment Strategies ---

# STRATEGY A: Simple Deploy (Source -> Cloud Run)
# This relies on Google's automated buildpacks. 
deploy_simple() {
    setup_project_and_billing
    
    cd src || exit
    log_info "🚀 Deploying from source (Simple Mode)..."
    
    # Note: This is the method that was causing the 'experiments.yaml' 403 error previously
    run_safe "Deployment failed. Try 'deploy-container' mode if this persists." \
             "Deployment successful!" \
             gcloud run deploy $GCP_PROJECT_PREFIX \
             --source . \
             --region=$GCP_PROJECT_REGION \
             --platform=managed \
             --allow-unauthenticated
    cd ..
}

# STRATEGY B: Container Deploy (Build -> Push -> Deploy)
# This is the robust fix that separates build and deploy steps.
deploy_container() {
    setup_project_and_billing

    cd src || exit
    IMAGE_TAG="gcr.io/$GCP_PROJECT_ID/$GCP_PROJECT_PREFIX"

    log_info "🔨 Building container image: $IMAGE_TAG..."
    run_safe "Build failed." "Build successful." gcloud builds submit --tag $IMAGE_TAG .

    log_info "🚀 Deploying container image..."
    run_safe "Deployment failed." "Deployment successful!" \
             gcloud run deploy $GCP_PROJECT_PREFIX \
             --image $IMAGE_TAG \
             --region=$GCP_PROJECT_REGION \
             --platform=managed \
             --allow-unauthenticated
    cd ..
}

# --- 5. Main Execution Block ---

# If no arguments are provided, default to help
if [ $# -eq 0 ]; then
    set -- "help"
fi

# Loop through ALL arguments
for cmd in "$@"; do
    echo -e "${BLUE}➡️  Executing command: $cmd${NC}"
    
    case "$cmd" in
        clean|fullclean)
            cleanup_resources "$cmd"
            ;;
        login)
            log_info "Logging into gcloud..."
            run_safe "Authentication failed." "Authentication successful." gcloud auth login
            ;;
        logout)
            log_info "Revoking GCloud credentials..."
            gcloud auth revoke --all || true
            ;;
        deploy)
            deploy_simple
            ;;
        deploy-container)
            deploy_container
            ;;
        help)
        echo -e "${BLUE}Usage: $0 {login|deploy|deploy-container|clean|fullclean}${NC}"
        echo -e "  ${YELLOW}login${NC}            : Authenticate with Google Cloud"
        echo -e "  ${YELLOW}logout${NC}           : Remove credentials"
        echo -e "  ${YELLOW}deploy${NC}           : Simple source deployment (Automated Buildpacks)"
        echo -e "  ${YELLOW}deploy-container${NC} : Manual container build & deploy (More robust)"
        echo -e "  ${YELLOW}clean${NC}            : Delete GCloud service"
        echo -e "  ${YELLOW}fullclean${NC}        : Delete GCloud service and project"
        
        ;;
    *)
        echo -e "${RED}❌ Error: Unrecognized command: '$cmd'${NC}"
            exit 1
            ;;
    esac
    
    echo "" # Add a spacer line between commands
done
