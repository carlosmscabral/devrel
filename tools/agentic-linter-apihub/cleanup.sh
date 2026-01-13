#!/bin/bash
# Copyright 2026 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


# cleanup.sh
# Deletes the API from API Hub

set -e

# Load environment variables if .env exists
if [[ -f .env ]]; then
  source .env
fi

# Determine API_ID based on argument (matching deploy.sh)
if [[ "$1" == "legacy" ]]; then
  echo "🧹 Cleaning up Legacy (Human-Centric) Spec..."
  API_ID="human-centric-orders-api"
elif [[ "$1" == "medium" ]]; then
  echo "🧹 Cleaning up Medium Spec..."
  API_ID="proactive-orders-api"
else
  # Default or explicit 'agentic'
  echo "🧹 Cleaning up Agentic Spec..."
  API_ID="agentic-orders-api"
fi

# Check required variables
if [[ -z "${PROJECT_ID}" ]]; then
  echo "Error: PROJECT_ID is not set."
  exit 1
fi


if [[ -z "${API_HUB_REGION}" ]]; then
  echo "Error: API_HUB_REGION is not set."
  exit 1
fi

echo "Authenticating..."
TOKEN="$(gcloud auth print-access-token)"

# Ensure apigeecli is installed (still needed for API Hub)
if ! command -v apigeecli &> /dev/null; then
    echo "Installing apigeecli..."
    curl -s https://raw.githubusercontent.com/apigee/apigeecli/main/downloadLatest.sh | bash
    export PATH="${PATH}:${HOME}/.apigeecli/bin"
fi

delete_api_from_hub() {
  local api_id="$1"
  echo "Deleting API ${api_id} from API Hub..."
  if ! apigeecli apihub apis delete \
      --id "${api_id}" \
      --force true \
      -r "${API_HUB_REGION}" \
      -o "${PROJECT_ID}" \
      -t "${TOKEN}"; then
      echo "API ${api_id} might already be deleted."
  fi
}

echo "Starting Cleanup"
echo "================================================="

# 1. Delete from API Hub
delete_api_from_hub "${API_ID}"

echo "================================================="
echo "Cleanup Complete"
echo "================================================="
