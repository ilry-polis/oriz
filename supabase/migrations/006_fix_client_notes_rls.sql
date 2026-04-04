-- Fix: client_notes RLS must allow studio owners (not just professionals)
-- Owner may not have a professionals row if they don't provide services themselves

DROP POLICY IF EXISTS "studio_select_notes" ON client_notes;
DROP POLICY IF EXISTS "studio_insert_notes" ON client_notes;

CREATE POLICY "studio_select_notes" ON client_notes
  FOR SELECT
  USING (
    studio_id IN (
      SELECT studio_id FROM professionals WHERE user_id = auth.uid()
    )
    OR
    studio_id IN (
      SELECT id FROM studios WHERE owner_id = auth.uid()
    )
  );

CREATE POLICY "studio_insert_notes" ON client_notes
  FOR INSERT
  WITH CHECK (
    studio_id IN (
      SELECT studio_id FROM professionals WHERE user_id = auth.uid()
    )
    OR
    studio_id IN (
      SELECT id FROM studios WHERE owner_id = auth.uid()
    )
  );
