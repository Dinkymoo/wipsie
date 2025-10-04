# 🚀 Wipsie Full Stack Application

A modern, cloud-native full-stack application built with **FastAPI**, **Angular**, **PostgreSQL**, **Redis**, **AWS SQS/SES**, and **Celery**.

## 📁 Project Structure

```
wipsie/
├── 📚 Documentation
│   ├── README.md                 # This file
│   ├── GETTING_STARTED.md        # Quick start guide
│   └── docs/                     # Detailed documentation
│
├── 🚀 Quick Start
│   ├── run_dev.sh               # Development environment runner
│   ├── initdb.sh                # Database initialization
│   └── compose.yaml             # Docker orchestration
│
├── ⚙️  Configuration
│   ├── requirements.txt         # Python dependencies
│   ├── package.json            # Node.js dependencies
│   ├── alembic.ini             # Database migrations config
│   ├── catalog-info.yaml       # Backstage service catalog
│   └── .env                    # Environment variables
│
├── 💻 Application Code
│   ├── backend/                # FastAPI backend application
│   ├── frontend/               # Angular frontend application
│   └── scripts/                # Utility scripts
│
├── 🐳 Infrastructure
│   ├── docker/                 # Docker configurations
│   ├── aws-lambda/             # Serverless functions
│   └── alembic/                # Database migrations
│
├── 🛠️  Development Tools
│   ├── tools/                  # AWS management utilities
│   ├── examples/               # Code examples and demos
│   └── archive/                # Deprecated/backup files
```

## 🏃‍♂️ Quick Start

```bash
# Setup development environment
./run_dev.sh setup

# Start all services
./run_dev.sh start

# Start only backend services
./run_dev.sh backend-only

# Check status
./run_dev.sh status

# Stop everything
./run_dev.sh stop
```

## 🌐 Access Points

- **🌐 API**: http://localhost:8000
- **📚 API Docs**: http://localhost:8000/docs  
- **🎨 Frontend**: http://localhost:4200
- **📊 Task Monitor**: http://localhost:5555 (Flower)
- **🗄️ Database Admin**: http://localhost:8080 (Adminer)

## 🏗️ Architecture

- **Frontend**: Angular with TypeScript
- **Backend**: FastAPI with Python
- **Database**: PostgreSQL with SQLAlchemy
- **Cache**: Redis
- **Queue**: AWS SQS with Celery workers
- **Email**: AWS SES
- **Deployment**: Docker with Nginx reverse proxy

## 📊 Features

✅ **Modern Tech Stack**  
✅ **Microservices Architecture**  
✅ **Background Task Processing**  
✅ **Email Notifications**  
✅ **Database Migrations**  
✅ **Docker Orchestration**  
✅ **Development Tools**  
✅ **Production Ready**  

## 🔧 Development

```bash
# Run tests
python -m pytest

# Format code  
black backend/
isort backend/

# Type checking
mypy backend/

# Security scan
safety check
```

## 🚀 Deployment

```bash
# Production deployment
docker-compose up -d

# Scale workers
docker-compose up -d --scale celery-worker=3

# View logs
docker-compose logs -f
```

## 📖 Documentation

- **[Getting Started](GETTING_STARTED.md)** - Quick setup guide
- **[API Documentation](docs/)** - Detailed API reference  
- **[Architecture Guide](docs/ARCHITECTURE.md)** - System design
- **[Development Guide](docs/DEVELOPER_GUIDE.md)** - Development workflow

## 🤝 Contributing

1. Clone the repository
2. Run `./run_dev.sh setup`
3. Make your changes
4. Run tests with `pytest`
5. Submit a pull request

---

**Built with ❤️ for learning and production use**
