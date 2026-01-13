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

# classify_spec.sh
# Analyzes spectral_output.json to determine Agentic Readiness level.

set -e

INPUT_FILE="spectral_output.json"
OUTPUT_ENV="readiness.env"

if ! command -v jq &> /dev/null; then
  echo "jq not found. Installing..."
  apk add --no-cache jq
fi

if [[ ! -f "${INPUT_FILE}" ]]; then
  echo "Error: ${INPUT_FILE} not found."
  # If no output file, assume critical failure or empty?
  # Let's verify if 0-byte file or missing means something else.
  # If missing, defaulting to LOW is safe.
  echo "READINESS_LEVEL=readiness_low" > "${OUTPUT_ENV}"
  exit 0
fi

# Count Errors and Warnings
# Spectral JSON format: [ { "severity": 0 (Error), ... }, { "severity": 1 (Warn), ... } ]
# Severity 0 = Error, 1 = Warning, 2 = Info, 3 = Hint

ERRORS=$(jq '[.[] | select(.severity == 0)] | length' "${INPUT_FILE}")
WARNINGS=$(jq '[.[] | select(.severity == 1)] | length' "${INPUT_FILE}")

echo "Spectral Results: ${ERRORS} Errors, ${WARNINGS} Warnings."

if [[ "${ERRORS}" -gt 0 ]]; then
  LEVEL="readiness_low"
  echo "Detected ERRORS. Classification: LOW (Passive)"
elif [[ "${WARNINGS}" -gt 0 ]]; then
  LEVEL="readiness_medium"
  echo "Detected WARNINGS (No Errors). Classification: MEDIUM (Proactive)"
else
  LEVEL="readiness_high"
  echo "Clean Spec. Classification: HIGH (Autonomous)"
fi

echo "READINESS_LEVEL=${LEVEL}" > "${OUTPUT_ENV}"
cat "${OUTPUT_ENV}"
