#!/bin/sh

# Xcode Cloud post-clone script
# This runs after the repo is cloned

echo "📦 PushPal - Post Clone"
echo "========================"

# Print environment info
echo "Xcode version: $(xcodebuild -version | head -1)"
echo "macOS version: $(sw_vers -productVersion)"

# Any additional setup can go here
# e.g., install dependencies, generate files, etc.

echo "✅ Post-clone complete"
