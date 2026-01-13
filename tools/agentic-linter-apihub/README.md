# Agentic API Design & Governance Demo

This project demonstrates how to refactor a legacy "Human-Centric" API into an "Agent-Ready" Cognitive Interface, and how to enforce these patterns using **Spectral** and **Google Cloud Build**.

## 🎥 Hands-On Demo

[![Agentic API Design Demo](https://img.youtube.com/vi/LvJYUz4mws0/0.jpg)](https://www.youtube.com/watch?v=LvJYUz4mws0)

## 📂 Project Structure

- **`human-centric/`**: Legacy OpenAPI spec (Low Readiness).
- **`medium/`**: Proactive OpenAPI spec (Medium Readiness).
- **`agentic/`**: Agent-Ready OpenAPI spec (High Readiness).
- **`linters/`**: Spectral rulesets (`agentic.yaml`).
- **`cloudbuild.yaml`**: CI/CD pipeline for governance and deployment.
- **`deploy.sh`**: Main deployment script to trigger specific scenarios.
- **Helper Scripts**: `ensure_attribute.sh`, `classify_spec.sh`, `assign_attribute.sh`.
- **`Article.md`**: Guide on Agentic API Design philosophy.

## 🚀 Getting Started

### Prerequisites

1.  **Google Cloud Project** with:
    - API Hub enabled.
    - Cloud Build enabled.
2.  **`gcloud` CLI** installed and authenticated.
3.  **Permissions**: Ensure your Cloud Build Service Account has:
    - `API Hub Admin` (or equivalent permissions to create APIs/Versions/Specs)

### Configuration

1.  Copy the environment template:
    ```bash
    cp .env.local .env
    ```
2.  Edit `.env` and fill in your details:
    ```bash
    PROJECT_ID=your-gcp-project-id
    API_HUB_REGION=us-central1
    ```

## 🧠 Agentic Readiness & Classification

We have introduced a **custom attribute** in API Hub called **Agentic Readiness** (`agentic-readiness`) to classify APIs based on their adherence to the agentic rules.

### Readiness Levels

| Level | Value | Description | Spectral Criteria |
| :--- | :--- | :--- | :--- |
| **High** | `readiness_high` | **Autonomous** | 0 Errors, 0 Warnings. Ready for full agentic autonomy. |
| **Medium** | `readiness_medium` | **Proactive** | 0 Errors, >0 Warnings. Usable by agents but may require user confirmation. |
| **Low** | `readiness_low` | **Passive** | >0 Errors. Not safe for agentic use (Standard REST API). |

---

## 🛠️ Running the Pipeline

We use **Google Cloud Build** to automate the governance, classification, and deployment loop.
The pipeline now includes the following steps (visualized in Cloud Build with emojis):

1.  **✨ Ensure Attribute**: Checks if `agentic-readiness` exists in API Hub, creates it if missing.
2.  **🧐 Agentic Lint**: Runs `spectral` to analyze the spec. Output is saved for classification.
3.  **🧠 Classify Spec**: Calculates the Readiness Level (Low/Medium/High).
4.  **📦 Register API**: Registers the API and Version in API Hub.
5.  **🏷️ Assign Readiness**: Updates the API Version with the calculated readiness attribute.

### Deployment Modes

You can deploy three different versions of the API to see the classification in action.

#### 1. The "Agentic" Path (High Readiness)
Deploys the optimized `agentic/openapi.yaml`.

```bash
./deploy.sh
```
- **Outcome**: `agentic-orders-api` | **High (Autonomous)**

#### 2. The "Medium" Path (Proactive)
Deploys `medium/openapi.yaml`, which has valid structure but misses some examples/hints.

```bash
./deploy.sh medium
```
- **Outcome**: `proactive-orders-api` | **Medium (Proactive)**

#### 3. The "Legacy" Path (Low Readiness)
Deploys the legacy `human-centric/openapi.yaml`.

```bash
./deploy.sh legacy
```
- **Outcome**: `human-centric-orders-api` | **Low (Passive)**

---

## 🧹 Cleanup

To remove the Agentic API from API Hub, run:

```bash
./cleanup.sh
```

Or for specific versions:

```bash
./cleanup.sh medium
./cleanup.sh legacy
```

## 🔍 The "Agentic" Linter Rules

The `linters/agentic.yaml` file enforces 6 key rules for AI compatibility:

1.  **Semantic Naming**: OperationIDs must be action-oriented (e.g., `submitOrder` vs `post_orders`).
2.  **Description Economy**: Descriptions must be detailed enough to serve as System Prompts.
3.  **Few-Shot Prompting**: Examples are mandatory (Warning).
4.  **Strict Mode**: `additionalProperties: false` is required to prevent hallucinations (Error).
5.  **Explicit Requirements**: No implicit logic; required fields must be listed (Warning).
6.  **Reflexion**: Error responses must include a `hint` field (Warning).
