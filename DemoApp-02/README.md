# DemoApp-02 : Local deployment example - Automating Google Cloud Run deployment.
This is a simple demo application to illustrate local deployment to Google Cloud Run using the `gcloud` command-line tool.


## Prerequisites

**Follow README.md in the root directory for setting up your environment: This will give you the necessary environment
to run the demo applications, including installing Docker, VSCode, git (optional), and setting up the development container.**

## Table of Contents
* [1. Understanding the Application](#1-understanding-the-application)
  * [1.1 File Structure](#11-file-structure)
* [2. Building and Running the Application Locally](#2-building-and-running-the-application-locally)
* [3. Deploying to Google Cloud Run](#3-deploying-to-google-cloud-run)
  * [3.1 Setting Up Environment Variables](#31-setting-up-environment-variables)
  * [3.2 Deploying the GCP Project](#32-deploying-the-gcp-project)
  * [3.3 Cleaning Up](#33-cleaning-up)
* [Notes](#notes)
* [References](#references)

## 1. Understanding the Application
The demo application is a simple **Gradio** example that creates a web interface for uploading audio files. It uses the Gradio library to handle the UI and file processing.

### 1.1 File Structure

* `src/`: Contains the source code.
    * `app.py`: The main application code defining the Gradio interface.
    * `requirements.txt`: Python dependencies.
* `deploy_to_cloud.sh`: The main automation script for deployment and cleanup.
* `env_variables_model.sh`: A template script to set environment variables for GCP deployment.
* `.gitignore`: Specifies files ignored by git (critical for security).

		
## 2. Building and Running the Application Locally
In the dev container terminal, navigate to the DemoApp-02/src directory:
```bash
cd DemoApp-02/src
```
The dev container built with the Dockerfile.dev already has the dependencies installed from requirements.txt.
You can run the application directly using Python:
```bash
python app.py
```
This will start the gradio application, and you should see output indicating that the server is running, along with a 
local URL (e.g., `http://127.0.0.1:8080`). You can open this URL in your web browser to interact with the application.

## 3. Deploying to Google Cloud Run

### 3.1 Setting Up Environment Variables

1.  **Move back to the DemoApp-02 folder:**
   
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

### 3.2 Deploying the GCP Project
		
This time we packed all the deployment workflow into a script.
Make sure you are in the DemoApp-02 directory.
List your billing information and keep it in hand, when the script asks for it.

Then run:

```bash
./deploy_to_cloud.sh
```

The script will source the env_vars.sh file to get the necessary environment variables and then proceed to create the GCP project,
enable required APIs, ask for billing account and finally deploy the application to Cloud Run.
You should see output in the terminal indicating the progress of each step.

You may be required to answer some prompts after this command, to set some things like:
- additional APIs: answer y if prompted
- public access: answer y to allow unauthenticated invocations (recommended for this demo purpose) 

After the deployment is complete, you will see a URL where your application is hosted. You can open this URL 
in your web browser to access the deployed application.

Congratulations! You have successfully deployed the DemoApp-02 application to Google Cloud Run.

### 3.3 Cleaning Up
Before jumping into the next DemoApp you may want to delete all the resources created in this DemoApp-02:

```bash
./deploy_to_cloud.sh clean
```
This will delete the Cloud Run service and the GCP project created for this demo.

## Notes

>As the standard Gradio examples and my tries to deploy from Google Console had failed, the setup and deployment process is heavily 
based on the following Google Cloud CLI tutorial.

>The gcloud run deploy --source . seems to rely on .gitignore file to avoid copying unwanted files to the 
deployment package (but not .dockerignore :-( ).

## References

* **Google Cloud Quickstart:** [Build and deploy a Python (Gradio) web app to Cloud Run](https://docs.cloud.google.com/run/docs/quickstarts/build-and-deploy/deploy-python-gradio-service)
