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
