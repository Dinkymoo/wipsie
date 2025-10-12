# 🚀 Wipsie Full Stack Application

A modern, cloud-native full-stack application built with **FastAPI**, **Angular**, **PostgreSQL**, and **AWS services**. Optimized for **cost-effective learning** with an **85% cost reduction** architecture.

## 💰 **Cost-Optimized Learning Environment**

**Monthly Cost: ~$13-18** (down from ~$87-91 - **85% savings!**)

- ✅ **RDS PostgreSQL**: Database learning ($13/month)
- ✅ **ECS + Lambda**: Container & serverless learning (free tier)
- ✅ **S3 + SQS**: Storage & messaging learning (~$1-3/month)
- ✅ **VPC + Security Groups**: Networking learning (free)
- 🔧 **Optional Services**: Enable as needed for specific learning modules

**[📖 View Complete Cost Optimization Guide →](docs/COST_OPTIMIZATION_COMPLETE.md)**

## 💰 Cost Optimization

This project implements aggressive cost optimization for learning environments:

### Quick Start - Ultra Budget ($13-18/month)
```bash
cd infrastructure
terraform apply -var-file=ultra-budget.tfvars -auto-approve
```

### Enable Services for Learning
```bash
# Database learning
terraform apply -var="enable_rds=true"

# Load balancing learning  
terraform apply -var="enable_alb=true"

# Caching learning
terraform apply -var="enable_redis=true"

# Private networking learning
terraform apply -var="enable_nat_gateway=true"
```

### Documentation
- **[Complete Cost Guide](docs/COST_OPTIMIZATION_COMPLETE.md)** - Detailed optimization documentation
- **[Quick Reference](docs/COST_OPTIMIZATION_QUICK_REFERENCE.md)** - Commands and summary
- **[Configuration Files](docs/CONFIGURATION_FILES_SUMMARY.md)** - All config files explained

## 🎓 **Learning Path**

| Phase | Monthly Cost | Services | Learning Focus |
|-------|--------------|----------|----------------|
| **Phase 1** | $13-18 | RDS + Core Services | Database, containers, basics |
| **Phase 2** | $29-34 | + Load Balancer | Traffic management, SSL |
| **Phase 3** | $41-46 | + Redis Cache | Performance, caching strategies |
| **Phase 4** | $86-91 | + NAT + CloudFront | Production architecture |

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
│   │   ├── core/               # Core application components
│   │   │   ├── config.py       # Application settings
│   │   │   ├── celery_app.py   # Celery configuration
│   │   │   └── db_functions/   # 🆕 SQLAlchemy ORM utilities
│   │   │       ├── session.py  # Database session management
│   │   │       ├── queries.py  # Repository pattern & query utils
│   │   │       └── utils.py    # Database admin utilities
│   │   ├── models/             # SQLAlchemy data models
│   │   ├── schemas/            # Pydantic schemas
│   │   ├── services/           # Business logic services
│   │   ├── workers/            # Celery worker modules
│   │   └── alembic/            # Database migrations
│   ├── frontend/               # Angular frontend application
│   └── scripts/                # Utility scripts
│
├── 🐳 Infrastructure
│   ├── docker/                 # Docker configurations
│   └── aws-lambda/             # Serverless functions
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
- **Database**: PostgreSQL with SQLAlchemy + 🆕 **Custom ORM utilities**
- **Cache**: Redis
- **Queue**: AWS SQS with Celery workers
- **Email**: AWS SES
- **Deployment**: Docker with Nginx reverse proxy
- **🆕 Database Layer**: Comprehensive SQLAlchemy utilities with repository pattern

### 🆕 Database Functions Module

The new `backend/core/db_functions/` provides:

- **Session Management**: Context managers and FastAPI dependencies
- **Repository Pattern**: Generic CRUD operations with `BaseRepository`
- **Query Utilities**: Advanced filtering, searching, and ordering
- **Admin Tools**: Table management, raw SQL execution, maintenance

```python
# Example usage
from backend.core.db_functions import get_db_session, BaseRepository
from backend.models import User

with get_db_session() as db:
    user_repo = BaseRepository(User, db)
    user = user_repo.get(1)
    users = user_repo.get_all(skip=0, limit=10)
```

## 📊 Features

✅ **Modern Tech Stack**  
✅ **Microservices Architecture**  
✅ **Background Task Processing**  
✅ **Email Notifications**  
✅ **Database Migrations**  
✅ **Docker Orchestration**  
✅ **Development Tools**  
✅ **Production Ready**  
✅ 🆕 **Advanced Database Layer** - SQLAlchemy utilities with repository pattern  
✅ 🆕 **Modular Architecture** - Clean separation of concerns  
✅ 🆕 **Comprehensive Error Handling** - Robust database operations  

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
