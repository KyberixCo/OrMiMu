#!/bin/bash
set -e

# Check for Homebrew
if ! command -v brew &> /dev/null; then
    echo "Homebrew is required but not installed. Aborting."
    exit 1
fi

# Install dependencies
if ! command -v xcodegen &> /dev/null; then
    echo "Installing XcodeGen..."
    brew install xcodegen
fi

if ! command -v swiftlint &> /dev/null; then
    echo "Installing SwiftLint..."
    brew install swiftlint
fi

# Generate project
echo "Generating Xcode project..."
xcodegen generate

echo "Done!"
