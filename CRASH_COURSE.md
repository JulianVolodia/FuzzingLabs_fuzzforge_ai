# FuzzForge AI - Crash Course for Windows & Cloud Deployment

**Version:** 0.7.3
**Last Updated:** 2025-11-08
**Target Audience:** Security researchers, DevOps engineers, developers

---

## Table of Contents

1. [Introduction](#introduction)
2. [Windows Setup Guide](#windows-setup-guide)
3. [Cloud Deployment Guide](#cloud-deployment-guide)
4. [First Workflow Walkthrough](#first-workflow-walkthrough)
5. [Common Use Cases](#common-use-cases)
6. [Troubleshooting](#troubleshooting)
7. [Performance Optimization](#performance-optimization)
8. [Security Best Practices](#security-best-practices)

---

## Introduction

This crash course will get you running FuzzForge AI in **15 minutes** on Windows or in the cloud. We cover:

- ✅ Windows 10/11 with Docker Desktop or WSL2
- ✅ Cloud platforms: AWS, Azure, GCP, DigitalOcean
- ✅ Quick start with pre-built workflows
- ✅ Common issues and solutions

### What You'll Need

**Minimum Requirements:**
- **CPU:** 4 cores
- **RAM:** 8 GB (16 GB recommended)
- **Disk:** 20 GB free space
- **Network:** Stable internet connection

**Software:**
- Docker Desktop (Windows) or Docker Engine (Cloud)
- Python 3.11+ (for CLI)
- Git

---

## Windows Setup Guide

### Method 1: Docker Desktop (Recommended for Windows)

#### Step 1: Install Docker Desktop

1. **Download Docker Desktop**
   - Visit: https://www.docker.com/products/docker-desktop/
   - Download for Windows
   - Minimum: Windows 10 64-bit (Pro, Enterprise, Education) or Windows 11

2. **Install Docker Desktop**
   ```powershell
   # Run the installer as Administrator
   # Accept license agreement
   # Enable WSL2 when prompted (recommended)
   ```

3. **Configure Docker Desktop**
   - Open Docker Desktop
   - Go to **Settings** → **Resources**
   - Allocate resources:
     - **CPUs:** 4 (minimum)
     - **Memory:** 8 GB (minimum), 16 GB recommended
     - **Swap:** 2 GB
     - **Disk:** 60 GB

4. **Enable WSL2 Integration** (Recommended)
   - Settings → Resources → WSL Integration
   - Enable integration with Ubuntu or your WSL2 distro

5. **Verify Installation**
   ```powershell
   # Open PowerShell or Command Prompt
   docker --version
   docker compose version

   # Test Docker
   docker run hello-world
   ```

#### Step 2: Install Python and uv Package Manager

1. **Install Python 3.11+**
   ```powershell
   # Download from https://www.python.org/downloads/
   # OR use winget
   winget install Python.Python.3.12

   # Verify
   python --version
   ```

2. **Install uv Package Manager**
   ```powershell
   # Using PowerShell (Run as Administrator)
   irm https://astral.sh/uv/install.ps1 | iex

   # Verify
   uv --version
   ```

#### Step 3: Clone Repository

```powershell
# Open PowerShell
cd C:\Users\YourUsername\Projects

# Clone repository
git clone https://github.com/fuzzinglabs/fuzzforge_ai.git
cd fuzzforge_ai
```

#### Step 4: Configure Environment

```powershell
# Copy environment template
Copy-Item volumes\env\.env.template volumes\env\.env

# Edit .env file (Optional - only for AI-powered workflows)
notepad volumes\env\.env

# Add your API keys if using AI features:
# LITELLM_GEMINI_API_KEY=your-google-api-key
# or
# OPENAI_API_KEY=your-openai-api-key (for LLM workflows)
```

**Note:** Basic workflows work without API keys!

#### Step 5: Start FuzzForge

```powershell
# Start core services
docker compose up -d

# Wait for services to start (30-60 seconds)
# You should see:
#   ✔ Network fuzzforge-network     Created
#   ✔ Volume temporal_data          Created
#   ✔ Container fuzzforge-temporal  Started
#   ✔ Container fuzzforge-minio     Started
#   ✔ Container fuzzforge-backend   Started

# Check status
docker compose ps
```

#### Step 6: Install CLI

```powershell
# Install CLI globally
uv tool install --python python3.12 .

# Verify installation
fuzzforge --version
ff --version
```

#### Step 7: Run Your First Workflow

```powershell
# Navigate to test project
cd test_projects\vulnerable_app

# Initialize FuzzForge project
fuzzforge init

# List available workflows
fuzzforge workflows list

# Start Python worker (needed for security_assessment)
docker compose up -d worker-python

# Run security assessment
ff workflow run security_assessment .

# View findings
fuzzforge finding
```

**Success! 🎉** You're now running FuzzForge on Windows.

---

### Method 2: WSL2 (Windows Subsystem for Linux)

For users who prefer Linux environment on Windows:

#### Step 1: Install WSL2

```powershell
# Open PowerShell as Administrator
wsl --install

# Install Ubuntu (recommended)
wsl --install -d Ubuntu-22.04

# Restart your computer
```

#### Step 2: Setup in Ubuntu

```bash
# Open Ubuntu from Start Menu
# Update packages
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group
sudo usermod -aG docker $USER

# Install Docker Compose
sudo apt install docker-compose-plugin

# Logout and login again
exit
```

#### Step 3: Install Python and uv

```bash
# Reopen Ubuntu terminal
# Install Python 3.11+
sudo apt install python3.11 python3-pip

# Install uv
curl -LsSf https://astral.sh/uv/install.sh | sh

# Reload shell
source ~/.bashrc
```

#### Step 4: Clone and Setup

```bash
# Clone repository
cd ~
git clone https://github.com/fuzzinglabs/fuzzforge_ai.git
cd fuzzforge_ai

# Configure environment
cp volumes/env/.env.template volumes/env/.env
nano volumes/env/.env  # Edit if needed

# Start services
docker compose up -d

# Install CLI
uv tool install --python python3.11 .

# Verify
fuzzforge --version
```

#### Step 5: Access from Windows

```bash
# Services are accessible from Windows browser:
# - Temporal UI: http://localhost:8080
# - MinIO Console: http://localhost:9001
# - Backend API: http://localhost:8000
```

---

## Cloud Deployment Guide

### AWS Deployment

#### Option A: EC2 Instance (Quick Start)

**Step 1: Launch EC2 Instance**

```bash
# Recommended instance: t3.xlarge
# - vCPUs: 4
# - RAM: 16 GB
# - Storage: 100 GB gp3
# - OS: Ubuntu 22.04 LTS

# From AWS Console:
# 1. Go to EC2 → Launch Instance
# 2. Name: fuzzforge-server
# 3. AMI: Ubuntu Server 22.04 LTS
# 4. Instance type: t3.xlarge
# 5. Key pair: Create or select existing
# 6. Network: Allow SSH (22), HTTP (8000, 8080, 9000, 9001)
# 7. Storage: 100 GB gp3
# 8. Launch instance
```

**Security Group Rules:**

| Type | Protocol | Port Range | Source | Description |
|------|----------|------------|--------|-------------|
| SSH | TCP | 22 | Your IP | SSH access |
| Custom TCP | TCP | 8000 | 0.0.0.0/0 | Backend API |
| Custom TCP | TCP | 8080 | 0.0.0.0/0 | Temporal UI |
| Custom TCP | TCP | 9000 | 0.0.0.0/0 | MinIO S3 API |
| Custom TCP | TCP | 9001 | 0.0.0.0/0 | MinIO Console |

**Step 2: Connect and Setup**

```bash
# Connect to instance
ssh -i your-key.pem ubuntu@your-instance-ip

# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker ubuntu

# Install Docker Compose
sudo apt install docker-compose-plugin

# Logout and login
exit
ssh -i your-key.pem ubuntu@your-instance-ip

# Install Python and uv
sudo apt install python3.11 python3-pip git
curl -LsSf https://astral.sh/uv/install.sh | sh
source ~/.bashrc
```

**Step 3: Deploy FuzzForge**

```bash
# Clone repository
git clone https://github.com/fuzzinglabs/fuzzforge_ai.git
cd fuzzforge_ai

# Configure environment
cp volumes/env/.env.template volumes/env/.env
nano volumes/env/.env  # Add API keys if needed

# Start services
docker compose up -d

# Install CLI
uv tool install --python python3.11 .

# Verify services
docker compose ps
curl http://localhost:8000/health
```

**Step 4: Configure DNS (Optional)**

```bash
# If you have a domain, point it to your EC2 IP
# Example: fuzzforge.yourdomain.com → 54.123.45.67

# Update environment for production
export FUZZFORGE_API_URL=http://fuzzforge.yourdomain.com:8000
```

**Step 5: Run Test Workflow**

```bash
cd test_projects/vulnerable_app
fuzzforge init
docker compose up -d worker-python
ff workflow run security_assessment .
```

#### Option B: ECS (Elastic Container Service)

For production-grade deployment with auto-scaling:

**Prerequisites:**
- AWS CLI installed and configured
- Docker images pushed to ECR

```bash
# 1. Create ECR repositories
aws ecr create-repository --repository-name fuzzforge/temporal
aws ecr create-repository --repository-name fuzzforge/backend
aws ecr create-repository --repository-name fuzzforge/worker-python

# 2. Build and push images
docker compose build
docker tag fuzzforge-backend:latest <account-id>.dkr.ecr.<region>.amazonaws.com/fuzzforge/backend:latest
docker push <account-id>.dkr.ecr.<region>.amazonaws.com/fuzzforge/backend:latest

# 3. Create ECS cluster (via Console or CLI)
# 4. Create task definitions
# 5. Create services
# 6. Configure ALB for load balancing
```

See `docs/deployment/aws-ecs.md` for detailed ECS deployment guide.

---

### Azure Deployment

#### Azure Container Instances (Quick Start)

**Step 1: Create Resource Group**

```bash
# Install Azure CLI
# Windows: winget install Microsoft.AzureCLI
# Linux: curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Login
az login

# Create resource group
az group create --name fuzzforge-rg --location eastus
```

**Step 2: Create Azure Container Instances**

```bash
# Create storage account for MinIO
az storage account create \
  --name fuzzforgestorage \
  --resource-group fuzzforge-rg \
  --location eastus \
  --sku Standard_LRS

# Deploy using docker-compose (Azure supports this!)
az container create \
  --resource-group fuzzforge-rg \
  --file docker-compose.yml
```

#### Azure VM (Recommended for Production)

```bash
# Create VM
az vm create \
  --resource-group fuzzforge-rg \
  --name fuzzforge-vm \
  --image Ubuntu2204 \
  --size Standard_D4s_v3 \
  --admin-username azureuser \
  --generate-ssh-keys \
  --public-ip-address-allocation static

# Open ports
az vm open-port --resource-group fuzzforge-rg --name fuzzforge-vm --port 8000 --priority 1001
az vm open-port --resource-group fuzzforge-rg --name fuzzforge-vm --port 8080 --priority 1002
az vm open-port --resource-group fuzzforge-rg --name fuzzforge-vm --port 9000 --priority 1003
az vm open-port --resource-group fuzzforge-rg --name fuzzforge-vm --port 9001 --priority 1004

# Get public IP
az vm show -d --resource-group fuzzforge-rg --name fuzzforge-vm --query publicIps -o tsv

# Connect and setup
ssh azureuser@<public-ip>

# Follow standard setup steps (same as AWS EC2)
```

---

### Google Cloud Platform (GCP)

#### Compute Engine VM

**Step 1: Create VM Instance**

```bash
# Install gcloud CLI
# Follow: https://cloud.google.com/sdk/docs/install

# Login
gcloud auth login

# Set project
gcloud config set project your-project-id

# Create VM
gcloud compute instances create fuzzforge-vm \
  --zone=us-central1-a \
  --machine-type=n2-standard-4 \
  --image-family=ubuntu-2204-lts \
  --image-project=ubuntu-os-cloud \
  --boot-disk-size=100GB \
  --boot-disk-type=pd-ssd \
  --tags=fuzzforge-server

# Create firewall rules
gcloud compute firewall-rules create fuzzforge-api \
  --allow=tcp:8000 \
  --target-tags=fuzzforge-server

gcloud compute firewall-rules create fuzzforge-temporal \
  --allow=tcp:8080 \
  --target-tags=fuzzforge-server

gcloud compute firewall-rules create fuzzforge-minio \
  --allow=tcp:9000,tcp:9001 \
  --target-tags=fuzzforge-server

# Get external IP
gcloud compute instances describe fuzzforge-vm \
  --zone=us-central1-a \
  --format='get(networkInterfaces[0].accessConfigs[0].natIP)'

# SSH into instance
gcloud compute ssh fuzzforge-vm --zone=us-central1-a

# Follow standard setup (same as AWS EC2)
```

---

### DigitalOcean Deployment

#### Droplet Setup (Easiest Cloud Option)

**Step 1: Create Droplet**

```bash
# From DigitalOcean Console:
# 1. Click "Create" → "Droplets"
# 2. Choose image: Ubuntu 22.04 LTS
# 3. Plan: Basic ($48/mo - 8 GB RAM, 4 vCPUs)
# 4. Datacenter: Choose closest to you
# 5. Authentication: SSH keys
# 6. Hostname: fuzzforge-server
# 7. Create Droplet

# OR using doctl CLI:
doctl compute droplet create fuzzforge-server \
  --size s-4vcpu-8gb \
  --image ubuntu-22-04-x64 \
  --region nyc1 \
  --ssh-keys <your-ssh-key-id>

# Get IP
doctl compute droplet list
```

**Step 2: Configure Firewall**

```bash
# Create firewall
doctl compute firewall create \
  --name fuzzforge-fw \
  --inbound-rules "protocol:tcp,ports:22,sources:addresses:0.0.0.0/0 protocol:tcp,ports:8000,sources:addresses:0.0.0.0/0 protocol:tcp,ports:8080,sources:addresses:0.0.0.0/0 protocol:tcp,ports:9000-9001,sources:addresses:0.0.0.0/0" \
  --outbound-rules "protocol:tcp,ports:all,destinations:addresses:0.0.0.0/0"
```

**Step 3: Setup FuzzForge**

```bash
# SSH into droplet
ssh root@<droplet-ip>

# Create non-root user
adduser fuzzforge
usermod -aG sudo fuzzforge
su - fuzzforge

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker fuzzforge

# Install tools
sudo apt update && sudo apt install -y python3.11 python3-pip git
curl -LsSf https://astral.sh/uv/install.sh | sh
source ~/.bashrc

# Clone and deploy
git clone https://github.com/fuzzinglabs/fuzzforge_ai.git
cd fuzzforge_ai
cp volumes/env/.env.template volumes/env/.env

# Start services
docker compose up -d

# Install CLI
uv tool install --python python3.11 .

# Verify
docker compose ps
curl http://localhost:8000/health
```

---

### Docker Compose Cloud-Optimized Configuration

Create `docker-compose.cloud.yml` for production:

```yaml
# docker-compose.cloud.yml
services:
  temporal:
    restart: always
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G

  minio:
    restart: always
    environment:
      MINIO_CI_CD: "false"  # Use full performance mode
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 1G

  backend:
    restart: always
    environment:
      - WORKERS_COUNT=4
      - LOG_LEVEL=INFO
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G

  worker-python:
    restart: always
    deploy:
      replicas: 2  # Run 2 workers
      resources:
        limits:
          cpus: '1'
          memory: 1G
```

**Deploy with:**

```bash
docker compose -f docker-compose.yml -f docker-compose.cloud.yml up -d
```

---

## First Workflow Walkthrough

### Example 1: Secret Detection in Your Code

**Scenario:** Scan a repository for exposed secrets (API keys, passwords, tokens)

```bash
# Navigate to your project
cd /path/to/your/codebase

# Initialize FuzzForge
fuzzforge init --name "My Project Security Scan"

# Start secrets worker
docker compose up -d worker-secrets

# Run LLM-based secret detection (highest accuracy)
ff workflow run llm_secret_detection . --wait

# View findings
fuzzforge finding

# Export report
fuzzforge finding export --format html --output secrets-report.html
```

**Expected Output:**
```
🔧 Getting workflow information for: llm_secret_detection
📦 Detected local directory: . (1,234 files)
🗜️  Creating compressed tarball...
📤 Uploading to backend (12.5 MB)...
✅ Upload complete! Target ID: abc123-def456

🎯 Executing workflow:
   Workflow: llm_secret_detection
   Status: 🔄 RUNNING

⏳ Waiting for completion...
✅ Workflow completed successfully!

📊 Findings: 8 secrets detected
   - 3 High severity
   - 5 Medium severity
```

### Example 2: Android APK Security Analysis

**Scenario:** Analyze an Android APK for security vulnerabilities

```bash
# Start Android worker
docker compose up -d worker-android

# Download a test APK or use your own
cd test_projects/android_test

# Run Android static analysis
ff workflow run android_static_analysis BeetleBug.apk --wait

# View findings
fuzzforge finding

# Findings include:
# - Decompiled Java source code analysis
# - Manifest permission review
# - Hardcoded credentials
# - Insecure cryptography
# - Network security issues
```

### Example 3: Python Code Security Assessment

**Scenario:** Comprehensive security analysis of Python codebase

```bash
# Start Python worker
docker compose up -d worker-python

# Navigate to Python project
cd /path/to/python/project

# Run SAST workflow
ff workflow run python_sast . \
  --param check_dependencies=true \
  --param strict_mode=true \
  --wait

# View detailed findings
fuzzforge finding --format table

# Export SARIF for CI/CD integration
fuzzforge finding export --format sarif --output results.sarif
```

---

## Common Use Cases

### Use Case 1: CI/CD Integration

**GitHub Actions Example:**

```yaml
# .github/workflows/security-scan.yml
name: FuzzForge Security Scan

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

jobs:
  security-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup FuzzForge
        run: |
          curl -LsSf https://astral.sh/uv/install.sh | sh
          git clone https://github.com/fuzzinglabs/fuzzforge_ai.git
          cd fuzzforge_ai
          docker compose up -d
          uv tool install --python python3.11 .

      - name: Run Security Assessment
        run: |
          cd $GITHUB_WORKSPACE
          fuzzforge init --name "CI Security Scan"
          docker compose -f ../fuzzforge_ai/docker-compose.yml up -d worker-python
          ff workflow run security_assessment . --wait

      - name: Export Findings
        run: |
          fuzzforge finding export --format sarif --output security-results.sarif

      - name: Upload Results
        uses: github/codeql-action/upload-sarif@v2
        with:
          sarif_file: security-results.sarif
```

### Use Case 2: Scheduled Security Audits

**Cron Job (Linux/Cloud):**

```bash
# Create audit script
cat > /home/fuzzforge/audit.sh <<'EOF'
#!/bin/bash
cd /home/fuzzforge/projects/myapp
ff workflow run security_assessment . --wait
fuzzforge finding export --format html --output /var/www/html/security-reports/$(date +%Y%m%d).html
EOF

chmod +x /home/fuzzforge/audit.sh

# Add to crontab (daily at 2 AM)
crontab -e
# Add line:
0 2 * * * /home/fuzzforge/audit.sh
```

**Windows Task Scheduler:**

```powershell
# Create scheduled task
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-File C:\FuzzForge\audit.ps1"
$trigger = New-ScheduledTaskTrigger -Daily -At 2am
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "FuzzForge Daily Audit"
```

### Use Case 3: Multi-Project Dashboard

**Setup Project Monitoring:**

```bash
# Create projects directory
mkdir ~/fuzzforge-projects
cd ~/fuzzforge-projects

# Initialize multiple projects
for project in webapp api mobile backend; do
  mkdir $project
  cd $project
  fuzzforge init --name "$project Security"
  cd ..
done

# Run scans across all projects
for project in webapp api mobile backend; do
  cd $project
  ff workflow run security_assessment /path/to/$project --wait
  cd ..
done

# Aggregate findings
fuzzforge findings history --limit 100 > all-findings.json
```

---

## Troubleshooting

### Windows-Specific Issues

#### Issue 1: Docker Desktop Not Starting

**Symptoms:**
- "Docker Desktop starting..." never completes
- WSL2 errors

**Solutions:**

```powershell
# 1. Restart Docker Desktop
Stop-Process -Name "Docker Desktop" -Force
Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"

# 2. Reset WSL2
wsl --shutdown
wsl --list --verbose

# 3. Reinstall WSL2 kernel
wsl --update

# 4. Check virtualization in BIOS
# Ensure Intel VT-x or AMD-V is enabled

# 5. Check Windows features
# Enable: Virtual Machine Platform, Windows Subsystem for Linux
```

#### Issue 2: Port Conflicts on Windows

**Symptoms:**
- "Port 8080 already in use"

**Solutions:**

```powershell
# Find process using port
netstat -ano | findstr :8080

# Kill process
taskkill /PID <process-id> /F

# Change FuzzForge ports (edit docker-compose.yml)
# temporal-ui:
#   ports:
#     - "8081:8080"  # Changed from 8080
```

#### Issue 3: File Permission Issues

**Symptoms:**
- "Permission denied" when accessing volumes

**Solutions:**

```powershell
# Run PowerShell as Administrator
# OR

# Share drive with Docker
# Docker Desktop → Settings → Resources → File Sharing
# Add your project directory

# OR use WSL2 path
wsl
cd /mnt/c/Users/YourName/Projects/fuzzforge_ai
```

### Cloud-Specific Issues

#### Issue 1: Out of Memory Errors

**Symptoms:**
- Workflows fail with OOM
- Docker containers exit with code 137

**Solutions:**

```bash
# 1. Check current memory usage
free -h
docker stats

# 2. Increase swap space
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# 3. Add to /etc/fstab for persistence
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# 4. Upgrade instance size
# AWS: t3.xlarge → t3.2xlarge
# Azure: Standard_D4s_v3 → Standard_D8s_v3
# GCP: n2-standard-4 → n2-standard-8
```

#### Issue 2: Network Connectivity Issues

**Symptoms:**
- Cannot access Temporal UI from browser
- Workers cannot connect to Temporal

**Solutions:**

```bash
# 1. Check security groups/firewall
# AWS:
aws ec2 describe-security-groups --group-ids sg-xxxxx

# 2. Check if services are listening
sudo netstat -tlnp | grep -E '8000|8080|9000|9001'

# 3. Test from localhost first
curl http://localhost:8080

# 4. Check Docker network
docker network inspect fuzzforge-network

# 5. Restart Docker networking
sudo systemctl restart docker
docker compose down
docker compose up -d
```

#### Issue 3: Disk Space Issues

**Symptoms:**
- "No space left on device"

**Solutions:**

```bash
# 1. Check disk usage
df -h
du -sh /var/lib/docker

# 2. Clean Docker resources
docker system prune -a --volumes

# 3. Clean old images
docker image prune -a

# 4. Expand volume (AWS EBS example)
# Modify volume in AWS Console, then:
sudo growpart /dev/xvda 1
sudo resize2fs /dev/xvda1

# 5. Add monitoring
# Install disk usage alerts
```

### General Issues

#### Issue 1: Workflow Stuck in "Running" State

**Diagnosis:**

```bash
# 1. Check worker logs
docker logs fuzzforge-worker-python

# 2. Check Temporal UI
# Open http://localhost:8080
# Navigate to workflow → View execution history

# 3. Check if worker is running
docker ps | grep worker

# 4. Check MinIO target upload
# Open http://localhost:9001
# Login and check targets bucket
```

**Solutions:**

```bash
# 1. Restart worker
docker compose restart worker-python

# 2. Check worker vertical matches workflow
# Workflow metadata.yaml should have correct vertical

# 3. Increase activity timeout
# Edit workflow.py if needed

# 4. Check target file was uploaded correctly
docker exec fuzzforge-minio mc ls fuzzforge/targets/
```

#### Issue 2: "Cannot connect to backend API"

**Diagnosis:**

```bash
# Check backend health
curl http://localhost:8000/health

# Check backend logs
docker logs fuzzforge-backend

# Check if backend is running
docker ps | grep backend
```

**Solutions:**

```bash
# 1. Restart backend
docker compose restart backend

# 2. Check environment variables
docker exec fuzzforge-backend env | grep TEMPORAL

# 3. Rebuild backend if needed
docker compose build backend
docker compose up -d backend
```

---

## Performance Optimization

### Windows Performance Tips

1. **Use WSL2 Instead of Hyper-V**
   - WSL2 has better I/O performance
   - Native Linux file system is faster

2. **Allocate More Resources to Docker**
   ```
   Docker Desktop → Settings → Resources
   - CPUs: 6-8 (if you have 8+ cores)
   - Memory: 12-16 GB
   - Enable file sharing only for required directories
   ```

3. **Disable Antivirus Scanning for Docker Directories**
   ```
   Add exclusions for:
   - C:\ProgramData\Docker
   - C:\Users\<user>\AppData\Local\Docker
   - WSL2 virtual disk
   ```

### Cloud Performance Tips

1. **Use SSD Storage**
   - AWS: gp3 volumes with provisioned IOPS
   - Azure: Premium SSD
   - GCP: SSD persistent disks

2. **Enable Instance Optimizations**
   ```bash
   # AWS: Use enhanced networking
   # Azure: Enable accelerated networking
   # GCP: Use n2 series instances
   ```

3. **Scale Workers Horizontally**
   ```bash
   # Scale Python workers to 3 replicas
   docker compose up -d --scale worker-python=3

   # Or in docker-compose.cloud.yml:
   # worker-python:
   #   deploy:
   #     replicas: 3
   ```

4. **Use External PostgreSQL for Temporal**
   ```yaml
   # For production, use managed PostgreSQL:
   # - AWS RDS
   # - Azure Database for PostgreSQL
   # - GCP Cloud SQL
   ```

---

## Security Best Practices

### Windows Security

1. **Use Windows Defender Application Control**
2. **Enable BitLocker for disk encryption**
3. **Run Docker Desktop as non-admin user**
4. **Keep Docker Desktop updated**

### Cloud Security

1. **Use Private Networks**
   ```bash
   # AWS VPC, Azure VNet, GCP VPC
   # Don't expose all ports to 0.0.0.0/0
   ```

2. **Enable HTTPS with SSL/TLS**
   ```bash
   # Use Let's Encrypt with Nginx reverse proxy
   # Or AWS ALB with ACM certificate
   ```

3. **Use Secrets Management**
   ```bash
   # AWS Secrets Manager
   # Azure Key Vault
   # GCP Secret Manager

   # Don't store API keys in .env files
   ```

4. **Enable Monitoring and Logging**
   ```bash
   # CloudWatch (AWS)
   # Azure Monitor
   # Cloud Logging (GCP)
   ```

5. **Implement Access Control**
   ```bash
   # Use IAM roles
   # Enable MFA
   # Rotate credentials regularly
   ```

---

## Next Steps

### Learning Path

1. **Week 1:** Run all pre-built workflows on test projects
2. **Week 2:** Create custom workflows for your use cases
3. **Week 3:** Integrate FuzzForge into CI/CD pipeline
4. **Week 4:** Deploy to production with monitoring

### Advanced Topics

- **Custom Workflows:** See `docs/how-to/create-workflow.md`
- **Vertical Workers:** See `workers/README.md`
- **AI Agents:** See `ai/README.md`
- **Scaling to Production:** See `ARCHITECTURE.md`

### Community Resources

- **Discord:** https://discord.gg/8XEX33UUwZ
- **Documentation:** https://docs.fuzzforge.ai
- **GitHub Issues:** Report bugs and request features
- **FuzzingLabs Academy:** https://academy.fuzzinglabs.com

---

## Quick Reference

### Essential Commands

```bash
# Start services
docker compose up -d

# Start specific worker
docker compose up -d worker-python

# Check status
docker compose ps

# View logs
docker compose logs -f worker-python

# Stop services
docker compose down

# Remove everything
docker compose down -v

# Install CLI
uv tool install --python python3.12 .

# Initialize project
fuzzforge init

# List workflows
fuzzforge workflows list

# Run workflow
ff workflow run <workflow-name> <path>

# View findings
fuzzforge finding

# Export findings
fuzzforge finding export --format sarif
```

### Service URLs

- **Temporal UI:** http://localhost:8080
- **MinIO Console:** http://localhost:9001 (fuzzforge/fuzzforge123)
- **Backend API:** http://localhost:8000
- **API Docs:** http://localhost:8000/docs

---

**Congratulations! 🎉** You're now ready to use FuzzForge AI for security testing and vulnerability research.

For more help, join our [Discord community](https://discord.gg/8XEX33UUwZ) or check the [full documentation](https://docs.fuzzforge.ai).

**Happy Fuzzing! 🐛🔍**
