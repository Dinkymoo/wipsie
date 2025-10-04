# Tools Directory

This directory contains utility scripts and tools for managing the Wipsie infrastructure, particularly AWS services.

## Contents:

- `cleanup_us_queues.py` - Script to clean up US region SQS queues
- `create_eu_queues.py` - Script to create SQS queues in EU region
- `create_queues_direct.py` - Direct queue creation utility

## Usage:

```bash
# Create EU queues
python tools/create_eu_queues.py

# Clean up old US queues  
python tools/cleanup_us_queues.py
```

## Note:
Make sure your AWS credentials are configured before running these tools.
