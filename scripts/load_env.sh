#!/usr/bin/env bash
# Loads environment variables from a .env file into the current process environment.
# Use this in an Xcode Scheme Run pre-action or a Run Script build phase.

set -euo pipefail

ENVFILE="${PROJECT_DIR:-$(pwd)}/.env"

if [ ! -f "$ENVFILE" ]; then
  echo "No .env found at $ENVFILE"
  exit 0
fi

echo "Loading environment variables from $ENVFILE"

# Read the file line by line, ignore comments and blank lines
while IFS= read -r line || [ -n "$line" ]; do
  # Trim leading/trailing whitespace
  line="$(echo "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  # Skip comments and empty lines
  if [[ -z "$line" || "$line" == \#* ]]; then
    continue
  fi
  # Only accept KEY=VALUE pairs
  if ! echo "$line" | grep -q '='; then
    continue
  fi
  key="$(echo "$line" | cut -d '=' -f 1)"
  value="$(echo "$line" | cut -d '=' -f 2- )"
  # Export the variable for the launched process
  export "$key=$value"
done < "$ENVFILE"

echo "Environment variables exported."
