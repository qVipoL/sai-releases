#!/bin/bash

# Script to copy app release and update signatures in latest.json

set -e  # Exit on error

# Define paths
APP_DIR="releases/latest/app"
DOWNLOAD_DIR="releases/latest/download"
APP_FILE="sales-ai.app.tar.gz"
SIG_FILE="sales-ai.app.tar.gz.sig"
JSON_FILE="$DOWNLOAD_DIR/latest.json"

# Step 1: Copy the tar.gz file
echo "Copying $APP_FILE to $DOWNLOAD_DIR..."
cp "$APP_DIR/$APP_FILE" "$DOWNLOAD_DIR/"
echo "✓ File copied successfully"

# Step 2: Read the signature content
echo "Reading signature from $SIG_FILE..."
SIGNATURE=$(cat "$APP_DIR/$SIG_FILE")
echo "✓ Signature read successfully"

# Step 3: Update the JSON file with the new signature
echo "Updating signatures in $JSON_FILE..."

# Use jq to update both darwin platforms' signatures
if command -v jq &> /dev/null; then
    # Using jq (preferred method)
    jq --arg sig "$SIGNATURE" \
       '.platforms["darwin-x86_64"].signature = $sig | 
        .platforms["darwin-aarch64"].signature = $sig' \
       "$JSON_FILE" > "$JSON_FILE.tmp" && mv "$JSON_FILE.tmp" "$JSON_FILE"
    echo "✓ Signatures updated successfully using jq"
else
    # Fallback: Using Python
    python3 << EOF
import json

with open("$JSON_FILE", "r") as f:
    data = json.load(f)

signature = """$SIGNATURE"""

data["platforms"]["darwin-x86_64"]["signature"] = signature
data["platforms"]["darwin-aarch64"]["signature"] = signature

with open("$JSON_FILE", "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")

print("✓ Signatures updated successfully using Python")
EOF
fi

echo ""
echo "Release update completed successfully!"
echo "- Copied: $APP_FILE"
echo "- Updated signatures in: $JSON_FILE"

