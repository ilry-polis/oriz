-- ============================================================================
-- 002: Fix RLS policies — restrict access to actual studio owner/members
-- Problem: original policies used `studio_id IN (SELECT id FROM studios)`
-- which returns ALL studios (studios has public SELECT), allowing any
-- authenticated user to access any studio's data.
-- ============================================================================

-- ============================================================================
-- Helper functions (SECURITY DEFINER to avoid RLS recursion)
-- ============================================================================
CREATE OR REPLACE FUNCTION public.is_studio_owner(_studio_id UUID)
RETURNS BOOLEAN
LANGUAGE sql SECURITY DEFINER STABLE
SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.studios
    WHERE id = _studio_id AND owner_id = auth.uid()
  );
$$;

CREATE OR REPLACE FUNCTION public.is_studio_member(_studio_id UUID)
RETURNS BOOLEAN
LANGUAGE sql SECURITY DEFINER STABLE
SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.studios
    WHERE id = _studio_id AND owner_id = auth.uid()
  ) OR EXISTS (
    SELECT 1 FROM public.professionals
    WHERE studio_id = _studio_id AND user_id = auth.uid() AND is_active = true
  );
$$;

-- ============================================================================
-- professionals — SELECT public (booking page); mutations → owner
-- ============================================================================
DROP POLICY professionals_mutate ON professionals;

CREATE POLICY professionals_insert ON professionals
  FOR INSERT WITH CHECK (is_studio_owner(studio_id));

CREATE POLICY professionals_update ON professionals
  FOR UPDATE USING (is_studio_owner(studio_id))
  WITH CHECK (is_studio_owner(studio_id));

CREATE POLICY professionals_delete ON professionals
  FOR DELETE USING (is_studio_owner(studio_id));

-- ============================================================================
-- service_categories — SELECT public; mutations → owner (studio_id NOT NULL)
-- ============================================================================
DROP POLICY service_categories_insert ON service_categories;
DROP POLICY service_categories_update ON service_categories;
DROP POLICY service_categories_delete ON service_categories;

CREATE POLICY service_categories_insert ON service_categories
  FOR INSERT WITH CHECK (studio_id IS NOT NULL AND is_studio_owner(studio_id));

CREATE POLICY service_categories_update ON service_categories
  FOR UPDATE USING (studio_id IS NOT NULL AND is_studio_owner(studio_id))
  WITH CHECK (studio_id IS NOT NULL AND is_studio_owner(studio_id));

CREATE POLICY service_categories_delete ON service_categories
  FOR DELETE USING (studio_id IS NOT NULL AND is_studio_owner(studio_id));

-- ============================================================================
-- services — SELECT public; mutations → owner
-- ============================================================================
DROP POLICY services_mutate ON services;

CREATE POLICY services_insert ON services
  FOR INSERT WITH CHECK (is_studio_owner(studio_id));

CREATE POLICY services_update ON services
  FOR UPDATE USING (is_studio_owner(studio_id))
  WITH CHECK (is_studio_owner(studio_id));

CREATE POLICY services_delete ON services
  FOR DELETE USING (is_studio_owner(studio_id));

-- ============================================================================
-- professional_services — SELECT public; mutations → owner
-- ============================================================================
DROP POLICY professional_services_mutate ON professional_services;

CREATE POLICY professional_services_insert ON professional_services
  FOR INSERT WITH CHECK (is_studio_owner(studio_id));

CREATE POLICY professional_services_update ON professional_services
  FOR UPDATE USING (is_studio_owner(studio_id))
  WITH CHECK (is_studio_owner(studio_id));

CREATE POLICY professional_services_delete ON professional_services
  FOR DELETE USING (is_studio_owner(studio_id));

-- ============================================================================
-- clients — SELECT member; mutations → owner
-- ============================================================================
DROP POLICY clients_policy ON clients;

CREATE POLICY clients_select ON clients
  FOR SELECT USING (is_studio_member(studio_id));

CREATE POLICY clients_insert ON clients
  FOR INSERT WITH CHECK (is_studio_owner(studio_id));

CREATE POLICY clients_update ON clients
  FOR UPDATE USING (is_studio_owner(studio_id))
  WITH CHECK (is_studio_owner(studio_id));

CREATE POLICY clients_delete ON clients
  FOR DELETE USING (is_studio_owner(studio_id));

-- ============================================================================
-- anamneses — SELECT member; mutations → owner
-- ============================================================================
DROP POLICY anamneses_policy ON anamneses;

CREATE POLICY anamneses_select ON anamneses
  FOR SELECT USING (is_studio_member(studio_id));

CREATE POLICY anamneses_insert ON anamneses
  FOR INSERT WITH CHECK (is_studio_owner(studio_id));

CREATE POLICY anamneses_update ON anamneses
  FOR UPDATE USING (is_studio_owner(studio_id))
  WITH CHECK (is_studio_owner(studio_id));

CREATE POLICY anamneses_delete ON anamneses
  FOR DELETE USING (is_studio_owner(studio_id));

-- ============================================================================
-- appointments — SELECT member; mutations → owner
-- ============================================================================
DROP POLICY appointments_policy ON appointments;

CREATE POLICY appointments_select ON appointments
  FOR SELECT USING (is_studio_member(studio_id));

CREATE POLICY appointments_insert ON appointments
  FOR INSERT WITH CHECK (is_studio_owner(studio_id));

CREATE POLICY appointments_update ON appointments
  FOR UPDATE USING (is_studio_owner(studio_id))
  WITH CHECK (is_studio_owner(studio_id));

CREATE POLICY appointments_delete ON appointments
  FOR DELETE USING (is_studio_owner(studio_id));

-- ============================================================================
-- blocked_slots — SELECT member; mutations → owner
-- ============================================================================
DROP POLICY blocked_slots_policy ON blocked_slots;

CREATE POLICY blocked_slots_select ON blocked_slots
  FOR SELECT USING (is_studio_member(studio_id));

CREATE POLICY blocked_slots_insert ON blocked_slots
  FOR INSERT WITH CHECK (is_studio_owner(studio_id));

CREATE POLICY blocked_slots_update ON blocked_slots
  FOR UPDATE USING (is_studio_owner(studio_id))
  WITH CHECK (is_studio_owner(studio_id));

CREATE POLICY blocked_slots_delete ON blocked_slots
  FOR DELETE USING (is_studio_owner(studio_id));

-- ============================================================================
-- conversations — SELECT member; mutations → owner
-- ============================================================================
DROP POLICY conversations_policy ON conversations;

CREATE POLICY conversations_select ON conversations
  FOR SELECT USING (is_studio_member(studio_id));

CREATE POLICY conversations_insert ON conversations
  FOR INSERT WITH CHECK (is_studio_owner(studio_id));

CREATE POLICY conversations_update ON conversations
  FOR UPDATE USING (is_studio_owner(studio_id))
  WITH CHECK (is_studio_owner(studio_id));

CREATE POLICY conversations_delete ON conversations
  FOR DELETE USING (is_studio_owner(studio_id));

-- ============================================================================
-- messages — SELECT member; mutations → owner
-- ============================================================================
DROP POLICY messages_policy ON messages;

CREATE POLICY messages_select ON messages
  FOR SELECT USING (is_studio_member(studio_id));

CREATE POLICY messages_insert ON messages
  FOR INSERT WITH CHECK (is_studio_owner(studio_id));

CREATE POLICY messages_update ON messages
  FOR UPDATE USING (is_studio_owner(studio_id))
  WITH CHECK (is_studio_owner(studio_id));

CREATE POLICY messages_delete ON messages
  FOR DELETE USING (is_studio_owner(studio_id));

-- ============================================================================
-- notification_logs — SELECT member; INSERT → owner (log table, no U/D)
-- ============================================================================
DROP POLICY notification_logs_policy ON notification_logs;

CREATE POLICY notification_logs_select ON notification_logs
  FOR SELECT USING (is_studio_member(studio_id));

CREATE POLICY notification_logs_insert ON notification_logs
  FOR INSERT WITH CHECK (is_studio_owner(studio_id));

-- ============================================================================
-- packages — owner only
-- ============================================================================
DROP POLICY packages_policy ON packages;

CREATE POLICY packages_select ON packages
  FOR SELECT USING (is_studio_owner(studio_id));

CREATE POLICY packages_insert ON packages
  FOR INSERT WITH CHECK (is_studio_owner(studio_id));

CREATE POLICY packages_update ON packages
  FOR UPDATE USING (is_studio_owner(studio_id))
  WITH CHECK (is_studio_owner(studio_id));

CREATE POLICY packages_delete ON packages
  FOR DELETE USING (is_studio_owner(studio_id));

-- ============================================================================
-- package_subscriptions — owner only
-- ============================================================================
DROP POLICY package_subscriptions_policy ON package_subscriptions;

CREATE POLICY package_subscriptions_select ON package_subscriptions
  FOR SELECT USING (is_studio_owner(studio_id));

CREATE POLICY package_subscriptions_insert ON package_subscriptions
  FOR INSERT WITH CHECK (is_studio_owner(studio_id));

CREATE POLICY package_subscriptions_update ON package_subscriptions
  FOR UPDATE USING (is_studio_owner(studio_id))
  WITH CHECK (is_studio_owner(studio_id));

CREATE POLICY package_subscriptions_delete ON package_subscriptions
  FOR DELETE USING (is_studio_owner(studio_id));

-- ============================================================================
-- commissions — owner only
-- ============================================================================
DROP POLICY commissions_policy ON commissions;

CREATE POLICY commissions_select ON commissions
  FOR SELECT USING (is_studio_owner(studio_id));

CREATE POLICY commissions_insert ON commissions
  FOR INSERT WITH CHECK (is_studio_owner(studio_id));

CREATE POLICY commissions_update ON commissions
  FOR UPDATE USING (is_studio_owner(studio_id))
  WITH CHECK (is_studio_owner(studio_id));

CREATE POLICY commissions_delete ON commissions
  FOR DELETE USING (is_studio_owner(studio_id));

-- ============================================================================
-- payments — owner only (no DELETE — financial record)
-- ============================================================================
DROP POLICY payments_policy ON payments;

CREATE POLICY payments_select ON payments
  FOR SELECT USING (is_studio_owner(studio_id));

CREATE POLICY payments_insert ON payments
  FOR INSERT WITH CHECK (is_studio_owner(studio_id));

CREATE POLICY payments_update ON payments
  FOR UPDATE USING (is_studio_owner(studio_id))
  WITH CHECK (is_studio_owner(studio_id));

-- ============================================================================
-- ai_configs — owner only
-- ============================================================================
DROP POLICY ai_configs_policy ON ai_configs;

CREATE POLICY ai_configs_select ON ai_configs
  FOR SELECT USING (is_studio_owner(studio_id));

CREATE POLICY ai_configs_insert ON ai_configs
  FOR INSERT WITH CHECK (is_studio_owner(studio_id));

CREATE POLICY ai_configs_update ON ai_configs
  FOR UPDATE USING (is_studio_owner(studio_id))
  WITH CHECK (is_studio_owner(studio_id));

CREATE POLICY ai_configs_delete ON ai_configs
  FOR DELETE USING (is_studio_owner(studio_id));

-- ============================================================================
-- onboarding_states — owner only
-- ============================================================================
DROP POLICY onboarding_states_policy ON onboarding_states;

CREATE POLICY onboarding_states_select ON onboarding_states
  FOR SELECT USING (is_studio_owner(studio_id));

CREATE POLICY onboarding_states_insert ON onboarding_states
  FOR INSERT WITH CHECK (is_studio_owner(studio_id));

CREATE POLICY onboarding_states_update ON onboarding_states
  FOR UPDATE USING (is_studio_owner(studio_id))
  WITH CHECK (is_studio_owner(studio_id));

CREATE POLICY onboarding_states_delete ON onboarding_states
  FOR DELETE USING (is_studio_owner(studio_id));

-- ============================================================================
-- campaigns — owner only
-- ============================================================================
DROP POLICY campaigns_policy ON campaigns;

CREATE POLICY campaigns_select ON campaigns
  FOR SELECT USING (is_studio_owner(studio_id));

CREATE POLICY campaigns_insert ON campaigns
  FOR INSERT WITH CHECK (is_studio_owner(studio_id));

CREATE POLICY campaigns_update ON campaigns
  FOR UPDATE USING (is_studio_owner(studio_id))
  WITH CHECK (is_studio_owner(studio_id));

CREATE POLICY campaigns_delete ON campaigns
  FOR DELETE USING (is_studio_owner(studio_id));

-- ============================================================================
-- campaign_logs — owner only (log table, no UPDATE/DELETE)
-- ============================================================================
DROP POLICY campaign_logs_policy ON campaign_logs;

CREATE POLICY campaign_logs_select ON campaign_logs
  FOR SELECT USING (is_studio_owner(studio_id));

CREATE POLICY campaign_logs_insert ON campaign_logs
  FOR INSERT WITH CHECK (is_studio_owner(studio_id));

-- ============================================================================
-- consent_records — SELECT + INSERT owner only (append-only, LGPD)
-- ============================================================================
DROP POLICY consent_records_select ON consent_records;
DROP POLICY consent_records_insert ON consent_records;

CREATE POLICY consent_records_select ON consent_records
  FOR SELECT USING (is_studio_owner(studio_id));

CREATE POLICY consent_records_insert ON consent_records
  FOR INSERT WITH CHECK (is_studio_owner(studio_id));
