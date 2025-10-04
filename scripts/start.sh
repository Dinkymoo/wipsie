#!/bin/bash

echo "🚀 Starting Wipsie Full Stack Application..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if we're in the dev container
if [ ! -f /.devcontainer ]; then
    echo -e "${YELLOW}Warning: This script is designed to run in the dev container${NC}"
fi

# Function to check if a service is running
check_service() {
    local service=$1
    local port=$2
    echo -e "${BLUE}Checking $service on port $port...${NC}"
    
    if nc -z localhost $port; then
        echo -e "${GREEN}✅ $service is running on port $port${NC}"
        return 0
    else
        echo -e "${RED}❌ $service is not running on port $port${NC}"
        return 1
    fi
}

# Function to start a service in the background
start_service() {
    local name=$1
    local command=$2
    local logfile="/tmp/wipsie_${name}.log"
    
    echo -e "${BLUE}Starting $name...${NC}"
    eval "$command" > "$logfile" 2>&1 &
    local pid=$!
    echo $pid > "/tmp/wipsie_${name}.pid"
    echo -e "${GREEN}✅ $name started with PID $pid (logs: $logfile)${NC}"
}

# Function to stop services
stop_services() {
    echo -e "${YELLOW}Stopping services...${NC}"
    
    for pidfile in /tmp/wipsie_*.pid; do
        if [ -f "$pidfile" ]; then
            local pid=$(cat "$pidfile")
            local service=$(basename "$pidfile" .pid | sed 's/wipsie_//')
            
            if kill -0 $pid 2>/dev/null; then
                echo -e "${BLUE}Stopping $service (PID: $pid)...${NC}"
                kill $pid
                rm "$pidfile"
            fi
        fi
    done
}

# Handle Ctrl+C
trap stop_services EXIT

# Main menu
show_menu() {
    echo -e "\n${BLUE}=== Wipsie Full Stack Application ===${NC}"
    echo "1. Start all services"
    echo "2. Start backend only"
    echo "3. Start frontend only"
    echo "4. Start Celery worker"
    echo "5. Run database migrations"
    echo "6. Create Angular app (if not exists)"
    echo "7. Check service status"
    echo "8. View logs"
    echo "9. Stop all services"
    echo "0. Exit"
    echo -n "Choose an option: "
}

# Check database connection
check_database() {
    echo -e "${BLUE}Checking database connection...${NC}"
    python3 -c "
import psycopg2
try:
    conn = psycopg2.connect('postgresql://postgres:postgres@db:5432/wipsie_db')
    conn.close()
    print('✅ Database connection successful')
except Exception as e:
    print(f'❌ Database connection failed: {e}')
    exit(1)
" 2>/dev/null || echo -e "${RED}❌ Cannot connect to database${NC}"
}

# Start all services
start_all() {
    echo -e "${BLUE}Starting all services...${NC}"
    
    # Check dependencies first
    check_database
    
    # Start backend
    start_service "backend" "cd /workspaces/wipsie && python -m uvicorn backend.main:app --reload --host 0.0.0.0 --port 8000"
    sleep 3
    
    # Start frontend (if exists)
    if [ -d "/workspaces/wipsie/frontend/wipsie-app" ]; then
        start_service "frontend" "cd /workspaces/wipsie/frontend/wipsie-app && ng serve --host 0.0.0.0 --port 4200"
        sleep 3
    else
        echo -e "${YELLOW}⚠️ Frontend app not found. Create it first with option 6.${NC}"
    fi
    
    # Start Celery worker
    start_service "celery" "cd /workspaces/wipsie && celery -A backend.core.celery_app worker --loglevel=info"
    
    echo -e "\n${GREEN}🎉 All services started!${NC}"
    echo -e "${BLUE}📖 Backend API: http://localhost:8000${NC}"
    echo -e "${BLUE}📖 API Docs: http://localhost:8000/docs${NC}"
    echo -e "${BLUE}🅰️ Frontend: http://localhost:4200${NC}"
    echo -e "${BLUE}📊 Service status: Choose option 7${NC}"
}

# Create Angular app
create_angular_app() {
    echo -e "${BLUE}Creating Angular application...${NC}"
    
    if [ -d "/workspaces/wipsie/frontend/wipsie-app" ]; then
        echo -e "${YELLOW}⚠️ Angular app already exists${NC}"
        return
    fi
    
    mkdir -p /workspaces/wipsie/frontend
    cd /workspaces/wipsie/frontend
    
    echo -e "${BLUE}Running: ng new wipsie-app --routing --style=scss --skip-git${NC}"
    ng new wipsie-app --routing --style=scss --skip-git
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Angular app created successfully${NC}"
    else
        echo -e "${RED}❌ Failed to create Angular app${NC}"
    fi
}

# Check service status
check_status() {
    echo -e "${BLUE}=== Service Status ===${NC}"
    check_service "PostgreSQL" 5432
    check_service "Redis" 6379
    check_service "FastAPI Backend" 8000
    check_service "Angular Frontend" 4200
    
    echo -e "\n${BLUE}=== Running Processes ===${NC}"
    for pidfile in /tmp/wipsie_*.pid; do
        if [ -f "$pidfile" ]; then
            local pid=$(cat "$pidfile")
            local service=$(basename "$pidfile" .pid | sed 's/wipsie_//')
            
            if kill -0 $pid 2>/dev/null; then
                echo -e "${GREEN}✅ $service (PID: $pid)${NC}"
            else
                echo -e "${RED}❌ $service (PID: $pid) - not running${NC}"
                rm "$pidfile"
            fi
        fi
    done
}

# View logs
view_logs() {
    echo -e "${BLUE}=== Available Logs ===${NC}"
    local logs=($(ls /tmp/wipsie_*.log 2>/dev/null))
    
    if [ ${#logs[@]} -eq 0 ]; then
        echo -e "${YELLOW}No log files found${NC}"
        return
    fi
    
    for i in "${!logs[@]}"; do
        local service=$(basename "${logs[$i]}" .log | sed 's/wipsie_//')
        echo "$((i+1)). $service"
    done
    
    echo -n "Choose a log to view (or 0 to return): "
    read choice
    
    if [ "$choice" -gt 0 ] && [ "$choice" -le "${#logs[@]}" ]; then
        local logfile="${logs[$((choice-1))]}"
        echo -e "${BLUE}Showing last 50 lines of $logfile (Press Ctrl+C to exit):${NC}"
        tail -f -n 50 "$logfile"
    fi
}

# Run database migrations
run_migrations() {
    echo -e "${BLUE}Running database migrations...${NC}"
    cd /workspaces/wipsie
    
    # Create alembic.ini if it doesn't exist
    if [ ! -f "alembic.ini" ]; then
        echo -e "${BLUE}Initializing Alembic...${NC}"
        alembic init alembic
    fi
    
    # Run migrations
    alembic upgrade head
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Migrations completed successfully${NC}"
    else
        echo -e "${RED}❌ Migration failed${NC}"
    fi
}

# Main loop
while true; do
    show_menu
    read choice
    
    case $choice in
        1)
            start_all
            ;;
        2)
            start_service "backend" "cd /workspaces/wipsie && python -m uvicorn backend.main:app --reload --host 0.0.0.0 --port 8000"
            echo -e "${GREEN}✅ Backend started at http://localhost:8000${NC}"
            ;;
        3)
            if [ -d "/workspaces/wipsie/frontend/wipsie-app" ]; then
                start_service "frontend" "cd /workspaces/wipsie/frontend/wipsie-app && ng serve --host 0.0.0.0 --port 4200"
                echo -e "${GREEN}✅ Frontend started at http://localhost:4200${NC}"
            else
                echo -e "${RED}❌ Frontend app not found. Create it first with option 6.${NC}"
            fi
            ;;
        4)
            start_service "celery" "cd /workspaces/wipsie && celery -A backend.core.celery_app worker --loglevel=info"
            echo -e "${GREEN}✅ Celery worker started${NC}"
            ;;
        5)
            run_migrations
            ;;
        6)
            create_angular_app
            ;;
        7)
            check_status
            ;;
        8)
            view_logs
            ;;
        9)
            stop_services
            echo -e "${GREEN}✅ All services stopped${NC}"
            ;;
        0)
            stop_services
            echo -e "${GREEN}👋 Goodbye!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option. Please try again.${NC}"
            ;;
    esac
    
    echo -e "\nPress Enter to continue..."
    read
done
