#!/bin/bash

################################################################################
# FuzzForge AI - Automated Setup Script for macOS
################################################################################
# Version: 1.0.0
# Description: Automated installation and setup of FuzzForge on macOS
# Requirements: macOS 11+ (Big Sur or later), Admin privileges
# Usage: ./setup-macos.sh
################################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Banner
echo "################################################################################"
echo "#                                                                              #"
echo "#                    FuzzForge AI - macOS Setup Script                        #"
echo "#                                                                              #"
echo "################################################################################"
echo ""

# Check macOS version
log_info "Checking macOS version..."
macos_version=$(sw_vers -productVersion)
log_success "Running macOS $macos_version"

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    log_error "Please do not run this script as root (don't use sudo)"
    exit 1
fi

################################################################################
# Step 1: Install Homebrew
################################################################################
log_info "Step 1: Installing Homebrew (if not installed)..."

if ! command -v brew &> /dev/null; then
    log_info "Homebrew not found. Installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH for Apple Silicon
    if [[ $(uname -m) == 'arm64' ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi

    log_success "Homebrew installed successfully"
else
    log_success "Homebrew already installed"
    brew update
fi

################################################################################
# Step 2: Install Docker Desktop
################################################################################
log_info "Step 2: Installing Docker Desktop..."

if ! command -v docker &> /dev/null; then
    log_info "Installing Docker Desktop via Homebrew Cask..."
    brew install --cask docker

    log_warning "Please start Docker Desktop from Applications and grant necessary permissions"
    log_warning "Waiting for Docker to start..."

    # Open Docker Desktop
    open -a Docker

    # Wait for Docker to be ready
    log_info "Waiting for Docker daemon to start (this may take 1-2 minutes)..."
    timeout=120
    elapsed=0
    while ! docker info &> /dev/null; do
        if [ $elapsed -ge $timeout ]; then
            log_error "Docker failed to start within $timeout seconds"
            log_error "Please start Docker Desktop manually and run this script again"
            exit 1
        fi
        sleep 5
        elapsed=$((elapsed + 5))
        echo -n "."
    done
    echo ""
    log_success "Docker is running"
else
    log_success "Docker already installed"

    # Check if Docker is running
    if ! docker info &> /dev/null; then
        log_warning "Docker is installed but not running. Starting Docker Desktop..."
        open -a Docker

        log_info "Waiting for Docker daemon..."
        timeout=120
        elapsed=0
        while ! docker info &> /dev/null; do
            if [ $elapsed -ge $timeout ]; then
                log_error "Docker failed to start. Please start Docker Desktop manually"
                exit 1
            fi
            sleep 5
            elapsed=$((elapsed + 5))
            echo -n "."
        done
        echo ""
        log_success "Docker is running"
    fi
fi

# Verify Docker Compose
log_info "Verifying Docker Compose..."
if docker compose version &> /dev/null; then
    log_success "Docker Compose is available"
else
    log_error "Docker Compose not found. Please reinstall Docker Desktop"
    exit 1
fi

################################################################################
# Step 3: Install Python 3.11+
################################################################################
log_info "Step 3: Installing Python 3.11+..."

if ! command -v python3.11 &> /dev/null && ! command -v python3.12 &> /dev/null; then
    log_info "Installing Python 3.12 via Homebrew..."
    brew install python@3.12
    log_success "Python 3.12 installed"
else
    log_success "Python 3.11+ already installed"
fi

# Verify Python version
python_version=$(python3 --version | awk '{print $2}')
log_success "Python version: $python_version"

################################################################################
# Step 4: Install uv Package Manager
################################################################################
log_info "Step 4: Installing uv package manager..."

if ! command -v uv &> /dev/null; then
    log_info "Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh

    # Add uv to PATH
    export PATH="$HOME/.cargo/bin:$PATH"

    # Add to shell profile
    if [[ $SHELL == *"zsh"* ]]; then
        echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.zshrc
        log_info "Added uv to ~/.zshrc"
    elif [[ $SHELL == *"bash"* ]]; then
        echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.bash_profile
        log_info "Added uv to ~/.bash_profile"
    fi

    log_success "uv installed successfully"
else
    log_success "uv already installed"
fi

################################################################################
# Step 5: Install Git (if not present)
################################################################################
log_info "Step 5: Checking Git installation..."

if ! command -v git &> /dev/null; then
    log_info "Installing Git..."
    brew install git
    log_success "Git installed"
else
    log_success "Git already installed"
fi

################################################################################
# Step 6: Clone FuzzForge Repository
################################################################################
log_info "Step 6: Cloning FuzzForge repository..."

INSTALL_DIR="$HOME/fuzzforge_ai"

if [ -d "$INSTALL_DIR" ]; then
    log_warning "Directory $INSTALL_DIR already exists"
    read -p "Do you want to remove it and clone fresh? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$INSTALL_DIR"
        log_info "Removed existing directory"
    else
        log_info "Using existing directory"
        cd "$INSTALL_DIR"
        git pull origin main 2>/dev/null || log_warning "Could not pull latest changes"
    fi
fi

if [ ! -d "$INSTALL_DIR" ]; then
    log_info "Cloning repository to $INSTALL_DIR..."
    git clone https://github.com/fuzzinglabs/fuzzforge_ai.git "$INSTALL_DIR"
    log_success "Repository cloned"
fi

cd "$INSTALL_DIR"

################################################################################
# Step 7: Configure Environment
################################################################################
log_info "Step 7: Configuring environment..."

if [ ! -f "volumes/env/.env" ]; then
    cp volumes/env/.env.template volumes/env/.env
    log_success "Environment file created: volumes/env/.env"
    log_warning "IMPORTANT: Edit volumes/env/.env to add your API keys for AI-powered workflows"
    log_warning "  - LITELLM_GEMINI_API_KEY for Google Gemini"
    log_warning "  - Or other LLM provider keys"
    log_warning "Basic workflows work without API keys!"
else
    log_success "Environment file already exists"
fi

################################################################################
# Step 8: Start FuzzForge Services
################################################################################
log_info "Step 8: Starting FuzzForge services..."

log_info "Building and starting Docker containers..."
docker compose up -d

log_info "Waiting for services to be healthy (30-60 seconds)..."
sleep 30

# Check service health
log_info "Checking service status..."
docker compose ps

log_success "FuzzForge services started!"

################################################################################
# Step 9: Install FuzzForge CLI
################################################################################
log_info "Step 9: Installing FuzzForge CLI..."

# Ensure uv is in PATH
export PATH="$HOME/.cargo/bin:$PATH"

log_info "Installing CLI with uv..."
uv tool install --python python3.12 .

log_success "FuzzForge CLI installed"

################################################################################
# Step 10: Verify Installation
################################################################################
log_info "Step 10: Verifying installation..."

# Add uv bin to PATH for verification
export PATH="$HOME/.local/bin:$PATH"

if command -v fuzzforge &> /dev/null; then
    log_success "FuzzForge CLI is available"
    fuzzforge --version
else
    log_warning "FuzzForge CLI not found in PATH"
    log_info "You may need to add it to your PATH:"
    log_info "  export PATH=\"\$HOME/.local/bin:\$PATH\""
fi

# Check Docker services
log_info "Checking service health..."
services_ok=true

if curl -s http://localhost:8000/health &> /dev/null; then
    log_success "Backend API is responding"
else
    log_warning "Backend API not responding on port 8000"
    services_ok=false
fi

if curl -s http://localhost:8080 &> /dev/null; then
    log_success "Temporal UI is accessible"
else
    log_warning "Temporal UI not accessible on port 8080"
    services_ok=false
fi

################################################################################
# Step 11: Create Quick Start Script
################################################################################
log_info "Creating quick start script..."

cat > "$HOME/fuzzforge-quickstart.sh" << 'EOF'
#!/bin/bash
# FuzzForge Quick Start Script

cd ~/fuzzforge_ai

echo "🚀 FuzzForge Quick Start"
echo ""
echo "Starting FuzzForge services..."
docker compose up -d

echo ""
echo "Waiting for services to start..."
sleep 10

echo ""
echo "✅ FuzzForge is ready!"
echo ""
echo "Access points:"
echo "  - Temporal UI: http://localhost:8080"
echo "  - MinIO Console: http://localhost:9001 (login: fuzzforge/fuzzforge123)"
echo "  - Backend API: http://localhost:8000"
echo "  - API Docs: http://localhost:8000/docs"
echo ""
echo "Quick commands:"
echo "  fuzzforge workflows list           # List available workflows"
echo "  fuzzforge init                      # Initialize a project"
echo "  ff workflow run <workflow> <path>   # Run a workflow"
echo ""
echo "Example: Run security assessment on a project"
echo "  cd ~/your-project"
echo "  fuzzforge init"
echo "  docker compose -f ~/fuzzforge_ai/docker-compose.yml up -d worker-python"
echo "  ff workflow run security_assessment ."
echo ""
EOF

chmod +x "$HOME/fuzzforge-quickstart.sh"
log_success "Quick start script created: ~/fuzzforge-quickstart.sh"

################################################################################
# Installation Complete
################################################################################
echo ""
echo "################################################################################"
echo "#                                                                              #"
echo "#                    Installation Complete! 🎉                                 #"
echo "#                                                                              #"
echo "################################################################################"
echo ""

log_success "FuzzForge AI has been successfully installed on your Mac!"
echo ""
echo "📍 Installation Directory: $INSTALL_DIR"
echo ""
echo "🌐 Access Points:"
echo "   - Temporal UI:    http://localhost:8080"
echo "   - MinIO Console:  http://localhost:9001 (login: fuzzforge/fuzzforge123)"
echo "   - Backend API:    http://localhost:8000"
echo "   - API Docs:       http://localhost:8000/docs"
echo ""
echo "🛠️  Next Steps:"
echo "   1. Open a new terminal (to load environment)"
echo "   2. Navigate to a test project:"
echo "      cd $INSTALL_DIR/test_projects/vulnerable_app"
echo "   3. Initialize FuzzForge:"
echo "      fuzzforge init"
echo "   4. Start a worker (e.g., Python worker):"
echo "      docker compose -f $INSTALL_DIR/docker-compose.yml up -d worker-python"
echo "   5. Run your first workflow:"
echo "      ff workflow run security_assessment ."
echo ""
echo "📚 Documentation:"
echo "   - Quick Start: cat $INSTALL_DIR/CRASH_COURSE.md"
echo "   - Full Docs:   cat $INSTALL_DIR/CLAUDE.md"
echo "   - Online:      https://docs.fuzzforge.ai"
echo ""
echo "⚙️  Configuration:"
echo "   - Edit API keys: nano $INSTALL_DIR/volumes/env/.env"
echo "   - Required only for AI-powered workflows (llm_secret_detection, etc.)"
echo ""
echo "🔧 Useful Commands:"
echo "   fuzzforge --help              # Show all commands"
echo "   fuzzforge workflows list      # List available workflows"
echo "   fuzzforge status              # Check system status"
echo "   ~/fuzzforge-quickstart.sh     # Quick start services"
echo ""
echo "💬 Support:"
echo "   - Discord:  https://discord.gg/8XEX33UUwZ"
echo "   - Docs:     https://docs.fuzzforge.ai"
echo "   - Issues:   https://github.com/FuzzingLabs/fuzzforge_ai/issues"
echo ""
echo "⚠️  Important Notes:"
echo "   - Add to PATH: export PATH=\"\$HOME/.local/bin:\$HOME/.cargo/bin:\$PATH\""
echo "   - Docker must be running before using FuzzForge"
echo "   - Workers don't auto-start (saves RAM). Start needed worker before workflows."
echo ""

if [ "$services_ok" = false ]; then
    log_warning "Some services are not responding. This is normal on first run."
    log_warning "Wait 1-2 minutes for all services to initialize, then check:"
    log_warning "  docker compose -f $INSTALL_DIR/docker-compose.yml ps"
fi

log_success "Setup complete! Happy fuzzing! 🐛🔍"
echo ""
