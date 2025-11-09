#Requires -RunAsAdministrator

################################################################################
# FuzzForge AI - Automated Setup Script for Windows
################################################################################
# Version: 1.0.0
# Description: Automated installation and setup of FuzzForge on Windows
# Requirements: Windows 10/11, PowerShell 5.1+, Admin privileges
# Usage: Right-click and "Run with PowerShell" (as Administrator)
#        Or: powershell -ExecutionPolicy Bypass -File setup-windows.ps1
################################################################################

# Set error action
$ErrorActionPreference = "Stop"

# Colors
function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

function Log-Info($message) {
    Write-ColorOutput Blue "[INFO] $message"
}

function Log-Success($message) {
    Write-ColorOutput Green "[SUCCESS] $message"
}

function Log-Warning($message) {
    Write-ColorOutput Yellow "[WARNING] $message"
}

function Log-Error($message) {
    Write-ColorOutput Red "[ERROR] $message"
}

# Banner
Write-Host "################################################################################"
Write-Host "#                                                                              #"
Write-Host "#                  FuzzForge AI - Windows Setup Script                        #"
Write-Host "#                                                                              #"
Write-Host "################################################################################"
Write-Host ""

# Check if running as Administrator
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Log-Error "This script must be run as Administrator"
    Log-Error "Right-click PowerShell and select 'Run as Administrator'"
    Read-Host "Press Enter to exit"
    exit 1
}

Log-Success "Running with Administrator privileges"

# Check Windows version
Log-Info "Checking Windows version..."
$osVersion = [System.Environment]::OSVersion.Version
$windowsVersion = (Get-CimInstance Win32_OperatingSystem).Caption
Log-Success "Running on: $windowsVersion"

if ($osVersion.Major -lt 10) {
    Log-Error "Windows 10 or later is required"
    Read-Host "Press Enter to exit"
    exit 1
}

################################################################################
# Step 1: Install Chocolatey (Package Manager)
################################################################################
Log-Info "Step 1: Installing Chocolatey package manager..."

if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
    Log-Info "Installing Chocolatey..."
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

    # Refresh environment
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

    Log-Success "Chocolatey installed successfully"
} else {
    Log-Success "Chocolatey already installed"
    choco upgrade chocolatey -y
}

################################################################################
# Step 2: Install Docker Desktop
################################################################################
Log-Info "Step 2: Installing Docker Desktop..."

if (!(Get-Command docker -ErrorAction SilentlyContinue)) {
    Log-Info "Installing Docker Desktop via Chocolatey..."
    choco install docker-desktop -y

    Log-Warning "Docker Desktop installed. Please complete the setup:"
    Log-Warning "1. Docker Desktop will start automatically (or start it from Start Menu)"
    Log-Warning "2. Accept the service agreement"
    Log-Warning "3. If prompted, enable WSL2 (recommended)"
    Log-Warning "4. Wait for Docker to complete initialization"

    Log-Info "Waiting for Docker Desktop to start..."
    Log-Info "This may take 2-3 minutes. Please wait..."

    # Wait for Docker Desktop to be available
    $timeout = 180
    $elapsed = 0
    while ($elapsed -lt $timeout) {
        Start-Sleep -Seconds 10
        $elapsed += 10

        try {
            docker version | Out-Null
            if ($LASTEXITCODE -eq 0) {
                break
            }
        } catch {
            Write-Host "." -NoNewline
        }
    }

    Write-Host ""

    if ($elapsed -ge $timeout) {
        Log-Warning "Docker Desktop did not start automatically"
        Log-Warning "Please start Docker Desktop manually from the Start Menu"
        Read-Host "Press Enter after Docker Desktop is running"
    } else {
        Log-Success "Docker Desktop is running"
    }
} else {
    Log-Success "Docker already installed"

    # Check if Docker is running
    try {
        docker version | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Log-Success "Docker is running"
        }
    } catch {
        Log-Warning "Docker is installed but not running"
        Log-Info "Starting Docker Desktop..."
        Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"

        Log-Info "Waiting for Docker to start..."
        $timeout = 120
        $elapsed = 0
        while ($elapsed -lt $timeout) {
            Start-Sleep -Seconds 10
            $elapsed += 10

            try {
                docker version | Out-Null
                if ($LASTEXITCODE -eq 0) {
                    break
                }
            } catch {
                Write-Host "." -NoNewline
            }
        }
        Write-Host ""

        if ($elapsed -ge $timeout) {
            Log-Error "Docker failed to start. Please start Docker Desktop manually"
            Read-Host "Press Enter to exit"
            exit 1
        }

        Log-Success "Docker is running"
    }
}

# Verify Docker Compose
Log-Info "Verifying Docker Compose..."
try {
    docker compose version | Out-Null
    Log-Success "Docker Compose is available"
} catch {
    Log-Error "Docker Compose not found. Please reinstall Docker Desktop"
    Read-Host "Press Enter to exit"
    exit 1
}

################################################################################
# Step 3: Install Python 3.11+
################################################################################
Log-Info "Step 3: Installing Python 3.12..."

if (!(Get-Command python -ErrorAction SilentlyContinue)) {
    Log-Info "Installing Python 3.12 via Chocolatey..."
    choco install python312 -y

    # Refresh environment
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

    Log-Success "Python 3.12 installed"
} else {
    Log-Success "Python already installed"
}

# Verify Python version
$pythonVersion = python --version
Log-Success "Python version: $pythonVersion"

################################################################################
# Step 4: Install uv Package Manager
################################################################################
Log-Info "Step 4: Installing uv package manager..."

if (!(Get-Command uv -ErrorAction SilentlyContinue)) {
    Log-Info "Installing uv..."

    # Download and run uv installer
    Invoke-RestMethod https://astral.sh/uv/install.ps1 | Invoke-Expression

    # Add to PATH
    $uvPath = "$env:USERPROFILE\.cargo\bin"
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($currentPath -notlike "*$uvPath*") {
        [Environment]::SetEnvironmentVariable("Path", "$currentPath;$uvPath", "User")
    }

    # Refresh environment
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

    Log-Success "uv installed successfully"
} else {
    Log-Success "uv already installed"
}

################################################################################
# Step 5: Install Git
################################################################################
Log-Info "Step 5: Installing Git..."

if (!(Get-Command git -ErrorAction SilentlyContinue)) {
    Log-Info "Installing Git via Chocolatey..."
    choco install git -y

    # Refresh environment
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

    Log-Success "Git installed"
} else {
    Log-Success "Git already installed"
}

################################################################################
# Step 6: Clone FuzzForge Repository
################################################################################
Log-Info "Step 6: Cloning FuzzForge repository..."

$installDir = "$env:USERPROFILE\fuzzforge_ai"

if (Test-Path $installDir) {
    Log-Warning "Directory $installDir already exists"
    $response = Read-Host "Remove and clone fresh? (y/n)"
    if ($response -eq "y" -or $response -eq "Y") {
        Remove-Item -Recurse -Force $installDir
        Log-Info "Removed existing directory"
    } else {
        Log-Info "Using existing directory"
        Set-Location $installDir
        try {
            git pull origin main
        } catch {
            Log-Warning "Could not pull latest changes"
        }
    }
}

if (!(Test-Path $installDir)) {
    Log-Info "Cloning repository to $installDir..."
    git clone https://github.com/fuzzinglabs/fuzzforge_ai.git $installDir
    Log-Success "Repository cloned"
}

Set-Location $installDir

################################################################################
# Step 7: Configure Environment
################################################################################
Log-Info "Step 7: Configuring environment..."

if (!(Test-Path "volumes\env\.env")) {
    Copy-Item "volumes\env\.env.template" "volumes\env\.env"
    Log-Success "Environment file created: volumes\env\.env"
    Log-Warning "IMPORTANT: Edit volumes\env\.env to add your API keys for AI workflows"
    Log-Warning "  - LITELLM_GEMINI_API_KEY for Google Gemini"
    Log-Warning "  - Or other LLM provider keys"
    Log-Warning "Basic workflows work without API keys!"
} else {
    Log-Success "Environment file already exists"
}

################################################################################
# Step 8: Start FuzzForge Services
################################################################################
Log-Info "Step 8: Starting FuzzForge services..."

Log-Info "Building and starting Docker containers..."
docker compose up -d

Log-Info "Waiting for services to be healthy (30-60 seconds)..."
Start-Sleep -Seconds 30

# Check service health
Log-Info "Checking service status..."
docker compose ps

Log-Success "FuzzForge services started!"

################################################################################
# Step 9: Install FuzzForge CLI
################################################################################
Log-Info "Step 9: Installing FuzzForge CLI..."

Log-Info "Installing CLI with uv..."
uv tool install --python python3.12 .

Log-Success "FuzzForge CLI installed"

################################################################################
# Step 10: Verify Installation
################################################################################
Log-Info "Step 10: Verifying installation..."

# Refresh PATH
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

if (Get-Command fuzzforge -ErrorAction SilentlyContinue) {
    Log-Success "FuzzForge CLI is available"
    fuzzforge --version
} else {
    Log-Warning "FuzzForge CLI not found in PATH"
    Log-Info "You may need to restart PowerShell or add to PATH:"
    Log-Info "  `$env:Path += `";$env:USERPROFILE\.local\bin`""
}

# Check Docker services
Log-Info "Checking service health..."
$servicesOk = $true

try {
    $response = Invoke-WebRequest -Uri "http://localhost:8000/health" -UseBasicParsing -TimeoutSec 5
    if ($response.StatusCode -eq 200) {
        Log-Success "Backend API is responding"
    }
} catch {
    Log-Warning "Backend API not responding on port 8000"
    $servicesOk = $false
}

try {
    $response = Invoke-WebRequest -Uri "http://localhost:8080" -UseBasicParsing -TimeoutSec 5
    Log-Success "Temporal UI is accessible"
} catch {
    Log-Warning "Temporal UI not accessible on port 8080"
    $servicesOk = $false
}

################################################################################
# Step 11: Create Quick Start Script
################################################################################
Log-Info "Creating quick start script..."

$quickStartScript = @"
# FuzzForge Quick Start Script for Windows
Write-Host "🚀 FuzzForge Quick Start" -ForegroundColor Blue
Write-Host ""

Set-Location "$installDir"

Write-Host "Starting FuzzForge services..." -ForegroundColor Yellow
docker compose up -d

Write-Host ""
Write-Host "Waiting for services to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

Write-Host ""
Write-Host "✅ FuzzForge is ready!" -ForegroundColor Green
Write-Host ""
Write-Host "Access points:"
Write-Host "  - Temporal UI: http://localhost:8080"
Write-Host "  - MinIO Console: http://localhost:9001 (login: fuzzforge/fuzzforge123)"
Write-Host "  - Backend API: http://localhost:8000"
Write-Host "  - API Docs: http://localhost:8000/docs"
Write-Host ""
Write-Host "Quick commands:"
Write-Host "  fuzzforge workflows list           # List available workflows"
Write-Host "  fuzzforge init                      # Initialize a project"
Write-Host "  ff workflow run <workflow> <path>   # Run a workflow"
Write-Host ""
Write-Host "Example: Run security assessment on a project"
Write-Host "  cd C:\Users\YourName\your-project"
Write-Host "  fuzzforge init"
Write-Host "  docker compose -f $installDir\docker-compose.yml up -d worker-python"
Write-Host "  ff workflow run security_assessment ."
Write-Host ""
"@

$quickStartScript | Out-File -FilePath "$env:USERPROFILE\fuzzforge-quickstart.ps1" -Encoding UTF8
Log-Success "Quick start script created: $env:USERPROFILE\fuzzforge-quickstart.ps1"

################################################################################
# Create Desktop Shortcut
################################################################################
Log-Info "Creating desktop shortcuts..."

$WshShell = New-Object -comObject WScript.Shell

# Shortcut to FuzzForge directory
$Shortcut = $WshShell.CreateShortcut("$env:USERPROFILE\Desktop\FuzzForge.lnk")
$Shortcut.TargetPath = "explorer.exe"
$Shortcut.Arguments = $installDir
$Shortcut.Description = "Open FuzzForge directory"
$Shortcut.Save()

# Shortcut to Temporal UI
$Shortcut = $WshShell.CreateShortcut("$env:USERPROFILE\Desktop\FuzzForge Temporal UI.url")
$Shortcut.TargetPath = "http://localhost:8080"
$Shortcut.Save()

Log-Success "Desktop shortcuts created"

################################################################################
# Installation Complete
################################################################################
Write-Host ""
Write-Host "################################################################################"
Write-Host "#                                                                              #"
Write-Host "#                    Installation Complete! 🎉                                 #"
Write-Host "#                                                                              #"
Write-Host "################################################################################"
Write-Host ""

Log-Success "FuzzForge AI has been successfully installed on Windows!"
Write-Host ""
Write-Host "📍 Installation Directory: $installDir"
Write-Host ""
Write-Host "🌐 Access Points:"
Write-Host "   - Temporal UI:    http://localhost:8080"
Write-Host "   - MinIO Console:  http://localhost:9001 (login: fuzzforge/fuzzforge123)"
Write-Host "   - Backend API:    http://localhost:8000"
Write-Host "   - API Docs:       http://localhost:8000/docs"
Write-Host ""
Write-Host "🛠️  Next Steps:"
Write-Host "   1. Open a new PowerShell window (to load environment)"
Write-Host "   2. Navigate to a test project:"
Write-Host "      cd $installDir\test_projects\vulnerable_app"
Write-Host "   3. Initialize FuzzForge:"
Write-Host "      fuzzforge init"
Write-Host "   4. Start a worker (e.g., Python worker):"
Write-Host "      docker compose -f $installDir\docker-compose.yml up -d worker-python"
Write-Host "   5. Run your first workflow:"
Write-Host "      ff workflow run security_assessment ."
Write-Host ""
Write-Host "📚 Documentation:"
Write-Host "   - Quick Start: type $installDir\CRASH_COURSE.md"
Write-Host "   - Full Docs:   type $installDir\CLAUDE.md"
Write-Host "   - Online:      https://docs.fuzzforge.ai"
Write-Host ""
Write-Host "⚙️  Configuration:"
Write-Host "   - Edit API keys: notepad $installDir\volumes\env\.env"
Write-Host "   - Required only for AI-powered workflows"
Write-Host ""
Write-Host "🔧 Useful Commands:"
Write-Host "   fuzzforge --help              # Show all commands"
Write-Host "   fuzzforge workflows list      # List available workflows"
Write-Host "   fuzzforge status              # Check system status"
Write-Host "   powershell $env:USERPROFILE\fuzzforge-quickstart.ps1  # Quick start"
Write-Host ""
Write-Host "💬 Support:"
Write-Host "   - Discord:  https://discord.gg/8XEX33UUwZ"
Write-Host "   - Docs:     https://docs.fuzzforge.ai"
Write-Host "   - Issues:   https://github.com/FuzzingLabs/fuzzforge_ai/issues"
Write-Host ""
Write-Host "⚠️  Important Notes:"
Write-Host "   - Docker Desktop must be running before using FuzzForge"
Write-Host "   - Workers don't auto-start (saves RAM). Start needed worker before workflows."
Write-Host "   - Desktop shortcuts created for quick access"
Write-Host ""

if (-not $servicesOk) {
    Log-Warning "Some services are not responding. This is normal on first run."
    Log-Warning "Wait 1-2 minutes for all services to initialize, then check:"
    Log-Warning "  docker compose -f $installDir\docker-compose.yml ps"
}

Log-Success "Setup complete! Happy fuzzing! 🐛🔍"
Write-Host ""

Read-Host "Press Enter to exit"
