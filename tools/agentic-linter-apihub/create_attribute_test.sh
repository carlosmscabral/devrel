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

# create_attribute_test.sh
# Creates 'agentic-readiness' attribute and tests association with a mock API.

set -e

# Load environment variables
if [[ -f .env ]]; then
  source .env
else
  echo "Error: .env file not found."
  exit 1
fi

# Configuration
LOCATION="${API_HUB_REGION}"
PROJECT="${PROJECT_ID}"
API_HUB_ENDPOINT="https://apihub.googleapis.com/v1"
ATTR_ID="agentic-readiness"
MOCK_API_ID="agentic-mock-api"
MOCK_VERSION_ID="version-1"

echo "Authenticating..."
TOKEN="$(gcloud auth print-access-token)"

# Helper function for curl
call_api() {
  local method="$1"
  local url="$2"
  local data="$3"
  
  if [[ -n "${data}" ]]; then
    curl -s -X "${method}" "${url}" \
      -H "Authorization: Bearer ${TOKEN}" \
      -H "Content-Type: application/json" \
      -d "${data}"
  else
    curl -s -X "${method}" "${url}" \
      -H "Authorization: Bearer ${TOKEN}" \
      -H "Content-Type: application/json"
  fi
}

echo "------------------------------------------------"
echo "1. Creating Attribute: ${ATTR_ID}"
echo "------------------------------------------------"

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

# Check if attribute exists first to avoid error or handle 409
EXISTING_ATTR=$(call_api "GET" "${API_HUB_ENDPOINT}/projects/${PROJECT}/locations/${LOCATION}/attributes/${ATTR_ID}")
if [[ $(echo "${EXISTING_ATTR}" | jq -r '.name' 2>/dev/null) == *"attributes/${ATTR_ID}" ]]; then
    echo "Attribute ${ATTR_ID} already exists."
else
    CREATE_RES=$(call_api "POST" "${API_HUB_ENDPOINT}/projects/${PROJECT}/locations/${LOCATION}/attributes?attributeId=${ATTR_ID}" "${ATTR_BODY}")
    if [[ $(echo "${CREATE_RES}" | jq -r '.name' 2>/dev/null) == *"attributes/${ATTR_ID}" ]]; then
        echo "Attribute created successfully."
    else
        echo "Failed to create attribute. Response:"
        echo "${CREATE_RES}"
        # Continue mostly to allow debugging, but normally should exit
    fi
fi

echo "------------------------------------------------"
echo "2. Creating Mock API: ${MOCK_API_ID}"
echo "------------------------------------------------"

API_BODY=$(cat <<EOF
{
  "displayName": "Agentic Mock API",
  "owner": {
    "email": "$(gcloud config get-value account)"
  }
}
EOF
)

# Check/Create API
EXISTING_API=$(call_api "GET" "${API_HUB_ENDPOINT}/projects/${PROJECT}/locations/${LOCATION}/apis/${MOCK_API_ID}")
if [[ $(echo "${EXISTING_API}" | jq -r '.name' 2>/dev/null) == *"apis/${MOCK_API_ID}" ]]; then
    echo "API ${MOCK_API_ID} already exists."
else
    # Correct Endpoint for creation: .../apis?apiId=...
    CREATE_API_RES=$(call_api "POST" "${API_HUB_ENDPOINT}/projects/${PROJECT}/locations/${LOCATION}/apis?apiId=${MOCK_API_ID}" "${API_BODY}")
    echo "API Creation Response: $(echo "${CREATE_API_RES}" | jq -r '.name // .error.message')"
fi

echo "------------------------------------------------"
echo "3. Creating Version: ${MOCK_VERSION_ID}"
echo "------------------------------------------------"

VERSION_BODY=$(cat <<EOF
{
  "displayName": "Version 1 (Agentic)"
}
EOF
)

EXISTING_VER=$(call_api "GET" "${API_HUB_ENDPOINT}/projects/${PROJECT}/locations/${LOCATION}/apis/${MOCK_API_ID}/versions/${MOCK_VERSION_ID}")
if [[ $(echo "${EXISTING_VER}" | jq -r '.name' 2>/dev/null) == *"versions/${MOCK_VERSION_ID}" ]]; then
    echo "Version ${MOCK_VERSION_ID} already exists."
else
    CREATE_VER_RES=$(call_api "POST" "${API_HUB_ENDPOINT}/projects/${PROJECT}/locations/${LOCATION}/apis/${MOCK_API_ID}/versions?versionId=${MOCK_VERSION_ID}" "${VERSION_BODY}")
    echo "Version Creation Response: $(echo "${CREATE_VER_RES}" | jq -r '.name // .error.message')"
fi

echo "------------------------------------------------"
echo "4. Assigning Attribute (LOW) to Version"
echo "------------------------------------------------"

# Format: projects/{project}/locations/{location}/attributes/{attribute_id}
ATTR_RESOURCE_NAME="projects/${PROJECT}/locations/${LOCATION}/attributes/${ATTR_ID}"

# Allowed values are objects with id. For assignment, we likely need the EnumValue object or just ID depending on API.
# Per REST docs, attributes is map<string, AttributeValues>.
# For Enum, the value should technically be the allowedValue ID or object.
# Let's try passing the basic structure.

PATCH_BODY=$(cat <<EOF
{
  "attributes": {
    "${ATTR_RESOURCE_NAME}": {
      "enumValues": {
        "values": [
          {
            "id": "readiness_low"
          }
        ]
      }
    }
  }
}
EOF
)

UPDATE_RES=$(call_api "PATCH" \
  "${API_HUB_ENDPOINT}/projects/${PROJECT}/locations/${LOCATION}/apis/${MOCK_API_ID}/versions/${MOCK_VERSION_ID}?updateMask=attributes" \
  "${PATCH_BODY}")

echo "Update Response:"
echo "${UPDATE_RES}" | jq '.'

echo "------------------------------------------------"
echo "5. Verifying Assignment"
echo "------------------------------------------------"

FINAL_VER=$(call_api "GET" "${API_HUB_ENDPOINT}/projects/${PROJECT}/locations/${LOCATION}/apis/${MOCK_API_ID}/versions/${MOCK_VERSION_ID}")
ASSIGNED_VAL=$(echo "${FINAL_VER}" | jq -r ".attributes[\"${ATTR_RESOURCE_NAME}\"].enumValues.values[0].id")

if [[ "${ASSIGNED_VAL}" == "readiness_low" ]]; then
  echo "✅ SUCCESS: Agentic Readiness is set to readiness_low."
else
  echo "❌ FAILURE: Agentic Readiness is ${ASSIGNED_VAL} (Expected readiness_low)."
fi
