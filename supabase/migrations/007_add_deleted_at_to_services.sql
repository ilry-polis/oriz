-- Add soft-delete column to services (required by Phase 2 repository code)
ALTER TABLE services ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;
CREATE INDEX IF NOT EXISTS idx_services_active ON services(studio_id) WHERE deleted_at IS NULL;
