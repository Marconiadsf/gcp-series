# DemoApp-01 : Local deployment example
This is a simple demo application to illustrate local deployment to Google Cloud Run using the `gcloud` command-line tool.


## Prerequisites

**Follow README.md in the root directory for setting up your environment: This will give you the necessary enviroinment
to run the demo applications, including installing Docker, VSCode, git (optional), and setting up the development container.**

## Running the Demo Application

### 1. Understanding the Application
The demo application is a simple gradio example that creates a web interface for sending audio files.
It uses the gradio library to create the web interface and handle file uploads.
The main application code is in the `app.py` file.
#### 1.1 File structure
- `src/`: This directory contains the source code for the demo application.
	- Inside the `src/` directory, you will find:
	- `app.py`: The main application code that defines the gradio interface.
	- `requirements.txt`: Lists the Python dependencies required for the application.
- `.gitignore`: Specifies files and directories to be ignored by git (if using version control).
- `env_variables_model.sh`: A template shell script to set environment variables for GCP deployment.
- `README.mk`: This file you are reading now, which provides instructions on how to run and deploy the application.
		
You can run the applycation locally in the dev container or deploy it to Google Cloud Run.

### 2. Building and Running the Application Locally
In the dev container terminal, navigate to the DemoApp-01 directory:
		```
		cd DemoApp-01
		```
The dev container built with the Dockerfile.dev already has the dependencies installed from requirements.txt.
You can run the application directly using Python:
		```
		python app.py
		```
This will start the gradio application, and you should see output indicating that the server is running, along with a 
local URL (e.g., `http://127.0.0.1:8080`). You can open this URL in your web browser to interact with the application.

### 3. Deploying to Google Cloud Run
#### 3.1 Setting Up Environment Variables
To deploy the application to Google Cloud Run, follow these steps:
Make a copy of env_variables_model.sh naming it env_vars.sh:
		```
		cp env_variables_model.sh env_vars.sh
		```
		
This pratice is to avoid leaking sensitive information if you share the code publicly (as long as the .gitignore file includes env_vars.sh).

Open env_vars.sh in VSCode or you favorite text editor	and follow the instructions to set your GCP project details. 
Only GCP_PROJECT_ID, GCP_PROJECT_REGION, and GCP_BILLING_ACCOUNT_ID really need to be changed (as they are probably blank), 
the other variables can be left as is for this demo.

Alternatively, you can create blank env_vars.sh file, and here is the content you need to put in:

	env_vars.sh: 
		```
		# Edit the following variables with your own values:

		GCP_PROJECT_ID="your-unique-gcp-project-id"
		GCP_PROJECT_REGION="your-preferred-region" 

		# You can keep the following variables as is:
		
		GCP_PROJECT_NAME="DemoApp-01"
		GCP_PROJECT_PREFIX="demoapp-01"
		TAG="v1" 

		# Don`t touch. It`s and art!		
		
		GCP_PROJECT_REPOSITORY="$GCP_PROJECT_PREFIX-repo" 
		GCP_IMAGE_NAME="$GCP_PROJECT_PREFIX-image" 
		GCP_IMAGE="$GCP_PROJECT_REGION-docker.pkg.dev/$GCP_PROJECT_ID/$GCP_PROJECT_REPOSITORY/$GCP_IMAGE_NAME:$TAG" 
		 
		```

Source the env_variables.sh file to set the environment variables in your terminal:
		```
		source env_vars.sh
		```
#### 3.2 Setting Up Google Cloud SDK
Make sure you are logged in to your Google Cloud account using the gcloud CLI:
		```
		gcloud auth login
		```
Especifying the project to work with:
Create the project:
			```
				gcloud projects create $GCP_PROJECT_ID --name="$GCP_PROJECT_NAME"
			```
Select the project:
	```	
		gcloud config set project $GCP_PROJECT_ID
	```
	
Verify if billing is enabled for your project. If not, follow instructions to enable in Google CLI (not in this scope).
You can list your billing accounts with the following command:
		
	```
		gcloud beta billing accounts list
	```
		
Then link the billing account to your project:

	```
		gcloud beta billing projects link $GCP_PROJECT_ID --billing-account=<billing-account-id>

	```

#### 3.3 Enabling Required APIs

Enable the necessary APIs for Cloud Run and Artifact Registry:
		```
			gcloud services enable run.googleapis.com cloudbuild.googleapis.com
		```

#### 3.4 Granting Permissions to the Cloud Build Service Account
	
	<todo: replace SERVICE_ACCOUNT_EMAIL_ADDRESS with the actual service account email address.>
	<explain how to find it if needed.>
	<explain why/when this is needed.>	

#### 3.5 Deploying the Application

From the DemoApp-01 directory, cd into src folder:
		```
		cd src
		```

Deploy the application to Cloud Run using the following command:

		```
			gcloud run deploy --source .
		```
It may require to answer some prompts after this command, to set some things like:
- service name: set one or press enter to keep default
- additional APIs: answer y if prompted
- region: the same you plalnned to use in env_vars.sh
- public access: answer y to allow unauthenticated invocations (recommended for this demo purpose) 

After the deployment is complete, you will see a URL where your application is hosted. You can open this URL 
in your web browser to access the deployed application.

Congratulations! You have successfully deployed the DemoApp-01 application to Google Cloud Run.

#### 3.6 Cleaning Up

Before jumping into the next DemoApp you may want to to delete all the resources created in this DemoApp-01:

		```
			gcloud run services delete <service-name> --region=$GCP_PROJECT_REGION
			gcloud projects delete $GCP_PROJECT_ID
		```
Replace `<service-name>` with the name of your Cloud Run service (the one asked when you ran gcloud run deploy...). 


## Comments and References

As the standart Gradio examples and my tries to deploy from Google Console had failed, the setup and deployment process is heavly 
based on the following Google Cloud CLI tutorial:
- [Quickstart: Build and deploy a Python (Gradio) web app to Cloud Run] (https://docs.cloud.google.com/run/docs/quickstarts/build-and-deploy/deploy-python-gradio-service?hl=pt-br#local-shell)
Next DemoApp-02 we will make some improovements to the deployment enviroinment using all variables set in env_vars.sh file.
As a matter of information, the gcloud run deploy --source . seems to rely on .gitignore file to avoid copying unwanted files to the 
deployment package (but not .dockerignore :-( ).
