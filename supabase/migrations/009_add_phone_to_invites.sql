-- Migration: 009_add_phone_to_invites.sql
-- Purpose: add phone column to professional_invites for WhatsApp integration

ALTER TABLE professional_invites
  ADD COLUMN phone TEXT;

-- ─── DOWN (reversible) ─────────────────────────────────────────────────────────
-- ALTER TABLE professional_invites DROP COLUMN phone;
