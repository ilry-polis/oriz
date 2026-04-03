-- ============================================================================
-- Migration 010: Add pending status to appointments, revise exclusion constraint
-- Phase 03 — Scheduling Engine
-- ============================================================================

-- 1. Drop existing CHECK constraint on status
ALTER TABLE appointments
  DROP CONSTRAINT IF EXISTS appointments_status_check;

-- 2. Add new CHECK constraint with 'pending' status included
ALTER TABLE appointments
  ADD CONSTRAINT appointments_status_check
  CHECK (status IN ('pending', 'confirmed', 'completed', 'cancelled', 'no_show'));

-- 3. Change DEFAULT from 'confirmed' to 'pending'
ALTER TABLE appointments
  ALTER COLUMN status SET DEFAULT 'pending';

-- 4. Drop existing exclusion constraint
ALTER TABLE appointments
  DROP CONSTRAINT IF EXISTS appointments_no_overlap;

-- 5. Recreate exclusion constraint: no_show slots become available for rebooking
--    Only active appointments (pending, confirmed, completed) block the slot
ALTER TABLE appointments
  ADD CONSTRAINT appointments_no_overlap
  EXCLUDE USING gist (
    professional_id WITH =,
    tstzrange(start_time, end_time) WITH &&
  ) WHERE (status NOT IN ('cancelled', 'no_show'));

-- 6. Add confirmation_hours_before to studios (consumed by Phase 5.1/6 notifications)
ALTER TABLE studios
  ADD COLUMN IF NOT EXISTS confirmation_hours_before INTEGER NOT NULL DEFAULT 24;

-- DOWN (for reference):
-- ALTER TABLE studios DROP COLUMN IF EXISTS confirmation_hours_before;
-- ALTER TABLE appointments DROP CONSTRAINT IF EXISTS appointments_no_overlap;
-- ALTER TABLE appointments ADD CONSTRAINT appointments_no_overlap
--   EXCLUDE USING gist (professional_id WITH =, tstzrange(start_time, end_time) WITH &&)
--   WHERE (status != 'cancelled');
-- ALTER TABLE appointments ALTER COLUMN status SET DEFAULT 'confirmed';
-- ALTER TABLE appointments DROP CONSTRAINT IF EXISTS appointments_status_check;
-- ALTER TABLE appointments ADD CONSTRAINT appointments_status_check
--   CHECK (status IN ('confirmed', 'completed', 'cancelled', 'no_show'));
