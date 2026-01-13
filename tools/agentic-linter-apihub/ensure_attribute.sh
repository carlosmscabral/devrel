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

# ensure_attribute.sh
# Ensures the 'agentic-readiness' attribute exists in API Hub.

set -e

# Load environment variables if .env exists (for local testing)
if [[ -f .env ]]; then
  source .env
fi

# Required variables (passed from Cloud Build)
PROJECT="${_PROJECT_ID:-$PROJECT_ID}"
LOCATION="${_API_HUB_REGION:-$API_HUB_REGION}"

if [[ -z "${PROJECT}" ]] || [[ -z "${LOCATION}" ]]; then
  echo "Error: PROJECT or LOCATION is missing."
  exit 1
fi

ATTR_ID="agentic-readiness"
API_HUB_ENDPOINT="https://apihub.googleapis.com/v1"

echo "Checking attribute ${ATTR_ID} in ${PROJECT}/${LOCATION}..."

TOKEN="$(gcloud auth print-access-token)"


call_api() {
  local method="$1"
  local url="$2"
  local data="$3"
  
  if [[ -n "${data}" ]]; then
    curl -s -w "\n%{http_code}" -X "${method}" "${url}" \
      -H "Authorization: Bearer ${TOKEN}" \
      -H "Content-Type: application/json" \
      -d "${data}"
  else
    curl -s -w "\n%{http_code}" -X "${method}" "${url}" \
      -H "Authorization: Bearer ${TOKEN}" \
      -H "Content-Type: application/json"
  fi
}

# Check if attribute exists
echo "Checking attribute ${ATTR_ID} in ${PROJECT}/${LOCATION}..."
RESPONSE=$(call_api "GET" "${API_HUB_ENDPOINT}/projects/${PROJECT}/locations/${LOCATION}/attributes/${ATTR_ID}")
HTTP_CODE=$(echo "${RESPONSE}" | tail -n1)
BODY=$(echo "${RESPONSE}" | sed '$d')

if [[ "${HTTP_CODE}" == "200" ]]; then
    echo "Attribute ${ATTR_ID} already exists (HTTP 200)."
    exit 0
fi

echo "Attribute not found (HTTP ${HTTP_CODE}). Creating..."

ATTR_BODY=$(cat <<EOF
{
  "displayName": "Agentic Readiness",
  "description": "Indicates the level of AI agent readiness (Low=Passive, Medium=Proactive, High=Autonomous).",
  "scope": "VERSION",
  "dataType": "ENUM",
  "allowedValues": [
    {"id": "readiness_low", "displayName": "Low (Passive)"},
    {"id": "readiness_medium", "displayName": "Medium (Proactive)"},
    {"id": "readiness_high", "displayName": "High (Autonomous)"}
  ],
  "cardinality": 1
}
EOF
)

CREATE_RES=$(call_api "POST" "${API_HUB_ENDPOINT}/projects/${PROJECT}/locations/${LOCATION}/attributes?attributeId=${ATTR_ID}" "${ATTR_BODY}")
CREATE_CODE=$(echo "${CREATE_RES}" | tail -n1)
CREATE_BODY=$(echo "${CREATE_RES}" | sed '$d')

if [[ "${CREATE_CODE}" == "200" ]] || [[ "${CREATE_CODE}" == "201" ]]; then
    echo "Attribute created successfully."
elif [[ "${CREATE_CODE}" == "409" ]]; then
    echo "Attribute already exists (Race condition / 409 caught). Continuing."
    exit 0
else
    echo "Failed to create attribute. code: ${CREATE_CODE}"
    echo "${CREATE_BODY}"
    exit 1
fi
