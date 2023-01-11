#!/bin/bash

# Date created: 2023-01-09
# Author: Kamal Taynaz (@GreatKemo)
# Email: ktaynaz@gmail.com
# License: MIT

# Print help message
print_help() {
  echo "Usage: install_rosetta.sh [-h|--help]"
  echo ""
  echo "This script installs Rosetta 2 on a Mac with Apple Silicon."
}

# Print error message
print_error() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')] Error: $*" >> /Library/Logs/install_rosetta.log
  echo "Error: $*" >&2
  exit 1
}

# Print info message
print_info() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')] Info: $*" >> /Library/Logs/install_rosetta.log
  echo "Info: $*"
}

touch /Library/Logs/install_rosetta.log

#Check if macOS version is 11 or greater
if [[ $(sw_vers -productVersion | awk -F '.' '{print $1}') -lt 11 ]]; then
  print_error "This script requires macOS 11 or greater to run. Please upgrade to macOS 11 or later."
fi

# Evaluate command-line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      print_help
      exit 0
      ;;
    --)
      shift
      break
      ;;
    *)
      print_error "Invalid option: $1"
      print_help
      exit 1
      ;;
  esac
  shift
done

# Check if Mac is using Apple Silicon
if sysctl -n machdep.cpu.brand_string | grep -q "Apple"; then
  # Check if Rosetta 2 is already installed
  if pkgutil --pkgs | grep -q "com.apple.pkg.Rosetta"; then
    print_info "Rosetta 2 is already installed."
    exit 0
  else
    # Set counter to 0
    COUNTER=0
    # Loop until Rosetta 2 is installed or maximum number of attempts is reached
    while [[ $COUNTER -lt 5 ]]; do
      print_info "Installing Rosetta 2 (attempt $((COUNTER+1)) of 5)..."
      # Install Rosetta 2
      softwareupdate --install-rosetta --agree-to-license > /dev/null 2>&1
      # Check if Rosetta 2 was successfully installed
      if pkgutil --pkgs | grep -q "com.apple.pkg.Rosetta"; then
        print_info "Done!"
        # Exit loop
        exit 0
      else
        # Increment counter
        COUNTER=$((COUNTER+1))
      fi
    done
    # Check if Rosetta 2 was not installed
    if ! pkgutil --pkgs | grep -q "com.apple.pkg.Rosetta"; then
      print_error "Failed to install Rosetta 2 after 5 attempts."
      exit 1
    fi
  fi
else
  print_error "This script is for Macs with Apple Silicon. Your Mac does not appear to have an Apple Silicon processor."
  exit 1
fi
