# DemoApp-02 : Local deployment example - Automating Google Cloud Run deployment.
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
- `src/`: This directory contains the source code for the demo application, that are:
	- `app.py`: The main application code that defines the gradio interface.
	- `requirements.txt`: Lists the Python dependencies required for the application.
 - 
- `.gitignore`: Specifies files and directories to be ignored by git (if using version control).
- `env_variables_model.sh`: A template shell script to set environment variables for GCP deployment.
- `README.mkd`: This file you are reading now, which provides instructions on how to run and deploy the application.
		
You can run the applycation locally in the dev container or deploy it to Google Cloud Run.

		
### 2. Building and Running the Application Locally
In the dev container terminal, navigate to the DemoApp-02 directory:
		```
		cd DemoApp-02
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
		```
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
#### 3.2 Deploying the GCP Project
		
This time we packed all the deplyment workflow into a script.
Make sure you are in the DemoApp-02 directory.
List your billing information and keep it in hand, qhen the script asks for it.

Then run:

		```
		./deploy_to_gcp.sh
		
		```

The script will source the env_vars.sh file to get the necessary environment variables and then proceed to create the GCP project,
enable required APIs, ask for billing account and finally deploy the application to Cloud Run.
You should see output in the terminal indicating the progress of each step.

It may require to answer some prompts after this command, to set some things like:
- additional APIs: answer y if prompted
- public access: answer y to allow unauthenticated invocations (recommended for this demo purpose) 

After the deployment is complete, you will see a URL where your application is hosted. You can open this URL 
in your web browser to access the deployed application.

Congratulations! You have successfully deployed the DemoApp-01 application to Google Cloud Run.

#### 3.6 Cleaning Up

Before jumping into the next DemoApp you may want to to delete all the resources created in this DemoApp-02:

		```
			./deploy_to_cloud.sh clean
		```
This will delete the Cloud Run service and the GCP project created for this demo.


## Comments and References

- As the standart Gradio examples and my tries to deploy from Google Console had failed, the setup and deployment process is heavly 
based on the following Google Cloud CLI tutorial:
	- [Quickstart: Build and deploy a Python (Gradio) web app to Cloud Run](https://docs.cloud.google.com/run/docs/quickstarts/build-and-deploy/deploy-python-gradio-service?hl=pt-br#local-shell)

- Next DemoApp-02 we will make some improovements to the deployment enviroinment using all variables set in env_vars.sh file.
- As a matter of information, the gcloud run deploy --source . seems to rely on .gitignore file to avoid copying unwanted files to the 
deployment package (but not .dockerignore :-( ).
