#!/bin/bash

# --- 1. Define Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# --- 2. Pre-Scan: Detect Tag & Intent ---
# We scan arguments to see if we need to enforce the Project Tag check.

REQUIRES_CONTEXT=false  # Default: We assume we don't need the tag
HAS_TAG_FLAG=false

for arg in "$@"; do
    case "$arg" in
        -tag=*)
            # Extract the value after the '='
            export GCP_PROJECT_TAG="${arg#*=}"
            HAS_TAG_FLAG=true
            ;;
        deploy| deploy-fix-buildpacks | deploy-container|clean|fullclean)
            # These commands MODIFY cloud resources, so they NEED the tag/context
            REQUIRES_CONTEXT=true
            ;;
        # login, logout, and help DO NOT trigger REQUIRES_CONTEXT
    esac
done

# --- 3. Validate Context (Only if needed) ---
# This only runs if the user requested a command that needs the tag (like 'deploy')

if [ "$REQUIRES_CONTEXT" = true ]; then
    if [ -z "$GCP_PROJECT_TAG" ]; then
        echo -e "${RED}❌ Error: GCP_PROJECT_TAG is not defined!${NC}"
        echo -e "The command you selected requires a project context."
        echo ""
        echo -e "Please define it using one of these methods:"
        echo -e "  ${YELLOW}1. Command Line:${NC}  ./ops.sh -tag=myproject deploy"
        echo -e "  ${YELLOW}2. Export:${NC}        export GCP_PROJECT_TAG=myproject"
        exit 1
    fi

    # Only load environment vars if we are actually deploying/cleaning
    if [ -f ./env_vars.sh ]; then
        source ./env_vars.sh
    else
        echo -e "${RED}❌ Error: env_vars.sh file not found!${NC}"
        exit 1
    fi
fi

# --- 4. Define Helper Functions ---

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

# Function to pause script execution to allow IAM changes to propagate
wait_for_propagation() {
    local seconds=$1
    echo -e "${YELLOW}⏳ Waiting ${seconds}s for IAM permissions to propagate...${NC}"
    
    # Simple countdown loop
    while [ $seconds -gt 0 ]; do
       echo -ne "   Time remaining: $seconds\033[0K\r" # \r overwrites the line
       sleep 1
       : $((seconds--))
    done
    echo -e "   ✅ Ready to proceed!          "
}

show_help() {
    echo -e "${BLUE}Usage: $0 [-tag=xxx] {login|deploy|deploy-container|clean|fullclean}${NC}"
    echo -e "  ${YELLOW}-tag=xxx${NC}              : (Optional) Set the project tag for this run"
    echo -e "  ${YELLOW}login${NC}                 : Authenticate with Google Cloud"
    echo -e "  ${YELLOW}logout${NC}                : Revoke credentials"
    echo -e "  ${YELLOW}deploy${NC}                : Simple source deployment (Automated Buildpacks)"
    echo -e "  ${YELLOW}deploy-fix-buildpacks${NC} : Simple source deployment (Manual Buildpack - use if you are getting 403 Error)"
    echo -e "  ${YELLOW}deploy-container${NC}      : Manual container build & deploy (Robust, but require Dockerfile)"
    echo -e "  ${YELLOW}clean${NC}                 : Delete GCloud service"
    echo -e "  ${YELLOW}fullclean${NC}             : Delete GCloud service and project"
}

# --- 5. Core Logic Functions ---

setup_project_and_billing() {
    local IS_FRESH_PROJECT=false # 1. Default to false

    log_info "Verifying project status for TAG: $GCP_PROJECT_TAG..."
    log_info "Project ID: $GCP_PROJECT_ID"

    if gcloud projects describe "$GCP_PROJECT_ID" &>/dev/null; then
        echo -e "${YELLOW}⚠️  Project $GCP_PROJECT_ID already exists. Using it.${NC}"
    else
        log_info "Project does not exist. Creating..."
        run_safe "Project creation failed." "Project created." \
                 gcloud projects create "$GCP_PROJECT_ID" --name="$GCP_PROJECT_NAME"
        
        IS_FRESH_PROJECT=true # 2. Mark as fresh since we just created it
    fi

    # ... (Rest of the standard setup logic: set project, billing) ...
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

    # 3. Only wait if the project is actually new
    if [ "$IS_FRESH_PROJECT" = true ]; then
        wait_for_propagation 90
    fi
}

cleanup_resources() {
    local clean_mode="$1"
    echo -e "${YELLOW}🧹 Cleaning up resources ($clean_mode)...${NC}"

    log_info "Deleting Cloud Run service..." 
    # FIX: Added --project=$GCP_PROJECT_ID to force the correct target
    gcloud run services delete $GCP_PROJECT_PREFIX \
        --region=$GCP_PROJECT_REGION \
        --project=$GCP_PROJECT_ID \
        --quiet || true
    
    if [ "$clean_mode" == "fullclean" ]; then
        log_info "Deleting GCP Project..."
        gcloud projects delete $GCP_PROJECT_ID --quiet || true
    fi

    echo -e "${GREEN}✅ Cleanup finished.${NC}"
}

# --- 5.1 Deployment Strategies ---

deploy_simple() {
    setup_project_and_billing
    cd src || exit
    log_info "🚀 Deploying from source (Simple Mode)..."
    run_safe "Deployment failed." "Deployment successful!" \
             gcloud run deploy $GCP_PROJECT_PREFIX --source . --region=$GCP_PROJECT_REGION --platform=managed --allow-unauthenticated
    cd ..
}

deploy_fix_buildpacks() {
    setup_project_and_billing
    cd src || exit
    
    # Define the image name manually
    IMAGE_TAG="gcr.io/$GCP_PROJECT_ID/$GCP_PROJECT_PREFIX"
    
    log_info "🚀 Deploying using Buildpacks (Bypassing 403 check)..."

    # Step 1: EXPLICITLY build using Buildpacks
    # This replaces 'gcloud run deploy --source' which was failing
    log_info "🔨 Building image with Buildpacks..."
    run_safe "Build failed." "Build successful." \
             gcloud builds submit --pack image=$IMAGE_TAG .

    # Step 2: Deploy the image we just built
    log_info "🚀 Deploying image..."
    run_safe "Deployment failed." "Deployment successful!" \
             gcloud run deploy $GCP_PROJECT_PREFIX \
             --image $IMAGE_TAG \
             --region=$GCP_PROJECT_REGION \
             --platform=managed \
             --allow-unauthenticated
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

# --- 6. Main Execution Block ---

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
        deploy-fix-buildpacks)
            ACTION_PERFORMED=true
            echo -e "${BLUE}➡️  Executing: $cmd${NC}"
            deploy_fix_buildpacks
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
