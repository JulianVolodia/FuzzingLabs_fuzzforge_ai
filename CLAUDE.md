# FuzzForge AI - Comprehensive Technical Documentation

**Version:** 0.7.3
**Last Updated:** 2025-11-08
**Status:** Active Development

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Project Overview](#project-overview)
3. [Architecture](#architecture)
4. [Repository Structure](#repository-structure)
5. [Core Components](#core-components)
6. [Workflows](#workflows)
7. [Installation & Setup](#installation--setup)
8. [Development Guide](#development-guide)
9. [Contributing](#contributing)
10. [License](#license)
11. [Roadmap](#roadmap)

---

## Executive Summary

**FuzzForge** is an AI-powered workflow automation platform for Application Security, Fuzzing, and Offensive Security. It provides security researchers and engineers with tools to automate security testing workflows, scale AppSec operations with AI agents, and build reusable security workflows.

### Key Highlights

- **Version:** 0.7.3
- **Architecture:** Temporal orchestration with vertical workers
- **Storage:** MinIO (S3-compatible) for unified file handling
- **AI Integration:** Multi-agent system with A2A (Agent-to-Agent) capabilities
- **License:** Business Source License (BSL) 1.1 + Apache 2.0 (after 4 years)
- **Language:** Python 3.11+
- **Status:** Active development with breaking changes expected

### Technology Stack

- **Orchestration:** Temporal
- **Storage:** MinIO (S3-compatible)
- **Database:** PostgreSQL (Temporal), SQLite (CLI/AI)
- **Workers:** Docker containers with specialized security toolchains
- **API:** FastAPI
- **CLI:** Typer with rich terminal interfaces
- **AI:** Google ADK, LiteLLM, Cognee knowledge graphs

---

## Project Overview

### What is FuzzForge?

FuzzForge helps security researchers and engineers automate application security and offensive security workflows with the power of AI and fuzzing frameworks. It provides:

1. **Workflow Automation** - Define and execute AppSec workflows as code
2. **AI Agents for Security** - Specialized agents for AppSec, reversing, and fuzzing
3. **Vulnerability Research at Scale** - Rediscover 1-days and find 0-days with automation
4. **Fuzzer Integration** - Atheris (Python), cargo-fuzz (Rust), OSS-Fuzz campaigns
5. **Community Marketplace** - Share workflows, corpora, PoCs, and modules
6. **Enterprise Ready** - Team/Corp cloud tiers for scaling offensive security

### Key Features

- **AI Agents for Security:** Specialized agents for AppSec, reversing, and fuzzing
- **Workflow Automation:** Define and execute AppSec workflows as code
- **Vulnerability Research at Scale:** Rediscover 1-days and find 0-days with automation
- **Fuzzer Integration:** Atheris (Python), cargo-fuzz (Rust), OSS-Fuzz campaigns
- **Community Marketplace:** Share workflows, corpora, PoCs, and modules
- **Enterprise Ready:** Team/Corp cloud tiers for scaling offensive security

### Secret Detection Benchmarks

FuzzForge includes three secret detection workflows benchmarked on a controlled dataset of **32 documented secrets** (12 Easy, 10 Medium, 10 Hard):

| Tool | Recall | Secrets Found | Speed |
|------|--------|---------------|-------|
| **LLM (gpt-5-mini)** | **84.4%** | 41 | 618s |
| **LLM (gpt-4o-mini)** | 56.2% | 30 | 297s |
| **Gitleaks** | 37.5% | 12 | 5s |
| **TruffleHog** | 0.0% | 1 | 5s |

The LLM-based detector excels at finding obfuscated and hidden secrets through semantic analysis, while pattern-based tools (Gitleaks) offer speed for standard secret formats.

---

## Architecture

### Current Architecture (Temporal + Vertical Workers)

FuzzForge uses **Temporal orchestration** with a **vertical worker architecture** where each worker is pre-built with domain-specific security toolchains.

```
┌───────────────────────────────────────────────────────────────┐
│ FuzzForge Platform                                            │
│                                                                │
│  ┌──────────────────┐         ┌─────────────────────────┐   │
│  │ Temporal Server  │◄────────│ MinIO (S3 Storage)      │   │
│  │ - Workflows      │         │ - Uploaded targets      │   │
│  │ - State mgmt     │         │ - Results (optional)    │   │
│  │ - Task queues    │         │ - Lifecycle policies    │   │
│  └────────┬─────────┘         └─────────────────────────┘   │
│           │                                                    │
│           │ (Task queue routing)                              │
│           │                                                    │
│  ┌────────┴────────────────────────────────────────────────┐ │
│  │ Vertical Workers (Long-lived)                            │ │
│  │                                                          │ │
│  │  ┌───────────────┐  ┌───────────────┐  ┌─────────────┐│ │
│  │  │ Android       │  │ Rust/Native   │  │ Web/JS      ││ │
│  │  │ - apktool     │  │ - AFL++       │  │ - Node.js   ││ │
│  │  │ - Frida       │  │ - cargo-fuzz  │  │ - OWASP ZAP ││ │
│  │  │ - jadx        │  │ - gdb         │  │ - semgrep   ││ │
│  │  │ - MobSF       │  │ - valgrind    │  │ - eslint    ││ │
│  │  └───────────────┘  └───────────────┘  └─────────────┘│ │
│  │                                                          │ │
│  │  ┌───────────────┐  ┌───────────────┐                  │ │
│  │  │ iOS           │  │ Blockchain    │                  │ │
│  │  │ - class-dump  │  │ - mythril     │                  │ │
│  │  │ - Clutch      │  │ - slither     │                  │ │
│  │  │ - Frida       │  │ - echidna     │                  │ │
│  │  │ - Hopper      │  │ - manticore   │                  │ │
│  │  └───────────────┘  └───────────────┘                  │ │
│  │                                                          │ │
│  │  All workers have:                                       │ │
│  │  - /app/toolbox mounted (workflow code)                 │ │
│  │  - /cache for MinIO downloads                           │ │
│  │  - Dynamic workflow discovery at startup                │ │
│  └──────────────────────────────────────────────────────────┘ │
└───────────────────────────────────────────────────────────────┘
```

### Architecture Principles

1. **Vertical Specialization:** Each worker is specialized for a security domain with pre-built toolchains
2. **Unified Storage:** Same storage backend (MinIO) in development and production
3. **Dynamic Workflow Discovery:** Workflows are discovered and loaded at runtime, not compile-time
4. **Environment-Driven Configuration:** All configuration via environment variables
5. **Fail-Safe Defaults:** System works out-of-the-box with sensible defaults

### Key Architecture Features

1. **Vertical Specialization:** Pre-built toolchains (Android: Frida, apktool; Rust: AFL++, cargo-fuzz)
2. **Zero Startup Overhead:** Long-lived workers (no container spawn per workflow)
3. **Dynamic Workflows:** Add workflows without rebuilding images (mount as volume)
4. **Unified Storage:** MinIO works identically in dev and prod
5. **Better Security:** No host filesystem mounts, isolated uploaded targets
6. **Automatic Cleanup:** MinIO lifecycle policies handle file expiration
7. **Scalability:** Clear path from single-host to multi-host to Nomad cluster

### Service Breakdown

```yaml
services:
  temporal:         # Workflow orchestration + PostgreSQL
  temporal-ui:      # Web UI at http://localhost:8080
  postgresql:       # Temporal state storage
  minio:            # S3-compatible storage for targets and results
  minio-setup:      # One-time: create buckets, set policies
  backend:          # FuzzForge REST API (port 8000)
  worker-python:    # Python security vertical (scales independently)
  worker-android:   # Android security vertical
  worker-rust:      # Rust/native security vertical
  worker-secrets:   # Secret detection vertical
  worker-ossfuzz:   # OSS-Fuzz integration vertical
  # Additional verticals as needed
```

### Vertical Worker Taxonomy

| Vertical | Tools Included | Use Cases | Workflows |
|----------|---------------|-----------|-----------|
| **android** | apktool, jadx, Frida, MobSF, androguard | APK analysis, reverse engineering, dynamic instrumentation | APK security assessment, malware analysis, repackaging detection |
| **rust** | AFL++, cargo-fuzz, gdb, valgrind, AddressSanitizer | Native fuzzing, memory safety | Cargo fuzzing campaigns, binary analysis |
| **python** | Bandit, mypy, Safety, pytest | Python security testing, SAST | Python SAST, security assessment |
| **secrets** | Gitleaks, TruffleHog, LLM-based detection | Secret scanning | Secret detection workflows |
| **ossfuzz** | OSS-Fuzz integration | Fuzzing campaigns | OSS-Fuzz project fuzzing |

---

## Repository Structure

```
fuzzforge_ai/
├── .github/              # GitHub workflows and CI/CD configurations
├── ai/                   # AI module with multi-agent system
│   ├── agents/          # Task agents and orchestration
│   ├── proxy/           # LLM proxy and routing
│   └── src/             # Main AI module code
├── backend/             # Backend API and workflow orchestration
│   ├── src/            # FastAPI application
│   ├── toolbox/        # Workflows and modules
│   │   ├── workflows/  # Security testing workflows
│   │   └── modules/    # Reusable security modules
│   ├── benchmarks/     # Performance benchmarks
│   └── tests/          # Backend tests
├── cli/                 # Command-line interface
│   └── src/            # CLI implementation with Typer
├── docker/              # Docker configurations
├── docs/                # Documentation (Docusaurus)
│   ├── docs/           # Documentation markdown files
│   ├── blog/           # Blog posts and release notes
│   └── static/         # Static assets (images, videos)
├── examples/            # Example scripts and usage
├── scripts/             # Utility scripts
├── sdk/                 # Python SDK for FuzzForge API
│   └── src/            # SDK implementation
├── src/                 # Additional source files
├── test_projects/       # Test projects for validation
│   ├── android_test/   # Android test APKs
│   ├── python_fuzz_waterfall/
│   ├── rust_fuzz_test/
│   ├── secret_detection_benchmark/
│   └── vulnerable_app/
├── volumes/             # Docker volumes and environment configs
│   └── env/            # Environment variable templates
├── workers/             # Vertical workers with specialized toolchains
│   ├── android/        # Android security worker
│   ├── ossfuzz/        # OSS-Fuzz worker
│   ├── python/         # Python security worker
│   ├── rust/           # Rust/native security worker
│   └── secrets/        # Secret detection worker
├── ARCHITECTURE.md      # Detailed architecture documentation
├── CHANGELOG.md         # Version history and changes
├── CONTRIBUTING.md      # Contribution guidelines
├── README.md            # Main project README
├── docker-compose.yml   # Main docker-compose configuration
├── pyproject.toml       # Python project configuration
├── setup.py             # Setup script
└── LICENSE              # Business Source License 1.1
```

### Directory Breakdown

- **ai/**: Multi-agent AI system with A2A capabilities, knowledge graphs, and LLM routing
- **backend/**: FastAPI-based REST API for workflow orchestration and Temporal integration
- **cli/**: Rich terminal interface for project management, workflow execution, and findings analysis
- **sdk/**: Python SDK for programmatic access to FuzzForge API
- **workers/**: Vertical workers with pre-built security toolchains
- **docs/**: Comprehensive documentation built with Docusaurus
- **test_projects/**: Sample projects for testing and validation

---

## Core Components

### 1. Backend (FastAPI + Temporal)

**Location:** `backend/`

The backend is a stateless API server that orchestrates security testing workflows using Temporal.

**Key Features:**
- **Workflow Discovery System:** Automatically discovers workflows at startup
- **Module System:** Reusable components (scanner, analyzer, reporter)
- **Temporal Integration:** Handles workflow orchestration and monitoring
- **File Upload & Storage:** HTTP multipart upload to MinIO
- **SARIF Output:** Standardized security findings format

**API Endpoints:**

Workflows:
- `GET /workflows` - List all discovered workflows
- `GET /workflows/{name}/metadata` - Get workflow metadata
- `POST /workflows/{name}/upload-and-submit` - Upload files and submit workflow

Runs:
- `GET /runs/{run_id}/status` - Get run status
- `GET /runs/{run_id}/findings` - Get SARIF findings

**Storage Flow:**

1. CLI/API uploads file via HTTP multipart
2. Backend receives file and streams to temporary location (max 10GB)
3. Backend uploads to MinIO with generated `target_id`
4. Workflow is submitted to Temporal with `target_id`
5. Worker downloads target from MinIO to local cache
6. Workflow processes target from cache
7. MinIO lifecycle policy deletes files after 7 days

### 2. CLI (Typer + Rich)

**Location:** `cli/`

A comprehensive command-line interface with beautiful terminal interfaces and persistent project management.

**Key Features:**
- Project management with SQLite database
- Workflow execution with automatic file upload
- Real-time monitoring with progress bars
- Findings analysis and export (JSON, CSV, HTML, SARIF)
- Rich tables and interactive prompts
- Worker lifecycle management (auto-start/stop)

**Main Commands:**

```bash
# Project Management
ff init                          # Initialize project
fuzzforge status                 # Show project and API status

# Workflow Management
fuzzforge workflows list         # List available workflows
fuzzforge workflows info <name>  # Get workflow details
ff workflow run <workflow> <path> # Execute workflow

# Findings Management
fuzzforge finding <run-id>       # View findings
fuzzforge finding export <run-id> --format sarif

# Configuration
fuzzforge config show            # Show configuration
fuzzforge config set <key> <value>
```

**Automatic File Upload:**

The CLI intelligently handles target files:
- **Local file/directory exists:** Automatic upload to MinIO
- **Path doesn't exist locally:** Path-based submission (legacy)

### 3. Workers (Vertical Security Toolchains)

**Location:** `workers/`

Long-lived Docker containers pre-built with domain-specific security toolchains.

**Available Workers:**

1. **worker-python:** Bandit, mypy, Safety, pytest
2. **worker-android:** apktool, jadx, Frida, MobSF, androguard
3. **worker-rust:** AFL++, cargo-fuzz, gdb, valgrind
4. **worker-secrets:** Gitleaks, TruffleHog, LLM-based detection
5. **worker-ossfuzz:** OSS-Fuzz integration

**Worker Architecture:**

- **Startup:** Worker discovers workflows from `/app/toolbox/workflows`
- **Filtering:** Only loads workflows where `metadata.yaml` has matching `vertical`
- **Dynamic Import:** Dynamically imports workflow Python modules
- **Registration:** Registers discovered workflows with Temporal
- **Processing:** Polls Temporal task queue for work

**Scaling:**

```bash
# Vertical scaling (more work per worker)
MAX_CONCURRENT_ACTIVITIES=10

# Horizontal scaling (more workers)
docker-compose up -d --scale worker-rust=3
```

### 4. AI Module (Multi-Agent System)

**Location:** `ai/`

Multi-agent AI layer for operating FuzzForge through natural language.

**Key Features:**
- Agent-to-Agent (A2A) orchestration
- LLM routing with LiteLLM proxy
- Knowledge graphs with Cognee
- Session persistence with SQLite
- Semantic recall and memory
- Artifact management

**Components:**

- **Task Agent:** Google ADK-based task orchestration
- **LLM Proxy:** Centralized LLM provider management
- **A2A Server:** HTTP endpoints for agent collaboration
- **Knowledge Graphs:** Cognee-based project knowledge

**Usage:**

```bash
# Initialize and ingest project
fuzzforge init
fuzzforge ingest --path . --recursive

# Launch agent shell
fuzzforge ai agent

# Example prompts
list available fuzzforge workflows
run fuzzforge workflow security_assessment on ./backend
search project knowledge for "temporal status" using INSIGHTS
```

### 5. SDK (Python Client Library)

**Location:** `sdk/`

Comprehensive Python SDK for programmatic access to FuzzForge API.

**Key Features:**
- Complete API coverage
- Automatic tarball creation and file upload
- Async & sync client methods
- Type safety with Pydantic
- Comprehensive error handling

**Example Usage:**

```python
from fuzzforge_sdk import FuzzForgeClient
from pathlib import Path

# Initialize client
client = FuzzForgeClient(base_url="http://localhost:8000")

# Submit workflow with automatic file upload
response = client.submit_workflow_with_upload(
    workflow_name="security_assessment",
    target_path=Path("/path/to/project"),
    timeout=300
)

# Wait for completion
final_status = client.wait_for_completion(response.run_id)
findings = client.get_run_findings(response.run_id)

client.close()
```

### 6. Documentation (Docusaurus)

**Location:** `docs/`

Comprehensive documentation website built with Docusaurus.

**Structure:**

- **Tutorial:** Getting started guides
- **How-To:** Practical guides for specific tasks
- **Concept:** Architectural explanations
- **Reference:** API documentation and CLI reference

**Local Development:**

```bash
cd docs/
yarn install
yarn start  # Opens http://localhost:3000
```

---

## Workflows

### Available Workflows

FuzzForge includes the following pre-built workflows:

1. **security_assessment** - Comprehensive security analysis
2. **android_static_analysis** - Android APK security testing
3. **python_sast** - Python static application security testing
4. **gitleaks_detection** - Pattern-based secret scanning
5. **trufflehog_detection** - Entropy-based secret detection
6. **llm_secret_detection** - AI-powered semantic secret detection
7. **llm_analysis** - LLM-based code security analysis
8. **atheris_fuzzing** - Python fuzzing with Atheris
9. **cargo_fuzzing** - Rust fuzzing with cargo-fuzz
10. **ossfuzz_campaign** - OSS-Fuzz integration

### Workflow Structure

Each workflow must have:

```
backend/toolbox/workflows/{workflow_name}/
├── workflow.py       # Temporal workflow definition
├── metadata.yaml     # Mandatory metadata (parameters, version, vertical)
└── requirements.txt  # Optional Python dependencies
```

### Workflow Metadata Example

```yaml
name: security_assessment
version: "1.0.0"
description: "Comprehensive security analysis workflow"
author: "FuzzForge Team"
category: "comprehensive"
vertical: "python"  # Routes to worker-python
tags:
  - "security"
  - "analysis"
  - "comprehensive"

requirements:
  tools:
    - "file_scanner"
    - "security_analyzer"
    - "sarif_reporter"
  resources:
    memory: "512Mi"
    cpu: "500m"
    timeout: 1800

parameters:
  type: object
  properties:
    target_path:
      type: string
      default: "/workspace"
      description: "Path to analyze"
```

### Workflow-to-Worker Mapping

| Workflow | Worker Required | Startup Command |
|----------|----------------|-----------------|
| `security_assessment`, `python_sast`, `llm_analysis`, `atheris_fuzzing` | worker-python | `docker compose up -d worker-python` |
| `android_static_analysis` | worker-android | `docker compose up -d worker-android` |
| `cargo_fuzzing` | worker-rust | `docker compose up -d worker-rust` |
| `ossfuzz_campaign` | worker-ossfuzz | `docker compose up -d worker-ossfuzz` |
| `llm_secret_detection`, `trufflehog_detection`, `gitleaks_detection` | worker-secrets | `docker compose up -d worker-secrets` |

---

## Installation & Setup

### Requirements

- **Python 3.11+**
- **uv Package Manager**
- **Docker** and **Docker Compose**

### Install uv Package Manager

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

### Configure AI Agent API Keys (Optional)

For AI-powered workflows, configure your LLM API keys:

```bash
cp volumes/env/.env.template volumes/env/.env
# Edit volumes/env/.env and add your API keys (OpenAI, Anthropic, Google, etc.)
```

**Note:** Don't change the `OPENAI_API_KEY` default value, as it's used for the LLM proxy.

### Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/fuzzinglabs/fuzzforge_ai.git
cd fuzzforge_ai

# 2. Copy the default LLM env config
cp volumes/env/.env.template volumes/env/.env

# 3. Start FuzzForge with Temporal
docker compose up -d

# 4. Start the Python worker (needed for security_assessment)
docker compose up -d worker-python

# 5. Install CLI
uv tool install --python python3.12 .

# 6. Run your first workflow
cd test_projects/vulnerable_app/
fuzzforge init
ff workflow run security_assessment .
```

### Services Running

- **Temporal UI:** http://localhost:8080
- **MinIO Console:** http://localhost:9001 (login: fuzzforge/fuzzforge123)
- **Backend API:** http://localhost:8000
- **API Docs:** http://localhost:8000/docs

---

## Development Guide

### Setting Up Development Environment

```bash
# Clone repository
git clone https://github.com/fuzzinglabs/fuzzforge_ai.git
cd fuzzforge_ai

# Install CLI in development mode
uv tool install --python python3.12 --editable .

# Install SDK in development mode
cd sdk
uv sync
cd ..

# Install AI module in development mode
cd ai
uv sync
cd ..
```

### Adding a New Workflow

1. **Create workflow directory:**

```bash
mkdir -p backend/toolbox/workflows/my_workflow
```

2. **Create metadata.yaml:**

```yaml
name: my_workflow
version: 1.0.0
description: "My custom security workflow"
vertical: python  # Choose appropriate vertical
```

3. **Create workflow.py:**

```python
from temporalio import workflow
from datetime import timedelta

@workflow.defn
class MyWorkflow:
    @workflow.run
    async def run(self, target_id: str) -> dict:
        # Download target
        target_path = await workflow.execute_activity(
            "get_target",
            target_id,
            start_to_close_timeout=timedelta(minutes=5)
        )

        # Your analysis logic here
        results = {"status": "success"}

        # Cleanup
        await workflow.execute_activity(
            "cleanup_cache",
            target_path,
            start_to_close_timeout=timedelta(minutes=1)
        )

        return results
```

4. **Restart worker:**

```bash
docker compose restart worker-python
```

### Adding a New Vertical Worker

1. **Create worker directory:**

```bash
mkdir -p workers/my_vertical
```

2. **Create Dockerfile:**

```dockerfile
FROM python:3.11-slim

# Install your vertical-specific tools
RUN apt-get update && apt-get install -y \
    tool1 \
    tool2 \
    && rm -rf /var/lib/apt/lists/*

# Copy worker files
COPY requirements.txt /tmp/
RUN pip install --no-cache-dir -r /tmp/requirements.txt

COPY worker.py /app/
COPY activities.py /app/

WORKDIR /app
ENV PYTHONPATH="/app:/app/toolbox:${PYTHONPATH}"

CMD ["python", "worker.py"]
```

3. **Copy worker files from template:**

```bash
cp workers/rust/worker.py workers/my_vertical/
cp workers/rust/activities.py workers/my_vertical/
cp workers/rust/requirements.txt workers/my_vertical/
```

4. **Add to docker-compose.yml:**

```yaml
worker-my-vertical:
  build:
    context: ./workers/my_vertical
  container_name: fuzzforge-worker-my-vertical
  profiles:
    - workers
    - my_vertical
  environment:
    TEMPORAL_ADDRESS: temporal:7233
    WORKER_VERTICAL: my_vertical
  volumes:
    - ./backend/toolbox:/app/toolbox:ro
    - worker_my_vertical_cache:/cache
  networks:
    - fuzzforge-network
```

### Running Tests

```bash
# Backend tests
cd backend
pytest

# CLI tests
cd cli
pytest

# SDK tests
cd sdk
pytest
```

### Code Quality

```bash
# Format code
black .
isort .

# Type checking
mypy src/

# Linting
ruff check .
```

---

## Contributing

We welcome contributions from the community! See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

### Ways to Contribute

- Bug Reports - Help us identify and fix issues
- Feature Requests - Suggest new capabilities
- Code Contributions - Submit bug fixes and enhancements
- Documentation - Improve guides and tutorials
- Testing - Help test new features
- Security Workflows - Contribute new workflows

### Commit Message Format

We use conventional commits:

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

**Types:**
- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation changes
- `style:` Code formatting
- `refactor:` Code restructuring
- `test:` Adding or updating tests
- `chore:` Maintenance tasks

### Pull Request Process

1. Create a branch: `git checkout -b feature/your-feature-name`
2. Make your changes with tests
3. Update documentation
4. Submit pull request with detailed description
5. Ensure all CI checks pass

---

## License

FuzzForge is released under the **Business Source License (BSL) 1.1**, with an automatic fallback to **Apache 2.0** after 4 years.

See [LICENSE](LICENSE) and [LICENSE-APACHE](LICENSE-APACHE) for details.

---

## Roadmap

### Planned Features

- Public workflow & module marketplace
- New specialized AI agents (Rust, Go, Android, Automotive)
- Expanded fuzzer integrations (LibFuzzer, Jazzer, network fuzzers)
- Multi-tenant SaaS platform with team collaboration
- Advanced reporting & analytics

### Version History

**Current Version:** 0.7.3 (2025-10-30)

**Recent Changes:**
- Android static analysis workflow
- ARM64 (Apple Silicon) support
- Python SAST workflow
- LiteLLM integration
- CI/CD improvements

See [CHANGELOG.md](CHANGELOG.md) for full version history.

---

## Support & Resources

- **Website:** https://fuzzforge.ai
- **Documentation:** https://docs.fuzzforge.ai
- **Discord:** https://discord.gg/8XEX33UUwZ
- **GitHub Issues:** https://github.com/FuzzingLabs/fuzzforge_ai/issues
- **FuzzingLabs Academy:** https://academy.fuzzinglabs.com

---

## Acknowledgments

FuzzForge is developed and maintained by [FuzzingLabs](https://fuzzinglabs.com) and the open-source community.

**Thank you to all contributors who make FuzzForge better!**

---

**Last Updated:** 2025-11-08
**Document Version:** 1.0
**Next Review:** After Phase 1 implementation
