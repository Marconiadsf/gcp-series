# Google Cloud Run Experiments

This repository contains a series of experiments and demo applications to explore development with Google Cloud Run.

## Description of Demo Applications

- [DemoApp-01](/DemoApp-01): Local deployment example to Google Cloud Run using the `gcloud` command-line tool.
- [DemoApp-02](/DemoApp-02): Local deployment example to Google Cloud Run using scripts to automate the process.

## How to Use This Repository

Each demo application is contained in its own folder (e.g., DemoApp-01, DemoApp-02).

### 1. Prerequisites
Before starting, ensure your local environment has the following installed:
- Docker (must be running)
- VSCode
- VSCode Extension: "Remote - Containers" (or "Dev Containers")
- Git (Optional)

Use VSCode to start a new terminal:
- Go to: Terminal → New Terminal
	- It may open in a path like: C:\Users\YourName\ (windows) or ~/ or /home/your_user (Mac/Linux)
	
- Create a new folder for this repository and navigate into it:
	- Windows/Linux:
		```bash
		mkdir gcp-series
		cd gcp-series
		```
### 2. Getting the sources
	You can clone this repository (2.1) and follow instrutions to set it up or just download a docker file of your preference (2.2) and run it (easier). 

#### 2.1 Git clone way...
If you have Git installed, you can clone this repository using Git:
```bash
git clone https://github.com/Marconiadsf/gcp-series.git
```
Now cd into the gcp-series folder for the unzipped files:
```bash
cd gcp-series
````
Check the folder structure to verify the files are there:
```bash
ls
```

You should see the folders DemoApp-01, DemoApp-02, the files: Dockerfile1.dev, Dockerfile2.dev, Dockerfile, and requirements.txt.

> ℹ️ Note: Dockerfile1.dev and Dockerfile2.dev are designed for your local development environment (including tooling like Git and SDKs), whereas the standard Dockerfile inside each app folder is optimized for the final production deployment on Cloud Run if appliable.

#### 2.2 Downloading only the Dockerfile

Alternatively, you can download only the Dockerfile1.dev or Dockerfile2.dev (see 3.1 and 3.2 for choosing the best one for your case) for the gcp-series folder (and no Git is required).

> ⚠️ Make sure Docker is running on your machine.

Inspect the .dev docker file of your choice to see what is being installed in the development container.

In the Terminal run:

```bash
docker build -f Dockerfilex.dev -t gcp-series-dev-container .
```
substituting x by the number of the file you`ve downloaded.

This builds a generic development image based on Python 3.10-slim, pre-installed with the GCloud SDK and necessary dependencies.
After the build is complete, you can run the container.

### 3. Run the container

You can now bring up a development container in two ways:

### 3.1. With mapped folders (⚠️ Not recommended)

You can run a container mapping a path in the host machine to a path in the container. File alterations you make in the container will be written to the host.
It makes file editing in host handy, however that also means file system integration overhead, which can make some build process and source downloading slower.
If you choose to map folders you can:
-

Run the container interactively, mapping the current folder, and opening port 8080:
```bash
docker run -it -p 8080:8080 -v ${PWD}:/workspace gcp-series-dev-container bash
```
Add the local folder to VSCode workspace and you are ready to go.
You may notice the terminal changed to something like `root@123alpha56:/workspace#`. That`s the container shell.
If you run ls you may see the folders DemoApp-01, DemoApp-02, the files: Dockerfile.dev, Dockerfile, and requirements.txt

**2. No mapped folders (ℹ️ Best!)**

If you don't want to map the folders and keep it only inside the container (but you need Dockerfile.dev and requirements.txt 
beforehand), you can just run:

```bash
docker run -it -p 8080:8080  gcp-series-dev-container bash	
```

You may notice the terminal changed to something like `root@123alpha56:/workspace#`. That`s the container shell.
However, if you run ls you may see only requirements.txt
ou can open the folder in VSCode using the "Remote - Containers" extension:

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
		
#### 1. Copy the files from your host to the container using Docker cp command:
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

