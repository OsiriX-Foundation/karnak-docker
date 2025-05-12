#!/bin/bash
set -e

# Define paths
COMPOSE_BIN="./docker/docker-compose"
COMPOSE_FILE="./docker-compose.yml"
SECRETS_DIR="./secrets"
GENERATE_SECRETS_SCRIPT="./generateSecrets.sh"

# Define helper function for downloading docker-compose
download_compose() {
    echo "Docker Compose binary not found. Downloading..."
    mkdir -p "$(dirname "$COMPOSE_BIN")"

    # Fetch the latest release from GitHub
    latest_release=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep -o '"tag_name": "[^"]*' | cut -d'"' -f4)

    if [ -z "$latest_release" ]; then
        echo "Error: Could not fetch the latest release of Docker Compose. Please check your internet connection."
        exit 1
    fi

    echo "Latest Docker Compose version: $latest_release"

    # Normalize OS name and architecture
    os_name=$(uname -s | tr '[:upper:]' '[:lower:]')  # Convert to lowercase (e.g., linux)
    arch_name=$(uname -m)                             # Architecture (e.g., x86_64)
    # Handle Apple Silicon (M1/M2) architecture
    if [ "$arch_name" = "arm64" ]; then
        arch_name="aarch64"
    fi

    # Download Docker Compose for the current platform
    echo "Downloading: https://github.com/docker/compose/releases/download/${latest_release}/docker-compose-${os_name}-${arch_name}"
    curl -L "https://github.com/docker/compose/releases/download/${latest_release}/docker-compose-${os_name}-${arch_name}" -o "$COMPOSE_BIN"
    chmod +x "$COMPOSE_BIN"
    echo "Docker Compose downloaded successfully: $COMPOSE_BIN"
}

# Ensure Docker Compose binary exists
if [ ! -f "$COMPOSE_BIN" ]; then
    download_compose
fi

# Helper function to display usage
usage() {
    echo "Usage: $0 {start|stop|clean}"
    echo
    echo "start - Start the application (in a detached process). Generates secrets if the secrets folder is missing or empty."
    echo "stop  - Stop the application"
    echo "clean - Stop the application, remove all volumes, and delete the secrets folder"
    echo
    exit 1
}

# Check if the first argument is supplied
if [ $# -eq 0 ]; then
    usage
fi

# Define actions
case "$1" in
    start)
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
        USER_ID=$(id -u) GROUP_ID=$(id -g) "$COMPOSE_BIN" -f "$COMPOSE_FILE" up -d
        echo "Application started."
        ;;
    
    stop)
        echo "Stopping the application..."
        "$COMPOSE_BIN" -f "$COMPOSE_FILE" down
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
        "$COMPOSE_BIN" -f "$COMPOSE_FILE" down --volumes
        echo "All volumes and data have been deleted."

        # Remove the secrets folder if it exists
        if [ -d "$SECRETS_DIR" ]; then
            echo "Removing the secrets folder..."
            rm -rf "$SECRETS_DIR"
            echo "Secrets folder removed."
        else
            echo "Secrets folder does not exist. Skipping."
        fi
        ;;
    
    *)
        echo "Invalid option!"
        usage
        ;;
esac