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


# deploy.sh
# Triggers the Cloud Build pipeline to lint, register, and deploy the API.
# Usage: ./deploy.sh [legacy|medium]

set -e

# Load environment variables
if [[ -f .env ]]; then
  source .env
else
  echo "Error: .env file not found. Please copy .env.local to .env and fill in your details."
  exit 1
fi

# Default to Agentic spec
SPEC_FILE="agentic/openapi.yaml"

# Check argument
if [[ "$1" == "legacy" ]]; then
  echo "🚀 Deploying Legacy (Human-Centric) Spec (LOW Readiness)..."
  SPEC_FILE="human-centric/openapi.yaml"
  API_ID="human-centric-orders-api"
  DISPLAY_NAME="Human-Centric Orders API"
elif [[ "$1" == "medium" ]]; then
  echo "🚀 Deploying Medium Spec (MEDIUM Readiness)..."
  SPEC_FILE="medium/openapi.yaml"
  API_ID="proactive-orders-api"
  DISPLAY_NAME="Proactive Orders API (Medium Readiness)"
else
  echo "🚀 Deploying Agentic Spec (HIGH Readiness)..."
  API_ID="agentic-orders-api"
  DISPLAY_NAME="Agentic Orders API"
fi

echo "Submitting build for spec: ${SPEC_FILE}"
echo "API ID: ${API_ID}"

gcloud builds submit --config cloudbuild.yaml \
  --substitutions="_PROJECT_ID=${PROJECT_ID},_API_HUB_REGION=${API_HUB_REGION},_SPEC_FILE=${SPEC_FILE},_API_ID=${API_ID},_DISPLAY_NAME=${DISPLAY_NAME}"
