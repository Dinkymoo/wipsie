# Worker Architecture Migration Guide

## 🏗️ **New Structure**

The Celery worker has been refactored from a single file to a modular architecture:

```
backend/workers/
├── __init__.py              # Package init with task imports
├── celery_app.py           # Celery configuration
├── worker.py               # Main worker entry point
└── tasks/
    ├── __init__.py
    ├── data_processing.py  # Data tasks + enrichers
    ├── general.py          # General purpose tasks
    ├── email.py           # Email/SES tasks
    └── notifications.py   # Multi-channel notifications
```

## 🔄 **Migration Changes**

### **Old Command:**
```bash
celery -A celery_worker worker --loglevel=info --concurrency=1
```

### **New Commands:**
```bash
# Using the new script
python scripts/start_worker.py

# Or directly with Celery
celery -A backend.workers.celery_app worker --loglevel=info --concurrency=4
```

## 📋 **Task Mapping**

| Old Task | New Location |
|----------|--------------|
| `process_default_message` | `backend.workers.tasks.data_processing.process_default_message` |
| `process_data_polling` | `backend.workers.tasks.data_processing.process_data_polling` |
| `process_task` | `backend.workers.tasks.general.process_task` |
| `send_notification` | `backend.workers.tasks.notifications.send_notification` |
| `notify_task_completion` | `backend.workers.tasks.notifications.notify_task_completion` |
| `process_email_queue` | `backend.workers.tasks.email.process_email_queue` |

## ✨ **New Features**

1. **Data Enricher**: `enrich_data` task for data enhancement
2. **Health Check**: `health_check` task for monitoring
3. **Batch Processing**: `process_batch` task for bulk operations
4. **Alert System**: `send_alert` task for high-priority notifications
5. **Better Organization**: Tasks grouped by function

## 🚀 **Benefits**

- ✅ **Modular**: Easy to add new task types
- ✅ **Scalable**: Better organization for large teams
- ✅ **Maintainable**: Clear separation of concerns
- ✅ **Production Ready**: Optimized worker settings
- ✅ **Type Safety**: Better imports and structure

## 🧪 **Testing**

Run the architecture test:
```bash
python scripts/test_worker_architecture.py
```

## 📝 **Notes**

- The old `celery_worker.py` file has been backed up
- All existing functionality is preserved
- Task routing is automatically configured
- Import paths have changed but functionality remains the same
