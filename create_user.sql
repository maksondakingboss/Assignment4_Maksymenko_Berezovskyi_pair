-- PostgreSQL version. Run as a superuser or database owner.
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'schedule_reader1') THEN
        CREATE ROLE schedule_reader1 LOGIN PASSWORD '123456Aa@';
    END IF;
END
$$;

GRANT CONNECT ON DATABASE uni_db TO schedule_reader1;
GRANT USAGE ON SCHEMA public TO schedule_reader1;
GRANT SELECT ON schedules TO schedule_reader1;

-- Check grants:
-- \dp schedules
