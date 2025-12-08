# DemoApp-01: Local Deployment Example

This is a simple demo application illustrating how to deploy a local Python app to Google Cloud Run using the `gcloud` command-line tool.

## Prerequisites

**Important:** Follow the `README.md` in the root directory of this repository first. That guide sets up your development environment, including Docker, VSCode, and the necessary Dev Container.

## 1. Understanding the Application

The demo application is a simple **Gradio** example that creates a web interface for uploading audio files. It uses the Gradio library to handle the UI and file processing.

### 1.1 File Structure

* `src/`: Contains the source code.
    * `app.py`: The main application code defining the Gradio interface.
    * `requirements.txt`: Python dependencies.
* `env_variables_model.sh`: A template script to set environment variables for GCP deployment.
* `.gitignore`: Specifies files ignored by git (critical for security).

## 2. Building and Running Locally

1.  **Open the Terminal:** Ensure you are inside the Dev Container.
2.  **Navigate to the folder:**
    ```bash
    cd DemoApp-01/src
    ```
    *(Note: The Dev Container has already installed the dependencies from `requirements.txt` globally, so you can run Python directly.)*

3.  **Run the application:**
    ```bash
    python app.py
    ```

You should see output indicating the server is running at `http://127.0.0.1:8080`. Open this URL in your browser to test the interface.

## 3. Deploying to Google Cloud Run

### 3.1 Setting Up Environment Variables

1.  **Move back to the DemoApp-01 folder:**
    ```bash
    cd ..
    ```

2.  **Create your config file:**
    Copy the template to a new file named `env_vars.sh` (this file is git-ignored to prevent leaking secrets).
    ```bash
    cp env_variables_model.sh env_vars.sh
    ```

3.  **Edit the file:**
    Open `env_vars.sh` and fill in your specific Google Cloud details. You typically only need to change:
    * `GCP_PROJECT_ID`
    * `GCP_PROJECT_REGION`
    * `GCP_BILLING_ACCOUNT_ID`

4.  **Load the variables:**
    Source the file to load these variables into your current terminal session:
    ```bash
    source env_vars.sh
    ```

### 3.2 Setting Up Google Cloud SDK

Ensure your CLI is authenticated and pointing to the right project.

1.  **Login:**
    ```bash
    gcloud auth login
    ```
2.  **Configure Project:**
    ```bash
    # Create the project (if it doesn't exist yet)
    gcloud projects create $GCP_PROJECT_ID --name="$GCP_PROJECT_NAME"

    # Set the project as the default for commands
    gcloud config set project $GCP_PROJECT_ID
    ```
3.  **Link Billing (If required):**
    ```bash
    gcloud beta billing projects link $GCP_PROJECT_ID --billing-account=<your-billing-id>
    ```

### 3.3 Fixing IAM Permissions

Sometimes the default compute service account lacks the necessary permissions to deploy successfully. We must explicitly grant it the Editor role.

Run the following block to fetch your Project Number and update the IAM policy:

```bash
PROJECT_NUMBER=$(gcloud projects describe $GCP_PROJECT_ID --format="value(projectNumber)")

gcloud projects add-iam-policy-binding $GCP_PROJECT_ID \
  --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
  --role="roles/editor"
```

### 3.4 Enabling Required APIs

Cloud Run and Cloud Build must be enabled on your project:
```bash
gcloud services enable run.googleapis.com cloudbuild.googleapis.com
```

### 3.5 Deploying the Application

1.  **Navigate to source:** Ensure you are in the `src` folder (where `app.py` is located).
    ```bash
    cd src
    ```
2.  **Deploy:**
    ```bash
    gcloud run deploy --source .
    ```

    **Interactive Prompts:**
    * **Service Name:** Press Enter to accept the default.
    * **Region:** Select the region matching your `$GCP_PROJECT_REGION`.
    * **Allow unauthenticated invocations:** Type `y` (Recommended for this demo so you can access it publicly).

Once complete, the terminal will display the **Service URL**. Click it to view your live app!

---

## 4. Cleaning Up

To avoid incurring charges, remove the resources when you are done.

```bash
# Delete the Cloud Run Service
gcloud run services delete <service-name> --region=$GCP_PROJECT_REGION

# Delete the entire project (Optional - Destructive!)
gcloud projects delete $GCP_PROJECT_ID
```

## References

* **Google Cloud Quickstart:** [Build and deploy a Python (Gradio) web app to Cloud Run](https://docs.cloud.google.com/run/docs/quickstarts/build-and-deploy/deploy-python-gradio-service)
