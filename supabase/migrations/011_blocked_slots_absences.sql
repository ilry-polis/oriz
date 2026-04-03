-- ============================================================================
-- Migration 011: Add absence fields to blocked_slots
-- Phase 03 — Scheduling Engine
-- ============================================================================

-- 1. Add title column (non-nullable with default to avoid breaking existing rows)
ALTER TABLE blocked_slots
  ADD COLUMN IF NOT EXISTS title TEXT NOT NULL DEFAULT 'Ausência';

-- 2. Add recurrence_rule JSONB (nullable — only set for recurring absences)
--    Expected shape: { "frequency": "weekly", "days": [1, 3], "until": "2026-12-31" | null }
ALTER TABLE blocked_slots
  ADD COLUMN IF NOT EXISTS recurrence_rule JSONB;

-- 3. Add excluded_dates for removing specific occurrences from a recurring absence
ALTER TABLE blocked_slots
  ADD COLUMN IF NOT EXISTS excluded_dates DATE[] NOT NULL DEFAULT '{}';

-- 4. Index for efficiently querying recurring blocked slots by professional
CREATE INDEX IF NOT EXISTS blocked_slots_recurrence_idx
  ON blocked_slots (professional_id)
  WHERE recurrence_rule IS NOT NULL;

-- DOWN (for reference):
-- DROP INDEX IF EXISTS blocked_slots_recurrence_idx;
-- ALTER TABLE blocked_slots DROP COLUMN IF EXISTS excluded_dates;
-- ALTER TABLE blocked_slots DROP COLUMN IF EXISTS recurrence_rule;
-- ALTER TABLE blocked_slots DROP COLUMN IF EXISTS title;
