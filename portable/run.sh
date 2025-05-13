#!/bin/bash
set -e

# Define paths
PORTABLE_DIR="./docker"
COMPOSE_FILE="./docker-compose.yml"
SECRETS_DIR="./secrets"
GENERATE_SECRETS_SCRIPT="./generateSecrets.sh"

# Define binary paths based on OS
case "$(uname -s)" in
    MINGW*|CYGWIN*)
        DOCKER_BIN="${PORTABLE_DIR}/docker.exe"
        COMPOSE_BIN="${PORTABLE_DIR}/docker-compose.exe"
        DOCKERD_BIN="${PORTABLE_DIR}/dockerd.exe"
        ;;
    *)
        DOCKER_BIN="${PORTABLE_DIR}/docker"
        COMPOSE_BIN="${PORTABLE_DIR}/docker-compose"
        DOCKERD_BIN="${PORTABLE_DIR}/dockerd"
        ;;
esac

# Helper function to display usage
usage() {
    echo "Usage: $0 {start|stop|clean}"
    echo
    echo "start - Start the application (in a detached process). Downloads required binaries if missing."
    echo "stop  - Stop the application"
    echo "clean - Stop the application, remove all volumes, and delete the secrets folder"
    echo
    exit 1
}

# Function to normalize OS and architecture names
get_platform_info() {
    case "$(uname -s)" in
        MINGW*|CYGWIN*)
            OS_NAME="windows"
            BINARY_SUFFIX=".exe"
            ;;
        Darwin)
            OS_NAME="darwin"
            BINARY_SUFFIX=""
            ;;
        *)
            OS_NAME="linux"
            BINARY_SUFFIX=""
            ;;
    esac

    ARCH_NAME=$(uname -m)
    case "$ARCH_NAME" in
        x86_64)
            ARCH_NAME="x86_64"
            ;;
        aarch64|arm64)
            ARCH_NAME="aarch64"
            ;;
        *)
            echo "Unsupported architecture: $ARCH_NAME"
            exit 1
            ;;
    esac
}

# Function to handle OS-specific path resolution (for Windows Git Bash)
resolve_path() {
    case "$(uname -s)" in
        MINGW*|CYGWIN*)
            # Convert paths to Windows format for tools that require it
            printf "%s\n" "$(cygpath -w "$1")"
            ;;
        *)
            printf "%s\n" "$1"
            ;;
    esac
}

# Function to download docker-compose
download_compose() {
    if [ -f "$COMPOSE_BIN" ]; then
        echo "docker-compose already exists"
        return 0
    fi

    mkdir -p "${PORTABLE_DIR}"
    echo "Downloading docker-compose..."
    get_platform_info

    # Get latest release
    local latest_release=$(curl -s "https://api.github.com/repos/docker/compose/releases/latest" | grep -o '"tag_name": "[^"]*' | cut -d'"' -f4)
    if [ -z "$latest_release" ]; then
        echo "Error: Could not fetch the latest release for docker-compose"
        return 1
    fi

    echo "Latest version: $latest_release"
    local download_url="https://github.com/docker/compose/releases/download/${latest_release}/docker-compose-${OS_NAME}-${ARCH_NAME}${BINARY_SUFFIX}"

    echo "Downloading from: $download_url"
    curl -L "$download_url" -o "$COMPOSE_BIN"
    chmod +x "$COMPOSE_BIN"
    echo "docker-compose downloaded successfully"
}

# Function to download docker engine binaries
download_docker_engine() {
    # For Mac, we only need docker binary, not dockerd
    if [ "$OS_NAME" = "darwin" ] && [ -f "$DOCKER_BIN" ]; then
        echo "docker binary already exists"
        return 0
    elif [ "$OS_NAME" != "darwin" ] && [ -f "$DOCKER_BIN" ] && [ -f "$DOCKERD_BIN" ]; then
        echo "docker and dockerd already exist"
        return 0
    fi

    mkdir -p "${PORTABLE_DIR}"
    echo "Downloading docker engine..."
    get_platform_info

    # Get latest version using Docker API
    local latest_version=$(curl -s "https://api.github.com/repos/moby/moby/releases/latest" | grep -o '"tag_name": "[^"]*' | cut -d'"' -f4 | tr -d 'v')
    echo "Latest version: ${latest_version}"

    # Convert OS_NAME for Docker's URL structure
    local docker_os
    case "$OS_NAME" in
        "darwin")
            docker_os="mac"
            ;;
        "windows")
            docker_os="win"
            ;;
        *)
            docker_os="linux"
            ;;
    esac

    local docker_archive="${PORTABLE_DIR}/docker.tgz"
    local download_url="https://download.docker.com/${docker_os}/static/stable/${ARCH_NAME}/docker-${latest_version}.tgz"

    echo "Downloading from: $download_url"
    if ! curl -L "$download_url" -o "$docker_archive"; then
        echo "Failed to download from ${download_url}, trying alternative version..."
        # Try without patch version
        latest_version=$(echo "$latest_version" | cut -d'.' -f1-2).0
        download_url="https://download.docker.com/${docker_os}/static/stable/${ARCH_NAME}/docker-${latest_version}.tgz"
        echo "Trying alternative download: $download_url"
        if ! curl -L "$download_url" -o "$docker_archive"; then
            echo "Error: Failed to download docker engine"
            return 1
        fi
    fi

    tar xzf "$docker_archive" -C "${PORTABLE_DIR}"
    mv "${PORTABLE_DIR}/docker/docker" "$DOCKER_BIN"
    # Only move dockerd on non-Mac systems
    if [ "$OS_NAME" != "darwin" ]; then
        mv "${PORTABLE_DIR}/docker/dockerd" "$DOCKERD_BIN"
        chmod +x "$DOCKERD_BIN"
    fi
    rm -rf "${PORTABLE_DIR}/docker" "$docker_archive"
    chmod +x "$DOCKER_BIN"
    echo "docker engine downloaded successfully"
}

# Function to ensure all binaries exist
ensure_binaries() {
    local missing=0

    if [ ! -f "$DOCKER_BIN" ] || [ ! -f "$DOCKERD_BIN" ]; then
        download_docker_engine || missing=1
    fi

    if [ ! -f "$COMPOSE_BIN" ]; then
        download_compose || missing=1
    fi

    if [ "$missing" -eq 1 ]; then
        echo "Error: Failed to download one or more required binaries"
        exit 1
    fi
}

# Check if the first argument is supplied
if [ $# -eq 0 ]; then
    usage
fi

# Define actions
case "$1" in
    start)
        # Ensure binaries exist before starting
        ensure_binaries

        # Set up portable Docker environment
        export DOCKER_HOST="unix://${PORTABLE_DIR}/docker.sock"
        export PATH="${PORTABLE_DIR}:$PATH"
        export DOCKER_CONFIG="${PORTABLE_DIR}/config"
        export DOCKER_CONTEXT="default"
        export COMPOSE_DOCKER_CLI_BUILD=0

        # Start portable dockerd if not running
        if ! "$DOCKER_BIN" info >/dev/null 2>&1; then
            echo "Starting portable Docker daemon..."
            "$DOCKERD_BIN" --data-root="${PORTABLE_DIR}/data" \
                          --exec-root="${PORTABLE_DIR}/exec" \
                          --pidfile="${PORTABLE_DIR}/docker.pid" \
                          --host="unix://${PORTABLE_DIR}/docker.sock" &
            # Wait for daemon to start
            sleep 5
        fi

        # Check if the secrets folder exists and contains files
        if [ ! -d "$SECRETS_DIR" ] || [ -z "$(ls -A "$SECRETS_DIR" 2>/dev/null)" ]; then
            echo "Secrets folder is missing or empty. Generating secrets..."
            chmod +x "$GENERATE_SECRETS_SCRIPT"
            if [ -x "$GENERATE_SECRETS_SCRIPT" ]; then
                "$GENERATE_SECRETS_SCRIPT"
                echo "Secrets generated successfully."
            else
                echo "Error: Secrets generation script ($GENERATE_SECRETS_SCRIPT) not found."
                exit 1
            fi
        else
            echo "Secrets folder exists and contains files."
        fi

        echo "Create the data folders mapped for logs and db (if it doesn't exist)"
        mkdir -p ./data/karnak-db-data
        mkdir -p ./data/karnak_logs
        echo "Starting the application in a detached mode..."

        # Handle user/group IDs
        if command -v id &>/dev/null; then
            USER_ID=$(id -u)
            GROUP_ID=$(id -g)
        else
            echo "Warning: 'id' command not found. Defaulting user and group IDs to 1000."
            USER_ID=1000
            GROUP_ID=1000
        fi

        USER_ID=$USER_ID GROUP_ID=$GROUP_ID "$COMPOSE_BIN" -f "$(resolve_path "$COMPOSE_FILE")" up -d
        echo "Application started."
        ;;
    
    stop)
        echo "Stopping the application..."
        "$COMPOSE_BIN" -f "$(resolve_path "$COMPOSE_FILE")" down

        # Stop the portable Docker daemon if running
        if [ -f "${PORTABLE_DIR}/docker.pid" ]; then
            echo "Stopping portable Docker daemon..."
            kill $(cat "${PORTABLE_DIR}/docker.pid")
            rm -f "${PORTABLE_DIR}/docker.pid"
        fi
        echo "Application stopped."
        ;;
    
    clean)
        echo "WARNING: This will stop the application, DELETE ALL VOLUMES (including any persistent data), AND REMOVE THE SECRETS FOLDER."
        read -p "Are you sure you want to proceed? (y/N): " confirm
        if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
            echo "Clean action canceled."
            exit 0
        fi

        echo "Stopping the application and cleaning up volumes..."
        "$COMPOSE_BIN" -f "$(resolve_path "$COMPOSE_FILE")" down --volumes

        # Stop the portable Docker daemon if running
        if [ -f "${PORTABLE_DIR}/docker.pid" ]; then
            echo "Stopping portable Docker daemon..."
            kill $(cat "${PORTABLE_DIR}/docker.pid")
            rm -f "${PORTABLE_DIR}/docker.pid"
        fi

        # Clean up portable Docker data
        echo "Cleaning up portable Docker data..."
        rm -rf "${PORTABLE_DIR}/data"
        rm -rf "${PORTABLE_DIR}/exec"
        rm -f "${PORTABLE_DIR}/docker.sock"

        # Remove the data and secrets folders
        if [ -d "$SECRETS_DIR" ]; then
            echo "Removing secrets folder..."
            rm -rf "$SECRETS_DIR"
        fi
        if [ -d "./data" ]; then
            echo "Removing data folder..."
            rm -rf "./data"
        fi
        echo "Clean up complete."
        ;;

    *)
        usage
        ;;
esac