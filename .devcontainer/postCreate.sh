#!/bin/bash

echo "🚀 Setting up the awesome full-stack application..."

# Install Python dependencies
echo "📦 Installing Python dependencies..."
pip install -r .devcontainer/requirements.txt

# Create project structure
echo "📁 Creating project structure..."
mkdir -p backend/{api,core,db,models,schemas,services,utils,tests}
mkdir -p frontend
mkdir -p aws-lambda/{functions,layers,templates}
mkdir -p scripts
mkdir -p docs

# Initialize FastAPI backend
echo "🐍 Setting up FastAPI backend..."
cat > backend/main.py << 'EOF'
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(
    title="Wipsie Full Stack API",
    description="A comprehensive full-stack application with FastAPI, Angular, PostgreSQL, and AWS Lambda",
    version="1.0.0"
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:4200"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
async def root():
    return {"message": "Welcome to Wipsie Full Stack API! 🚀"}

@app.get("/health")
async def health_check():
    return {"status": "healthy", "message": "API is running smoothly!"}
EOF

# Create Angular frontend
echo "🅰️ Creating Angular frontend..."
cd frontend
if [ ! -d "wipsie-app" ]; then
    ng new wipsie-app --routing --style=scss --skip-git
fi
cd ..

# Create environment configuration
echo "⚙️ Setting up environment configuration..."
cat > .env << 'EOF'
# Database Configuration
DATABASE_URL=postgresql://postgres:postgres@db:5432/wipsie_db
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_DB=wipsie_db

# Redis Configuration
REDIS_URL=redis://redis:6379

# FastAPI Configuration
SECRET_KEY=your-secret-key-change-in-production
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# AWS Configuration
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key

# Environment
ENVIRONMENT=development
DEBUG=true
EOF

# Create basic project files
echo "📄 Creating project configuration files..."

# Create README
cat > README.md << 'EOF'
# Wipsie Full Stack Application 🚀

A comprehensive full-stack application built with:
- **Backend**: Python FastAPI
- **Frontend**: Angular 17
- **Database**: PostgreSQL
- **Cache**: Redis
- **Cloud**: AWS Lambda functions
- **Background Tasks**: Celery

## Getting Started

1. Open in VS Code with dev containers
2. The application will be automatically set up
3. Backend API: http://localhost:8000
4. Frontend: http://localhost:4200
5. API Documentation: http://localhost:8000/docs

## Project Structure

```
├── backend/           # FastAPI backend
├── frontend/          # Angular frontend
├── aws-lambda/        # AWS Lambda functions
├── scripts/           # Utility scripts
└── docs/             # Documentation
```

## Development

- Backend: `uvicorn backend.main:app --reload --host 0.0.0.0 --port 8000`
- Frontend: `cd frontend/wipsie-app && ng serve --host 0.0.0.0`
- Database migrations: `alembic upgrade head`
EOF

echo "✅ Setup complete! Your awesome full-stack application is ready!"
echo "🌐 Backend will be available at: http://localhost:8000"
echo "🅰️ Frontend will be available at: http://localhost:4200"
echo "📖 API Documentation: http://localhost:8000/docs"
