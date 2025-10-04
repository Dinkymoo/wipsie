-- Initialize Wipsie Database
-- This script runs automatically when PostgreSQL container starts

-- Create wipsie user if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_user WHERE usename = 'wipsie_user') THEN
        CREATE USER wipsie_user WITH PASSWORD 'wipsie_password';
    END IF;
END $$;

-- Grant privileges on the wipsie database
GRANT ALL PRIVILEGES ON DATABASE wipsie TO wipsie_user;

-- Grant schema privileges
GRANT ALL ON SCHEMA public TO wipsie_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO wipsie_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO wipsie_user;

-- Grant future object privileges
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO wipsie_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO wipsie_user;

-- Log success
\echo 'Wipsie database initialization completed successfully!'
