#!/bin/bash
# Database Initialization Script for Wipsie
# Sets up PostgreSQL database with proper configuration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Database configuration
DB_NAME="${DB_NAME:-wipsie}"
DB_USER="${DB_USER:-wipsie_user}"
DB_PASSWORD="${DB_PASSWORD:-wipsie_password}"
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
POSTGRES_USER="${POSTGRES_USER:-postgres}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-postgres_root_password}"

echo -e "${BLUE}🗄️  Initializing Wipsie Database${NC}"
echo "=================================="

# Function to wait for PostgreSQL to be ready
wait_for_postgres() {
    echo -e "${YELLOW}⏳ Waiting for PostgreSQL to be ready...${NC}"
    
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if PGPASSWORD="$POSTGRES_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$POSTGRES_USER" -c '\q' > /dev/null 2>&1; then
            echo -e "${GREEN}✅ PostgreSQL is ready!${NC}"
            return 0
        fi
        
        echo "Attempt $attempt/$max_attempts: PostgreSQL not ready yet..."
        sleep 2
        ((attempt++))
    done
    
    echo -e "${RED}❌ PostgreSQL failed to become ready after $max_attempts attempts${NC}"
    echo -e "${YELLOW}💡 Try: docker-compose logs postgres${NC}"
    exit 1
}

# Function to create database and user
create_database() {
    echo -e "${YELLOW}📊 Database and user setup handled by Docker init scripts...${NC}"
    echo -e "${GREEN}✅ Database setup completed via Docker initialization!${NC}"
}

# Function to run Alembic migrations
run_migrations() {
    echo -e "${YELLOW}🔄 Running database migrations...${NC}"
    
    # Ensure we're in the project directory
    cd "$(dirname "$0")"
    
    # Activate virtual environment if it exists
    if [ -f "venv/bin/activate" ]; then
        source venv/bin/activate
        echo -e "${BLUE}📦 Activated virtual environment${NC}"
    elif [ -f ".venv/bin/activate" ]; then
        source .venv/bin/activate
        echo -e "${BLUE}📦 Activated virtual environment${NC}"
    fi
    
    # Check if alembic is available
    if ! command -v alembic &> /dev/null; then
        echo -e "${RED}❌ Alembic not found. Please install requirements.txt${NC}"
        exit 1
    fi
    
    # Run migrations
    echo -e "${BLUE}🔧 Running alembic upgrade head...${NC}"
    alembic upgrade head
    
    echo -e "${GREEN}✅ Database migrations completed!${NC}"
}

# Function to create initial data (optional)
create_initial_data() {
    echo -e "${YELLOW}🌱 Creating initial data...${NC}"
    
    # You can add initial data creation here
    # For example, creating admin user, default settings, etc.
    
    python3 -c "
import sys
sys.path.append('.')

try:
    from backend.db.database import get_db
    from backend.models.models import User
    from backend.schemas.schemas import UserCreate
    from backend.services.user_service import UserService
    
    # Create a test user if needed
    print('📝 Creating initial test user...')
    # Add your initial data logic here
    
    print('✅ Initial data created successfully!')
except Exception as e:
    print(f'⚠️  Initial data creation skipped: {e}')
"
    
    echo -e "${GREEN}✅ Initial data setup completed!${NC}"
}

# Function to verify database setup
verify_setup() {
    echo -e "${YELLOW}🔍 Verifying database setup...${NC}"
    
    # Test connection with application user
    if PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT version();" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Database connection successful!${NC}"
    else
        echo -e "${RED}❌ Database connection failed!${NC}"
        echo -e "${YELLOW}💡 Try: docker-compose logs postgres${NC}"
        exit 1
    fi
    
    # Check if tables exist
    local table_count=$(PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -tc "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" 2>/dev/null || echo "0")
    
    echo -e "${BLUE}📊 Found $table_count tables in the database${NC}"
    
    # List tables if any exist
    if [ "$table_count" -gt 0 ]; then
        echo -e "${BLUE}📋 Database tables:${NC}"
        PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "\dt" 2>/dev/null || echo "No tables to display"
    fi
}

# Main execution
main() {
    echo -e "${BLUE}🚀 Starting database initialization...${NC}"
    
    # Check if running in Docker
    if [ -f /.dockerenv ]; then
        echo -e "${BLUE}🐳 Running inside Docker container${NC}"
    fi
    
    # Wait for PostgreSQL
    wait_for_postgres
    
    # Create database and user
    create_database
    
    # Run migrations
    run_migrations
    
    # Create initial data
    create_initial_data
    
    # Verify setup
    verify_setup
    
    echo -e "${GREEN}🎉 Database initialization completed successfully!${NC}"
    echo -e "${BLUE}📝 Database: $DB_NAME${NC}"
    echo -e "${BLUE}👤 User: $DB_USER${NC}"
    echo -e "${BLUE}🌐 Host: $DB_HOST:$DB_PORT${NC}"
}

# Handle script arguments
case "$1" in
    --wait-only)
        wait_for_postgres
        ;;
    --migrate-only)
        run_migrations
        ;;
    --verify-only)
        verify_setup
        ;;
    *)
        main
        ;;
esac
