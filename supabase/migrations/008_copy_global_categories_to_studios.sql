-- Migration 008: Copy global categories to studios
--
-- Problem: Services currently reference global categories (studio_id IS NULL).
-- New behavior: Service form only shows studio-specific categories.
-- This migration copies global categories used by each studio into studio-specific
-- copies, then re-points the services to the new studio copies.
--
-- Safe: idempotent, non-destructive, preserves original data.

-- Step 1: For each studio that has services referencing global categories,
-- create studio-specific copies of those global categories.
INSERT INTO service_categories (studio_id, name, icon, position)
SELECT DISTINCT
  s.studio_id,
  gc.name,
  gc.icon,
  gc.position
FROM services s
JOIN service_categories gc ON gc.id = s.category_id AND gc.studio_id IS NULL
WHERE s.studio_id IS NOT NULL
  AND s.deleted_at IS NULL
  -- Don't duplicate if studio already has a category with the same name
  AND NOT EXISTS (
    SELECT 1 FROM service_categories sc
    WHERE sc.studio_id = s.studio_id
      AND sc.name = gc.name
  );

-- Step 2: Re-point services from global categories to their studio copies.
UPDATE services s
SET category_id = sc.id
FROM service_categories gc, service_categories sc
WHERE s.category_id = gc.id
  AND gc.studio_id IS NULL
  AND sc.studio_id = s.studio_id
  AND sc.name = gc.name
  AND s.deleted_at IS NULL;
