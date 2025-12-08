# Google Cloud Run Experiments

This repository contains a series of experiments and demo applications to explore development with Google Cloud Run.

## Description of Demo Applications

- [DemoApp-01](/DemoApp-01): Local deployment example. This is a simple demo application that demonstrates local deployment to Google Cloud Run using the `gcloud` command-line tool.
- [DemoApp-02](/DemoApp-02): Local deployment with script-based automation. This demo application shows how to use scripts to automate the deployment process.

## How to Use This Repository
Each demo application is contained in its own folder (e.g., DemoApp-01, DemoApp-02).
Start by installing Docker, VSCode, Git (optional) in your local development environment.

Start VSCode, install the "Remote - Containers" extension.
Use VSCode to start a new terminal:
- Go to: Terminal → New Terminal
	- It may open in a path like: C:\Users\YourName\
	
- Create a new folder for this repository and navigate into it:
	- Windows/Linux:
		```bash
		mkdir gcp-series
		cd gcp-series
		``` 
	
If you have Git installed, you can clone this repository using Git:
	
```bash
git clone https://github.com/Marconiadsf/gcpseries.git
```

If you don't want to install Git, you can also download the repository as a ZIP file and extract it.
Unzip the file into the gcp-series folder you created above.
Now cd into the gcp-series folder for the unzipped files:

```bash
cd gcp-series
````

Check the folder structure to verify the files are there:

```bash
ls
```

You should see the folders DemoApp-01, DemoApp-02, the files: Dockerfile.dev, Dockerfile, and requirements.txt.
Dockerfile.dev is used to create a development container with all the necessary tools installed.
> ⚠️ Make sure Docker is running on your machine.
Inspect the Dockerfile.dev to see what is being installed in the development container.

In the Terminal run:

```bash
docker build -f Dockerfile.dev -t gcp-series-dev-container .
```

This will build the development container image with Python 3.10-slim, Git, gcloud SDK, and other tools, copy
the requirements.txt file, and install the required Python packages.
After the build is complete, you can run the container.

For local testing and development, you can run the container interactively, mapping the current folder, and opening port 8080:

```bash
docker run -it -p 8080:8080 -v ${PWD}:/workspace gcp-series-dev-container bash
```
	
If you don't want to map the folders and keep it only inside the container (but you need Dockerfile.dev and requirements.txt 
beforehand), you can just run:

```bash
docker run -it -p 8080:8080  gcp-series-dev-container bash	
```

If you mapped folders of container to host you can open the folder in VSCode directly from your host machine as a workspace.
Keep the terminal open after running the container, you are now inside the container.
If you run ls you may see the folders DemoApp-01, DemoApp-02, the files: Dockerfile.dev, Dockerfile, and requirements.txt

If you kept it only inside the container, you can open the folder in VSCode using the "Remote - Containers" extension:

Click the "Remote - Containers" icon in the left sidebar
Search for the just created container and click "Attach in New Window"
The new window may have /workspace as the current workspace.
You can also set it manually by going to File -> Open Folder and selecting /workspace
In the menu select the folder you want to open, within the container, e.g., /workspace.
		
In the new window, go to: Terminal -> New Terminal
You are now inside the container terminal. You can see the current folder is /workspace in the line prompt.
However if you run ls, you may see only Dockerfile, and requirements.txt, as they were copied in the process of building
the container. However the demo application folders are missing. It is because the container does not have access to your 
host files.
		
You can:
		
#### 1. Copy the files from your host to the container using docker cp command:
Open a new terminal in your host machine (not inside the container) and navigate to the gcp-series folder you created before.
Run the command:

```bash
docker cp DemoApp-01 <container_id>:/workspace/DemoApp-01
docker cp DemoApp-02 <container_id>:/workspace/DemoApp-02
```

Replace <container_id> with the actual container ID or name. You can find it by running `docker ps` in your host terminal.
After copying the folders, go back to the container terminal and run ls again. You should now see the DemoApp-01 and DemoApp-02 folders.
		
#### 2. Use Git inside the container to clone the repository again:
			
```bash
git clone https://github.com/Marconiadsf/gcp-series.git
```
			
Now cd into the gcp-series folder for the cloned files:

```bash
cd gcp-series
```
			
Check the folder structure to verify the files are there:

```bash
ls
```

You should see the folders DemoApp-01, DemoApp-02, the files: Dockerfile.dev, Dockerfile, and requirements.txt
Either way, you can now navigate to each demo application folder and follow the specific instructions in their README.md files.

