# Google Cloud Run Experiments

This repository contains a series of experiments and demo applications to explore development with Google Cloud Run.

## Description of Demo Applications

* **DemoApp-01:** Local deployment example to Google Cloud Run using the `gcloud` command-line tool.
* **DemoApp-02:** Local deployment example to Google Cloud Run using scripts to automate the process.

## How to Use This Repository

Each demo application is contained in its own folder (e.g., DemoApp-01, DemoApp-02).

### 1. Prerequisites

Before starting, ensure your local environment has the following installed:
* **Docker** (Must be running)
* **VSCode**
* **VSCode Extension:** "Dev Containers" (formerly "Remote - Containers")
* **Git** (Optional, depending on your chosen workflow)

#### Setup your terminal
Use VSCode to start a new terminal:
1.  Go to: **Terminal** → **New Terminal**
2.  Create a working directory and navigate into it:

    ```bash
    mkdir gcp-series
    cd gcp-series
    ```

### 2. Getting the Sources & Building

You can choose between two workflows. **Option B** is generally easier for quick testing, while **Option A** is better if you plan to edit code extensively on your local machine.

#### Option A: The "Mapped" Workflow (Standard)
*Best for: Editing files locally using your host tools.*

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/Marconiadsf/gcp-series.git
    cd gcp-series
    ```
2.  **Verify files:** Run `ls` (or `dir` on Windows) to ensure `Dockerfile.dev` is present.
3.  **Build the container:**
    ```bash
    docker build -f Dockerfile.dev -t gcp-series-dev-container .
    ```

> **ℹ️ Note:** `Dockerfile.dev` is designed for your local development environment (includes Git, SDKs, etc.), whereas the standard `Dockerfile` inside each app folder is optimized for production Cloud Run deployment.

#### Option B: The "Isolated" Workflow (No Git Required Locally)
*Best for: Quick tests without installing Git on your host.*

1.  **Download the Dockerfile:** Download **only** the `Dockerfile-isolated.dev` (previously `Dockerfile2.dev`) from the repo and place it in your `gcp-series` folder.
2.  **Inspect the file:** Check the file content to understand what tools are being installed.
3.  **Build the container:**
    ```bash
    docker build -f Dockerfile-isolated.dev -t gcp-series-dev-container .
    ```

This builds an image that will clone the repository *inside* the container automatically.

---

### 3. Run the Container

Choose the method that matches the Build Option you selected above.

#### 3.1. With Mapped Folders (Matches Option A)
This maps your current local folder to the container. Changes made inside the container are saved to your local machine.

1.  Run the container interactively, mapping port 8080:
    ```bash
    docker run -it -p 8080:8080 -v ${PWD}:/workspace gcp-series-dev-container bash
    ```
    *(Note: On Windows PowerShell, use `${PWD}`; on Command Prompt, use `%cd%`)*

2.  You will see a prompt like `root@123alpha56:/workspace#`. You are now inside the container.
3.  Open VSCode, add the current folder to your workspace, and you are ready to go.

#### 3.2. No Mapped Folders (Matches Option B)
This runs a completely isolated container. The source code exists only inside the container.

> **⚠️ Warning:** Because this method does not map folders, if you delete the container, **any code changes you made will be lost** unless you push them to Git from within the container.

1.  Run the container:
    ```bash
    docker run -it -p 8080:8080 gcp-series-dev-container bash
    ```
2.  **Attach VSCode to the Container:**
    * Click the **Remote - Containers** (or Dev Containers) icon in the VSCode sidebar.
    * Right-click the running container (`gcp-series-dev-container`).
    * Select **"Attach to Container"**.
3.  A new window will open. If the workspace isn't loaded, go to **File → Open Folder** and select `/workspace`.
