-- ============================================================================
-- Oriz — Package Multi-Service Support
-- Replaces packages.service_id (1:1) with package_services junction table (M:N)
-- ============================================================================

-- ── 1. Create junction table ─────────────────────────────────────────────────

CREATE TABLE package_services (
  package_id UUID NOT NULL REFERENCES packages(id) ON DELETE CASCADE,
  service_id UUID NOT NULL REFERENCES services(id) ON DELETE CASCADE,
  studio_id  UUID NOT NULL REFERENCES studios(id) ON DELETE CASCADE,
  PRIMARY KEY (package_id, service_id)
);

CREATE INDEX package_services_service_idx ON package_services (service_id);

-- RLS
ALTER TABLE package_services ENABLE ROW LEVEL SECURITY;

CREATE POLICY "package_services_select" ON package_services
  FOR SELECT USING (studio_id = (auth.jwt()->>'studio_id')::UUID);

CREATE POLICY "package_services_insert" ON package_services
  FOR INSERT WITH CHECK (studio_id = (auth.jwt()->>'studio_id')::UUID);

CREATE POLICY "package_services_delete" ON package_services
  FOR DELETE USING (studio_id = (auth.jwt()->>'studio_id')::UUID);

-- ── 2. Migrate existing data ─────────────────────────────────────────────────

INSERT INTO package_services (package_id, service_id, studio_id)
SELECT id, service_id, studio_id
FROM packages
WHERE service_id IS NOT NULL;

-- ── 3. Drop old column ──────────────────────────────────────────────────────

ALTER TABLE packages DROP COLUMN service_id;
