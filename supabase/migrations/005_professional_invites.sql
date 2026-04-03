-- Migration: 005_professional_invites.sql
-- Purpose: professional_invites table for the invite link onboarding flow (TEAM-02)
-- Invite links expire after 7 days; once used they are marked with used_at
-- Token lookup for accept-invite is done via backend service_role (no public RLS needed)

-- ─── Table ─────────────────────────────────────────────────────────────────────
CREATE TABLE professional_invites (
  token            UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  studio_id        UUID          NOT NULL REFERENCES studios(id) ON DELETE CASCADE,
  created_by       UUID          NOT NULL REFERENCES auth.users(id),
  name             TEXT          NOT NULL,
  service_ids      UUID[]        NOT NULL DEFAULT '{}',
  commission_type  TEXT          NOT NULL CHECK (commission_type IN ('percentage', 'fixed')),
  commission_value NUMERIC(10,2) NOT NULL DEFAULT 0,
  card_fee_policy  TEXT          NOT NULL DEFAULT 'studio'
                                 CHECK (card_fee_policy IN ('studio', 'professional', 'split')),
  expires_at       TIMESTAMPTZ   NOT NULL DEFAULT (now() + interval '7 days'),
  used_at          TIMESTAMPTZ,
  created_at       TIMESTAMPTZ   NOT NULL DEFAULT now()
);

-- ─── Indexes ───────────────────────────────────────────────────────────────────
-- Fast lookup by studio (for owner listing their invites)
CREATE INDEX idx_professional_invites_studio_id ON professional_invites(studio_id);

-- ─── RLS ───────────────────────────────────────────────────────────────────────
-- RLS is enabled for belt-and-suspenders protection even though token lookups
-- for accept-invite are done via service_role (bypasses RLS).
ALTER TABLE professional_invites ENABLE ROW LEVEL SECURITY;

-- Owner can manage (view, create, delete) invites for their own studio
CREATE POLICY "owner_select_invites" ON professional_invites
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM studios s
      WHERE s.id = professional_invites.studio_id
        AND s.owner_id = auth.uid()
    )
  );

CREATE POLICY "owner_insert_invites" ON professional_invites
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM studios s
      WHERE s.id = professional_invites.studio_id
        AND s.owner_id = auth.uid()
    )
  );

CREATE POLICY "owner_delete_invites" ON professional_invites
  FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM studios s
      WHERE s.id = professional_invites.studio_id
        AND s.owner_id = auth.uid()
    )
  );

-- ─── DOWN (reversible) ─────────────────────────────────────────────────────────
-- DROP TABLE IF EXISTS professional_invites;
