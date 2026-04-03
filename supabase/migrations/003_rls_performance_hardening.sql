-- ============================================================================
-- 003: RLS performance indices + SECURITY DEFINER hardening
-- Supports is_studio_owner() and is_studio_member() helper functions
-- ============================================================================

-- Index for is_studio_owner: studios.owner_id lookup
CREATE INDEX studios_owner_id_idx ON studios (owner_id);

-- Index for is_studio_member: professionals (user_id, studio_id) filtered by active
CREATE INDEX professionals_user_studio_active_idx
  ON professionals (user_id, studio_id)
  WHERE is_active = true;

-- Restrict helper functions to authenticated users only
REVOKE EXECUTE ON FUNCTION is_studio_owner(UUID) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION is_studio_member(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION is_studio_owner(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION is_studio_member(UUID) TO authenticated;
