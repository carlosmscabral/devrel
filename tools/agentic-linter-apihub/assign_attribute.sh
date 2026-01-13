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

# assign_attribute.sh
# Assigns the calculated READINESS_LEVEL to the API Version in API Hub.

set -e

# Load environment variables (from Cloud Build env or file)
if [[ -f readiness.env ]]; then
  source readiness.env
fi

# Required variables
PROJECT="${_PROJECT_ID:-$PROJECT_ID}"
LOCATION="${_API_HUB_REGION:-$API_HUB_REGION}"
API_ID="${_API_ID:-$API_ID}"
VERSION="${_VERSION:-$VERSION}"
LEVEL="${READINESS_LEVEL}"

if [[ -z "${PROJECT}" ]] || [[ -z "${LOCATION}" ]] || [[ -z "${API_ID}" ]] || [[ -z "${VERSION}" ]] || [[ -z "${LEVEL}" ]]; then
  echo "Error: Missing required variables for assignment."
  echo "PROJECT: ${PROJECT}"
  echo "LOCATION: ${LOCATION}"
  echo "API_ID: ${API_ID}"
  echo "VERSION: ${VERSION}"
  echo "LEVEL: ${LEVEL}"
  exit 1
fi

echo "Assigning ${LEVEL} to ${API_ID}/${VERSION}..."

TOKEN="$(gcloud auth print-access-token)"

API_HUB_ENDPOINT="https://apihub.googleapis.com/v1"
ATTR_ID="agentic-readiness"
ATTR_RESOURCE_NAME="projects/${PROJECT}/locations/${LOCATION}/attributes/${ATTR_ID}"

# Prepare JSON Payload
# Using singular "enumValue" as discovered during testing
PATCH_BODY=$(cat <<EOF
{
  "attributes": {
    "${ATTR_RESOURCE_NAME}": {
      "enumValues": {
        "values": [{
          "id": "${LEVEL}"
        }]
      }
    }
  }
}
EOF
)

# Call Batch Update or Patch
# Using Patch on Version resource
URL="${API_HUB_ENDPOINT}/projects/${PROJECT}/locations/${LOCATION}/apis/${API_ID}/versions/${VERSION}?updateMask=attributes"

STATUS_CODE=$(curl -s -o response.json -w "%{http_code}" -X PATCH "${URL}" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d "${PATCH_BODY}")

if [[ "${STATUS_CODE}" -ge 200 ]] && [[ "${STATUS_CODE}" -lt 300 ]]; then
  echo "Success: Attribute assigned."
else
  echo "Error: Failed to assign attribute. Code: ${STATUS_CODE}"
  cat response.json
  exit 1
fi
