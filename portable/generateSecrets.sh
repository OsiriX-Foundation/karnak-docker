#!/bin/bash

# Exit script immediately on any error
set -euo pipefail

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

# Check if Docker is installed and executable
if ! command -v docker &> /dev/null; then
  echo "Docker is required but not installed. Install it from: https://docs.docker.com/install/"
  exit 1
fi

# Define variables for secret files and path
secretfiles=("karnak_postgres_password")
secretpath="secrets"
secretKarnakLoginPassword="karnak_login_password"

echo "Generating secrets..."
# Create secrets directory if it doesn't exist
mkdir -p "$secretpath"

# Function to generate random base64 string cross-platform
generate_random_base64() {
    case "$(uname -s)" in
        Darwin)
            # macOS
            dd if=/dev/urandom bs=1 count=32 2>/dev/null | base64
            ;;
        MINGW*|CYGWIN*)
            # Windows - use built-in certutil as alternative
            certutil -f -encodehex -f NUL out.tmp 32 > nul 2>&1 || true
            certutil -encode -f out.tmp out.b64 > nul 2>&1 || true
            # Clean up temporary files and format output
            head -n 2 out.b64 | tail -n 1
            rm -f out.tmp out.b64 2>/dev/null || true
            ;;
        Linux|*)
            # Linux and others
            dd if=/dev/urandom bs=1 count=32 2>/dev/null | base64 -w 0
            ;;
    esac
}

# Generate random secrets
for secretfile in "${secretfiles[@]}"; do
    generate_random_base64 > "$(resolve_path "$secretpath/$secretfile")"
done

# Prompt the user to set the web portal password
while true; do
  # First password prompt (silent)
  # Use stty to handle terminal settings in a cross-platform way
  stty -echo
  printf "Enter the web portal password: "
  read -r firstPasswordEntry
  stty echo
  printf "\n"

  # Confirm password prompt (silent)
  stty -echo
  printf "Confirm the password: "
  read -r secondPasswordEntry
  stty echo
  printf "\n"

  if [[ "$firstPasswordEntry" == "$secondPasswordEntry" ]]; then
    printf "%s" "$firstPasswordEntry" > "$(resolve_path "$secretpath/$secretKarnakLoginPassword")"
    chmod 600 "$(resolve_path "$secretpath/$secretKarnakLoginPassword")" # Restrict file permissions
    echo "The password for the Karnak web portal has been set successfully."
    break
  else
    echo "The passwords do not match. Please try again."
  fi
done