#!/bin/bash

# Exit script immediately on any error
set -euo pipefail

# Check if Docker is installed and executable
if ! command -v docker &> /dev/null; then
  echo "Docker is required but not installed. Install it from: https://docs.docker.com/install/"
  exit 1
fi

# Define variables for secret files and path
secretfiles=("karnak_postgres_password")
secretpath="secrets/"
secretKarnakLoginPassword="karnak_login_password"

echo "Generating secrets..."
# Create secrets directory if it doesn't exist
mkdir -p "$secretpath"

# Pull the busybox Docker image to use for generating secrets
docker pull busybox

# Generate random secrets
for secretfile in "${secretfiles[@]}"; do
  docker run --rm busybox sh -c "dd if=/dev/urandom bs=1 count=32 2>/dev/null | base64" > "$secretpath/$secretfile"
done

# Prompt the user to set the web portal password
while true; do
  # First password prompt (silent)
  read -rsp "Enter the web portal password: " firstPasswordEntry
	echo
  # Confirm password prompt (silent)
  read -rsp "Confirm the password: " secondPasswordEntry
	echo

  if [[ "$firstPasswordEntry" == "$secondPasswordEntry" ]]; then
    echo "$firstPasswordEntry" > "$secretpath/$secretKarnakLoginPassword"
    chmod 600 "$secretpath/$secretKarnakLoginPassword" # Restrict file permissions
    echo "The password for the Karnak web portal has been set successfully."
    break
	else
    echo "The passwords do not match. Please try again."
	fi
done