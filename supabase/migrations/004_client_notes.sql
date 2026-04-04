-- Migration: client_notes table for immutable timeline-style notes
-- Part of Phase 2: Core Domain (Plan 02-03)

CREATE TABLE client_notes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  studio_id UUID NOT NULL REFERENCES studios(id) ON DELETE CASCADE,
  client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
  professional_id UUID NOT NULL REFERENCES professionals(id),
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indexes
CREATE INDEX idx_client_notes_client ON client_notes(client_id, created_at DESC);
CREATE INDEX idx_client_notes_studio ON client_notes(studio_id);

-- RLS
ALTER TABLE client_notes ENABLE ROW LEVEL SECURITY;

-- Notes are immutable: INSERT + SELECT only, no UPDATE/DELETE
CREATE POLICY "studio_select_notes" ON client_notes
  FOR SELECT
  USING (studio_id IN (SELECT studio_id FROM professionals WHERE user_id = auth.uid()));

CREATE POLICY "studio_insert_notes" ON client_notes
  FOR INSERT
  WITH CHECK (studio_id IN (SELECT studio_id FROM professionals WHERE user_id = auth.uid()));
