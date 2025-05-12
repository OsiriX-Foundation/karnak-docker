#!/bin/bash
set -e

# Define paths
COMPOSE_BIN="./docker/docker-compose"
COMPOSE_FILE="./docker-compose.yml"
SECRETS_DIR="./secrets"
GENERATE_SECRETS_SCRIPT="./generateSecrets.sh"

# Define binary suffix based on OS
case "$(uname -s)" in
    MINGW*|CYGWIN*)
        # Define the correct binary path with suffix
        COMPOSE_BIN="${COMPOSE_BIN}.exe"
        ;;
esac


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

# Function to download Docker Compose
download_compose() {
    echo "Docker Compose binary not found. Downloading..."
    mkdir -p "$(dirname "$COMPOSE_BIN")"

    # Fetch the latest release from GitHub
    latest_release=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep -o '"tag_name": "[^"]*' | cut -d'"' -f4)

    if [ -z "$latest_release" ]; then
        echo "Error: Could not fetch the latest release of Docker Compose."
        exit 1
    fi

    echo "Latest Docker Compose version: $latest_release"

    # Normalize OS name and architecture
    case "$(uname -s)" in
        MINGW*|CYGWIN*)
            os_name="windows"
            ;;
        *)
            os_name=$(uname -s | tr '[:upper:]' '[:lower:]')  # Convert to lowercase
            ;;
    esac

    arch_name=$(uname -m)  # Architecture (e.g., x86_64)
    if [ "$arch_name" = "arm64" ]; then
        arch_name="aarch64"  # Handle Apple Silicon (M1/M2) architecture
    fi

    # Download Docker Compose for the current platform with correct suffix
    echo "Downloading: https://github.com/docker/compose/releases/download/${latest_release}/docker-compose-${os_name}-${arch_name}${binary_suffix}"
    curl -L "https://github.com/docker/compose/releases/download/${latest_release}/docker-compose-${os_name}-${arch_name}${binary_suffix}" -o "$COMPOSE_BIN"
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

        # Windows Git Bash does not support `id`, so handle it gracefully
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
        echo "All volumes and data have been deleted."

        # Remove the data folder if it exists
        if [ -d "$SECRETS_DIR" ]; then
            echo "Removing the data folder..."
            rm -rf "$SECRETS_DIR"
            echo "Data folder removed."
        fi

        # Remove the secrets folder if it exists
        if [ -d "./data" ]; then
            echo "Removing the secrets folder..."
            rm -rf "./data"
            echo "Secrets folder removed."
        fi
        ;;
    
    *)
        usage
        ;;
esac