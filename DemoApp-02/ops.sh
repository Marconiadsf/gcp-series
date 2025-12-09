#!/bin/bash

# --- 1. Define Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# --- 2. Pre-Scan for Configuration Flags ---
# We loop through all arguments just to find overrides like -tag=xxx
for arg in "$@"; do
    case "$arg" in
        -tag=*)
            # Extract the value after the '='
            export GCP_PROJECT_TAG="${arg#*=}"
            ;;
    esac
done

# --- 3. Validate Pre-Requisites ---
# This runs BEFORE env_vars.sh is sourced
if [ -z "$GCP_PROJECT_TAG" ]; then
    echo -e "${RED}❌ Error: GCP_PROJECT_TAG is not defined!${NC}"
    echo -e "This variable is required to load the correct environment context."
    echo ""
    echo -e "Please define it using one of these methods:"
    echo -e "  ${YELLOW}1. Command Line:${NC}  ./ops -tag=myproject deploy"
    echo -e "  ${YELLOW}2. Export:${NC}        export GCP_PROJECT_TAG=myproject"
    exit 1
fi

# --- 4. Load Environment ---
if [ -f ./env_vars.sh ]; then
    # Pass the tag to the script if needed, or just rely on the exported var
    source ./env_vars.sh
else
    echo -e "${RED}❌ Error: env_vars.sh file not found!${NC}"
    exit 1
fi

# --- 5. Define Helper Functions ---

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

show_help() {
    echo -e "${BLUE}Usage: $0 [-tag=xxx] {login|deploy|deploy-container|clean|fullclean}${NC}"
    echo -e "  ${YELLOW}-tag=xxx${NC}         : (Optional) Set the project tag for this run"
    echo -e "  ${YELLOW}login${NC}            : Authenticate with Google Cloud"
    echo -e "  ${YELLOW}logout${NC}           : Revoke credentials"
    echo -e "  ${YELLOW}deploy${NC}           : Simple source deployment (Automated Buildpacks)"
    echo -e "  ${YELLOW}deploy-container${NC} : Manual container build & deploy (Robust)"
    echo -e "  ${YELLOW}clean${NC}            : Delete GCloud service"
    echo -e "  ${YELLOW}fullclean${NC}        : Delete GCloud service and project"
}
# --- 6. Core Logic Functions ---

setup_project_and_billing() {
    log_info "Verifying project status for TAG: $GCP_PROJECT_TAG..."

    if gcloud projects describe "$GCP_PROJECT_ID" &>/dev/null; then
        echo -e "${YELLOW}⚠️  Project $GCP_PROJECT_ID already exists. Using it.${NC}"
    else
        log_info "Project does not exist. Creating..."
        run_safe "Project creation failed." "Project created." \
                 gcloud projects create "$GCP_PROJECT_ID" --name="$GCP_PROJECT_NAME"
    fi

    run_safe "Failed to set project." "Project set." gcloud config set project $GCP_PROJECT_ID

    if [ -z "$GCP_BILLING_ACCOUNT_ID" ]; then
        log_info "Listing billing accounts..."
        gcloud beta billing accounts list
        read -p "Enter your billing account ID: " GCP_BILLING_ACCOUNT_ID
    fi

    log_info "Linking billing account..."
    run_safe "Failed to link billing." "Billing linked." \
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

# --- 7. Deployment Strategies ---

deploy_simple() {
    setup_project_and_billing
    cd src || exit
    log_info "🚀 Deploying from source (Simple Mode)..."
    run_safe "Deployment failed." "Deployment successful!" \
             gcloud run deploy $GCP_PROJECT_PREFIX --source . --region=$GCP_PROJECT_REGION --platform=managed --allow-unauthenticated
    cd ..
}

deploy_container() {
    setup_project_and_billing
    cd src || exit
    IMAGE_TAG="gcr.io/$GCP_PROJECT_ID/$GCP_PROJECT_PREFIX"
    log_info "🔨 Building container image: $IMAGE_TAG..."
    run_safe "Build failed." "Build successful." gcloud builds submit --tag $IMAGE_TAG .
    log_info "🚀 Deploying container image..."
    run_safe "Deployment failed." "Deployment successful!" \
             gcloud run deploy $GCP_PROJECT_PREFIX --image $IMAGE_TAG --region=$GCP_PROJECT_REGION --platform=managed --allow-unauthenticated
    cd ..
}

# --- 8. Main Execution Block ---

# --- 8. Main Execution Block ---

# If absolutely no arguments are provided, force "help"
if [ $# -eq 0 ]; then
    set -- "help"
fi

ACTION_PERFORMED=false

for cmd in "$@"; do
    case "$cmd" in
        -tag=*)
            # Configuration flag, already handled in Pre-Scan. 
            # We skip it here, but we DO NOT mark it as an action.
            continue 
            ;;
        clean|fullclean)
            ACTION_PERFORMED=true
            echo -e "${BLUE}➡️  Executing: $cmd${NC}"
            cleanup_resources "$cmd"
            ;;
        login)
            ACTION_PERFORMED=true
            echo -e "${BLUE}➡️  Executing: $cmd${NC}"
            log_info "Logging into gcloud..."
            run_safe "Authentication failed." "Authentication successful." gcloud auth login
            ;;
        logout)
            ACTION_PERFORMED=true
            echo -e "${BLUE}➡️  Executing: $cmd${NC}"
            log_info "Revoking GCloud credentials..."
            gcloud auth revoke --all || true
            ;;
        deploy)
            ACTION_PERFORMED=true
            echo -e "${BLUE}➡️  Executing: $cmd${NC}"
            deploy_simple
            ;;
        deploy-container)
            ACTION_PERFORMED=true
            echo -e "${BLUE}➡️  Executing: $cmd${NC}"
            deploy_container
            ;;
        help)
            ACTION_PERFORMED=true
            show_help
            ;;
        *)
            echo -e "${RED}❌ Error: Unrecognized command: '$cmd'${NC}"
            exit 1
            ;;
    esac
    echo ""
done

# FINAL CHECK: If the loop finished but we never performed an action
# (e.g., the user ran "./ops.sh -tag=123" but forgot a command)
if [ "$ACTION_PERFORMED" = false ]; then
    show_help
fi
