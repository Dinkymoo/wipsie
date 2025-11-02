#!/bin/bash
# Development Environment Runner for Wipsie
# Orchestrates all development services

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="wipsie"
BACKEND_PORT="${BACKEND_PORT:-8000}"
FRONTEND_PORT="${FRONTEND_PORT:-4200}"
WORKER_CONCURRENCY="${WORKER_CONCURRENCY:-4}"

# ASCII Art Banner
show_banner() {
    echo -e "${BLUE}"
    echo "██╗    ██╗██╗██████╗ ███████╗██╗███████╗"
    echo "██║    ██║██║██╔══██╗██╔════╝██║██╔════╝"
    echo "██║ █╗ ██║██║██████╔╝███████╗██║█████╗  "
    echo "██║███╗██║██║██╔═══╝ ╚════██║██║██╔══╝  "
    echo "╚███╔███╔╝██║██║     ███████║██║███████╗"
    echo " ╚══╝╚══╝ ╚═╝╚═╝     ╚══════╝╚═╝╚══════╝"
    echo -e "${NC}"
    echo -e "${CYAN}🚀 Full Stack Development Environment${NC}"
    echo "====================================="
}

# Function to check prerequisites
check_prerequisites() {
    echo -e "${YELLOW}🔍 Checking prerequisites...${NC}"
    
    local missing_deps=""
    
    # Check Python
    if ! command -v python3 >/dev/null 2>&1; then
        missing_deps="$missing_deps python3"
    fi
    
    # Check Node.js
    if ! command -v node >/dev/null 2>&1; then
        missing_deps="$missing_deps node"
    fi
    
    # Check Docker
    if ! command -v docker >/dev/null 2>&1; then
        missing_deps="$missing_deps docker"
    fi
    
    # Check Docker Compose
    if ! command -v docker-compose >/dev/null 2>&1 && ! docker compose version >/dev/null 2>&1; then
        missing_deps="$missing_deps docker-compose"
    fi
    
    if [ -n "$missing_deps" ]; then
        echo -e "${RED}❌ Missing dependencies:$missing_deps${NC}"
        echo -e "${YELLOW}Please install the missing dependencies and try again.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ All prerequisites satisfied!${NC}"
}

# Function to setup Python environment
setup_python_env() {
    echo -e "${YELLOW}🐍 Setting up Python environment...${NC}"
    
    # Check for existing virtual environments
    local venv_path=""
    if [ -d "venv_container" ]; then
        venv_path="venv_container"
        echo -e "${BLUE}📦 Found existing virtual environment: venv_container${NC}"
    elif [ -d ".venv" ]; then
        venv_path=".venv"
        echo -e "${BLUE}📦 Found existing virtual environment: .venv${NC}"
    else
        echo -e "${BLUE}📦 Creating new virtual environment...${NC}"
        python3 -m venv venv_container
        venv_path="venv_container"
    fi
    
    # Check if pip is working in the virtual environment
    if [ -f "$venv_path/bin/pip" ]; then
        echo -e "${BLUE}🔍 Testing pip installation...${NC}"
        if ! "$venv_path/bin/pip" --version >/dev/null 2>&1; then
            echo -e "${YELLOW}⚠️  Pip is corrupted, recreating virtual environment...${NC}"
            rm -rf "$venv_path"
            python3 -m venv "$venv_path"
        fi
    fi
    
    # Activate virtual environment
    source "$venv_path/bin/activate"
    
    # Upgrade pip safely
    echo -e "${BLUE}🔧 Upgrading pip...${NC}"
    python -m pip install --upgrade pip
    
    # Install requirements
    if [ -f "requirements.txt" ]; then
        echo -e "${BLUE}📋 Installing Python dependencies...${NC}"
        pip install -r requirements.txt
    fi
    
    # Install additional dependencies for the project
    echo -e "${BLUE}📦 Installing project dependencies...${NC}"
    pip install fastapi uvicorn sqlalchemy alembic psycopg2-binary redis celery boto3 requests
    
    echo -e "${GREEN}✅ Python environment ready!${NC}"
}

# Function to setup Node.js environment
setup_node_env() {
    echo -e "${YELLOW}📦 Setting up Node.js environment...${NC}"
    
    if [ -d "frontend/wipsie-app" ]; then
        cd frontend/wipsie-app
        
        if [ -f "package.json" ]; then
            echo -e "${BLUE}📋 Installing Node.js dependencies...${NC}"
            npm install
            echo -e "${GREEN}✅ Node.js dependencies installed!${NC}"
        fi
        
        cd ../..
    fi
}

# Function to start infrastructure services
start_infrastructure() {
    echo -e "${YELLOW}🏗️  Starting infrastructure services...${NC}"
    
    if [ -f "compose.yaml" ]; then
        echo -e "${BLUE}🐳 Starting Docker services...${NC}"
        docker-compose up -d postgres redis
        
        # Wait for services to be ready
        echo -e "${BLUE}⏳ Waiting for services to be ready...${NC}"
        sleep 10
        
        # Initialize database (skip if already initialized)
        if [ -f "initdb.sh" ]; then
            echo -e "${BLUE}🗄️  Initializing database...${NC}"
            chmod +x initdb.sh
            # Set required environment variables for initdb.sh
            export POSTGRES_PASSWORD="postgres_root_password"
            export DB_NAME="wipsie"
            export DB_USER="wipsie_user"
            export DB_PASSWORD="wipsie_password"
            ./initdb.sh || echo -e "${YELLOW}⚠️  Database may already be initialized${NC}"
        fi
        
        echo -e "${GREEN}✅ Infrastructure services started!${NC}"
    else
        echo -e "${YELLOW}⚠️  No compose.yaml found, skipping infrastructure setup${NC}"
    fi
}

# Function to start backend services
start_backend() {
    echo -e "${YELLOW}🔧 Starting backend services...${NC}"
    
    # Determine which virtual environment to use
    local venv_path=""
    if [ -d "venv_container" ]; then
        venv_path="venv_container"
    elif [ -d ".venv" ]; then
        venv_path=".venv"
    else
        echo -e "${RED}❌ No virtual environment found. Run setup first.${NC}"
        return 1
    fi
    
    # Activate Python environment
    source "$venv_path/bin/activate"
    
    # Start FastAPI server in background
    echo -e "${BLUE}🌐 Starting FastAPI server on port $BACKEND_PORT...${NC}"
    uvicorn backend.main:app --reload --host 0.0.0.0 --port $BACKEND_PORT &
    BACKEND_PID=$!
    
    # Wait a moment for server to start
    sleep 3
    
    # Start Celery worker in background
    echo -e "${BLUE}⚙️ Starting Celery worker...${NC}"
    if [ -f "scripts/start_worker.py" ]; then
        python scripts/start_worker.py &
        WORKER_PID=$!
    else
        celery -A backend.workers.celery_app worker --loglevel=info --concurrency=$WORKER_CONCURRENCY &
        WORKER_PID=$!
    fi
    
    echo -e "${GREEN}✅ Backend services started!${NC}"
    echo -e "${BLUE}📊 FastAPI: http://localhost:$BACKEND_PORT${NC}"
    echo -e "${BLUE}📚 API Docs: http://localhost:$BACKEND_PORT/docs${NC}"
}

# Function to start frontend services
start_frontend() {
    echo -e "${YELLOW}🎨 Starting frontend services...${NC}"
    
    if [ -d "frontend/wipsie-app" ]; then
        cd frontend/wipsie-app
        
        echo -e "${BLUE}🅰️ Starting Angular development server...${NC}"
        npm start &
        FRONTEND_PID=$!
        
        cd ../..
        
        echo -e "${GREEN}✅ Frontend services started!${NC}"
        echo -e "${BLUE}🎨 Angular: http://localhost:$FRONTEND_PORT${NC}"
    else
        echo -e "${YELLOW}⚠️  No frontend directory found, skipping frontend startup${NC}"
    fi
}

# Function to show running services
show_services() {
    echo -e "${PURPLE}📊 Running Services:${NC}"
    echo "====================="
    echo -e "${BLUE}🌐 FastAPI Backend:    http://localhost:$BACKEND_PORT${NC}"
    echo -e "${BLUE}📚 API Documentation: http://localhost:$BACKEND_PORT/docs${NC}"
    echo -e "${BLUE}🎨 Angular Frontend:   http://localhost:$FRONTEND_PORT${NC}"
    echo -e "${BLUE}🗄️  PostgreSQL:        localhost:5432${NC}"
    echo -e "${BLUE}🔴 Redis:             localhost:6379${NC}"
    echo -e "${BLUE}⚙️ Celery Worker:     Running${NC}"
    echo ""
    echo -e "${CYAN}💡 Useful Commands:${NC}"
    echo "  🔍 Check logs:       docker-compose logs -f"
    echo "  🛑 Stop services:    docker-compose down"
    echo "  🔄 Restart backend:  pkill -f uvicorn && uvicorn backend.main:app --reload"
    echo "  📊 Monitor queues:   celery -A backend.workers.celery_app flower"
}

# Function to setup development tools
setup_dev_tools() {
    echo -e "${YELLOW}🛠️  Setting up development tools...${NC}"
    
    # Determine which virtual environment to use
    local venv_path=""
    if [ -d "venv_container" ]; then
        venv_path="venv_container"
    elif [ -d ".venv" ]; then
        venv_path=".venv"
    else
        echo -e "${RED}❌ No virtual environment found. Run setup first.${NC}"
        return 1
    fi
    
    # Activate Python environment
    source "$venv_path/bin/activate"
    
    # Install development tools
    pip install black isort flake8 pytest pytest-asyncio
    
    # Setup pre-commit hooks (optional)
    if command -v pre-commit &> /dev/null; then
        pre-commit install
        echo -e "${GREEN}✅ Pre-commit hooks installed!${NC}"
    fi
    
    echo -e "${GREEN}✅ Development tools ready!${NC}"
}

# Function to handle cleanup on exit
cleanup() {
    echo -e "\n${YELLOW}🧹 Cleaning up...${NC}"
    
    # Kill background processes
    if [ ! -z "$BACKEND_PID" ]; then
        kill $BACKEND_PID 2>/dev/null || true
    fi
    
    if [ ! -z "$WORKER_PID" ]; then
        kill $WORKER_PID 2>/dev/null || true
    fi
    
    if [ ! -z "$FRONTEND_PID" ]; then
        kill $FRONTEND_PID 2>/dev/null || true
    fi
    
    echo -e "${GREEN}✅ Cleanup completed!${NC}"
}

# Function to show help
show_help() {
    echo -e "${CYAN}Wipsie Development Runner${NC}"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  start           Start all development services (default)"
    echo "  stop            Stop all services"
    echo "  restart         Restart all services"
    echo "  backend-only    Start only backend services"
    echo "  frontend-only   Start only frontend services"
    echo "  setup           Setup development environment"
    echo "  status          Show service status"
    echo "  logs            Show service logs"
    echo "  clean           Clean up development environment"
    echo "  help            Show this help message"
    echo ""
    echo "Environment Variables:"
    echo "  BACKEND_PORT    Backend server port (default: 8000)"
    echo "  FRONTEND_PORT   Frontend server port (default: 4200)"
    echo "  WORKER_CONCURRENCY  Celery worker concurrency (default: 4)"
}

# Trap to handle cleanup on script exit
trap cleanup EXIT

# Main execution
main() {
    local command="${1:-start}"
    
    case "$command" in
        "start")
            show_banner
            check_prerequisites
            setup_python_env
            setup_node_env
            start_infrastructure
            start_backend
            start_frontend
            show_services
            
            echo -e "${GREEN}🎉 All services started successfully!${NC}"
            echo -e "${YELLOW}Press Ctrl+C to stop all services${NC}"
            
            # Keep script running
            wait
            ;;
        
        "stop")
            echo -e "${YELLOW}🛑 Stopping all services...${NC}"
            docker-compose down
            pkill -f "uvicorn\|celery\|ng serve" || true
            echo -e "${GREEN}✅ All services stopped!${NC}"
            ;;
        
        "restart")
            $0 stop
            sleep 2
            $0 start
            ;;
        
        "backend-only")
            show_banner
            check_prerequisites
            setup_python_env
            start_infrastructure
            start_backend
            show_services
            wait
            ;;
        
        "frontend-only")
            show_banner
            setup_node_env
            start_frontend
            wait
            ;;
        
        "setup")
            show_banner
            check_prerequisites
            setup_python_env
            setup_node_env
            setup_dev_tools
            echo -e "${GREEN}🎉 Development environment setup completed!${NC}"
            ;;
        
        "status")
            echo -e "${BLUE}📊 Service Status:${NC}"
            docker-compose ps
            ;;
        
        "logs")
            docker-compose logs -f
            ;;
        
        "clean")
            echo -e "${YELLOW}🧹 Cleaning development environment...${NC}"
            docker-compose down -v
            rm -rf .venv venv_container node_modules frontend/wipsie-app/node_modules
            echo -e "${GREEN}✅ Environment cleaned!${NC}"
            ;;
        
        "help")
            show_help
            ;;
        
        *)
            echo -e "${RED}❌ Unknown command: $command${NC}"
            show_help
            exit 1
            ;;
    esac
}

# Execute main function with all arguments
main "$@"
