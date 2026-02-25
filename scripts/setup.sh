#!/bin/bash
set -e

# Function to check if a command exists
command_exists() {
    type "$1" &> /dev/null
}

echo "Starting setup..."

# Check if Homebrew is installed
if ! command_exists brew; then
    echo "Error: Homebrew is required but not found. Please install it from https://brew.sh/"
    # Continue anyway if xcodegen is present, just warn
    if ! command_exists xcodegen; then
        exit 1
    fi
fi

# Install XcodeGen if missing
if ! command_exists xcodegen; then
    echo "Installing XcodeGen..."
    brew install xcodegen
else
    echo "XcodeGen found."
fi

# Install SwiftLint if missing
if ! command_exists swiftlint; then
    echo "Installing SwiftLint..."
    brew install swiftlint
else
    echo "SwiftLint found."
fi

echo "Generating project..."
xcodegen generate

echo "Setup complete! Open OrMiMu.xcodeproj"
