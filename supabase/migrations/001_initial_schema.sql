-- ============================================================================
-- Oriz — Initial Schema
-- Source of truth: docs/DOMAIN_MODEL.md
-- ============================================================================

-- Extensions
CREATE EXTENSION IF NOT EXISTS btree_gist;

-- ============================================================================
-- Helper: updated_at trigger function
-- ============================================================================
CREATE OR REPLACE FUNCTION updated_at_trigger()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- profiles
-- ============================================================================
CREATE TABLE profiles (
  id         UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name  TEXT NOT NULL,
  phone      TEXT,
  avatar_url TEXT,
  role       TEXT NOT NULL CHECK (role IN ('owner', 'professional', 'client')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TRIGGER profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION updated_at_trigger();

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY profiles_own ON profiles
  FOR ALL USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

-- ============================================================================
-- studios
-- ============================================================================
CREATE TABLE studios (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id    UUID NOT NULL REFERENCES auth.users(id),
  name        TEXT NOT NULL,
  slug        TEXT NOT NULL,
  phone       TEXT,
  address     TEXT,
  logo_url    TEXT,
  description TEXT,
  timezone    TEXT NOT NULL DEFAULT 'America/Sao_Paulo',
  settings    JSONB NOT NULL DEFAULT '{}',
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX studios_slug_key ON studios (slug);

CREATE TRIGGER studios_updated_at
  BEFORE UPDATE ON studios
  FOR EACH ROW EXECUTE FUNCTION updated_at_trigger();

ALTER TABLE studios ENABLE ROW LEVEL SECURITY;

-- Public: anyone can view studios (public booking page via slug lookup)
CREATE POLICY studios_select ON studios
  FOR SELECT USING (true);

CREATE POLICY studios_insert ON studios
  FOR INSERT WITH CHECK (owner_id = auth.uid());

CREATE POLICY studios_update ON studios
  FOR UPDATE USING (owner_id = auth.uid())
  WITH CHECK (owner_id = auth.uid());

CREATE POLICY studios_delete ON studios
  FOR DELETE USING (owner_id = auth.uid());

-- ============================================================================
-- studio_photos
-- ============================================================================
CREATE TABLE studio_photos (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  studio_id  UUID NOT NULL REFERENCES studios(id) ON DELETE CASCADE,
  url        TEXT NOT NULL,
  position   INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE studio_photos ENABLE ROW LEVEL SECURITY;

-- Public: anyone can view studio photos (public booking page)
CREATE POLICY studio_photos_select ON studio_photos
  FOR SELECT USING (true);

CREATE POLICY studio_photos_insert ON studio_photos
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM studios s WHERE s.id = studio_photos.studio_id AND s.owner_id = auth.uid())
  );

CREATE POLICY studio_photos_update ON studio_photos
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM studios s WHERE s.id = studio_photos.studio_id AND s.owner_id = auth.uid())
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM studios s WHERE s.id = studio_photos.studio_id AND s.owner_id = auth.uid())
  );

CREATE POLICY studio_photos_delete ON studio_photos
  FOR DELETE USING (
    EXISTS (SELECT 1 FROM studios s WHERE s.id = studio_photos.studio_id AND s.owner_id = auth.uid())
  );

-- ============================================================================
-- professionals
-- ============================================================================
CREATE TABLE professionals (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  studio_id        UUID NOT NULL REFERENCES studios(id) ON DELETE CASCADE,
  user_id          UUID NOT NULL REFERENCES auth.users(id),
  name             TEXT NOT NULL,
  avatar_url       TEXT,
  specialties      TEXT[] NOT NULL DEFAULT '{}',
  working_hours    JSONB NOT NULL DEFAULT '{}',
  commission_type  TEXT NOT NULL CHECK (commission_type IN ('percentage', 'fixed')),
  -- Dual-purpose: percentage (e.g. 40.00) when commission_type='percentage',
  -- amount in centavos when commission_type='fixed'
  commission_value NUMERIC(10,2) NOT NULL DEFAULT 0,
  card_fee_policy  TEXT NOT NULL CHECK (card_fee_policy IN ('studio', 'professional', 'split')) DEFAULT 'studio',
  is_active        BOOLEAN NOT NULL DEFAULT true,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX professionals_studio_user_key ON professionals (studio_id, user_id);

CREATE TRIGGER professionals_updated_at
  BEFORE UPDATE ON professionals
  FOR EACH ROW EXECUTE FUNCTION updated_at_trigger();

ALTER TABLE professionals ENABLE ROW LEVEL SECURITY;

-- Public: anyone can view professionals (public booking page)
CREATE POLICY professionals_select ON professionals
  FOR SELECT USING (true);

CREATE POLICY professionals_mutate ON professionals
  FOR ALL USING (studio_id IN (SELECT id FROM studios))
  WITH CHECK (studio_id IN (SELECT id FROM studios));

-- ============================================================================
-- service_categories
-- ============================================================================
CREATE TABLE service_categories (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  studio_id  UUID REFERENCES studios(id) ON DELETE CASCADE,
  name       TEXT NOT NULL,
  icon       TEXT,
  position   INTEGER NOT NULL DEFAULT 0,
  is_active  BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE service_categories ENABLE ROW LEVEL SECURITY;

-- Public: anyone can view categories (public booking page + global seeds)
CREATE POLICY service_categories_select ON service_categories
  FOR SELECT USING (true);

-- Mutations: only own studio categories (never global seeds)
CREATE POLICY service_categories_insert ON service_categories
  FOR INSERT WITH CHECK (
    studio_id IS NOT NULL
    AND studio_id IN (SELECT id FROM studios)
  );

CREATE POLICY service_categories_update ON service_categories
  FOR UPDATE USING (
    studio_id IS NOT NULL
    AND studio_id IN (SELECT id FROM studios)
  )
  WITH CHECK (
    studio_id IS NOT NULL
    AND studio_id IN (SELECT id FROM studios)
  );

CREATE POLICY service_categories_delete ON service_categories
  FOR DELETE USING (
    studio_id IS NOT NULL
    AND studio_id IN (SELECT id FROM studios)
  );

-- ============================================================================
-- services
-- ============================================================================
CREATE TABLE services (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  studio_id        UUID NOT NULL REFERENCES studios(id) ON DELETE CASCADE,
  category_id      UUID NOT NULL REFERENCES service_categories(id),
  name             TEXT NOT NULL,
  duration_minutes INTEGER NOT NULL,
  price            INTEGER NOT NULL,
  buffer_minutes   INTEGER NOT NULL DEFAULT 0,
  is_active        BOOLEAN NOT NULL DEFAULT true,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TRIGGER services_updated_at
  BEFORE UPDATE ON services
  FOR EACH ROW EXECUTE FUNCTION updated_at_trigger();

ALTER TABLE services ENABLE ROW LEVEL SECURITY;

-- Public: anyone can view services (public booking page)
CREATE POLICY services_select ON services
  FOR SELECT USING (true);

CREATE POLICY services_mutate ON services
  FOR ALL USING (studio_id IN (SELECT id FROM studios))
  WITH CHECK (studio_id IN (SELECT id FROM studios));

-- ============================================================================
-- professional_services
-- ============================================================================
CREATE TABLE professional_services (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  studio_id       UUID NOT NULL REFERENCES studios(id) ON DELETE CASCADE,
  professional_id UUID NOT NULL REFERENCES professionals(id) ON DELETE CASCADE,
  service_id      UUID NOT NULL REFERENCES services(id) ON DELETE CASCADE
);

CREATE UNIQUE INDEX professional_services_key ON professional_services (professional_id, service_id);

ALTER TABLE professional_services ENABLE ROW LEVEL SECURITY;

-- Public: anyone can view (public booking page)
CREATE POLICY professional_services_select ON professional_services
  FOR SELECT USING (true);

CREATE POLICY professional_services_mutate ON professional_services
  FOR ALL USING (studio_id IN (SELECT id FROM studios))
  WITH CHECK (studio_id IN (SELECT id FROM studios));

-- ============================================================================
-- clients
-- ============================================================================
CREATE TABLE clients (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  studio_id           UUID NOT NULL REFERENCES studios(id) ON DELETE CASCADE,
  name                TEXT NOT NULL,
  phone               TEXT,
  email               TEXT,
  birth_date          DATE,
  tags                JSONB NOT NULL DEFAULT '[]',
  notes               TEXT,
  last_appointment_at TIMESTAMPTZ,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX clients_studio_phone_key ON clients (studio_id, phone)
  WHERE phone IS NOT NULL;

-- Reactivation campaigns: find inactive clients by studio
CREATE INDEX clients_reactivation_idx ON clients (studio_id, last_appointment_at)
  WHERE last_appointment_at IS NOT NULL;

CREATE TRIGGER clients_updated_at
  BEFORE UPDATE ON clients
  FOR EACH ROW EXECUTE FUNCTION updated_at_trigger();

ALTER TABLE clients ENABLE ROW LEVEL SECURITY;

CREATE POLICY clients_policy ON clients
  FOR ALL USING (studio_id IN (SELECT id FROM studios))
  WITH CHECK (studio_id IN (SELECT id FROM studios));

-- ============================================================================
-- anamneses
-- ============================================================================
CREATE TABLE anamneses (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  studio_id           UUID NOT NULL REFERENCES studios(id) ON DELETE CASCADE,
  client_id           UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
  service_category_id UUID NOT NULL REFERENCES service_categories(id),
  fields              JSONB NOT NULL DEFAULT '{}',
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX anamneses_key ON anamneses (studio_id, client_id, service_category_id);

CREATE TRIGGER anamneses_updated_at
  BEFORE UPDATE ON anamneses
  FOR EACH ROW EXECUTE FUNCTION updated_at_trigger();

ALTER TABLE anamneses ENABLE ROW LEVEL SECURITY;

CREATE POLICY anamneses_policy ON anamneses
  FOR ALL USING (studio_id IN (SELECT id FROM studios))
  WITH CHECK (studio_id IN (SELECT id FROM studios));

-- ============================================================================
-- appointments
-- ============================================================================
CREATE TABLE appointments (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  studio_id           UUID NOT NULL REFERENCES studios(id) ON DELETE CASCADE,
  client_id           UUID NOT NULL REFERENCES clients(id),
  professional_id     UUID NOT NULL REFERENCES professionals(id),
  service_id          UUID NOT NULL REFERENCES services(id),
  date                DATE NOT NULL,
  start_time          TIMESTAMPTZ NOT NULL,
  end_time            TIMESTAMPTZ NOT NULL,
  status              TEXT NOT NULL CHECK (status IN ('confirmed', 'completed', 'cancelled', 'no_show')) DEFAULT 'confirmed',
  source              TEXT NOT NULL CHECK (source IN ('app', 'whatsapp_ai', 'web_page', 'manual')) DEFAULT 'manual',
  notes               TEXT,
  cancellation_reason TEXT,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Exclusion constraint: prevent overlapping appointments for same professional
ALTER TABLE appointments
  ADD CONSTRAINT appointments_no_overlap
  EXCLUDE USING gist (
    professional_id WITH =,
    tsrange(start_time, end_time) WITH &&
  ) WHERE (status != 'cancelled');

-- Lookup: professional schedule for a given day
CREATE INDEX appointments_prof_date_idx ON appointments (professional_id, date, start_time);

-- Lookup: studio daily agenda
CREATE INDEX appointments_studio_date_idx ON appointments (studio_id, date);

CREATE TRIGGER appointments_updated_at
  BEFORE UPDATE ON appointments
  FOR EACH ROW EXECUTE FUNCTION updated_at_trigger();

ALTER TABLE appointments ENABLE ROW LEVEL SECURITY;

CREATE POLICY appointments_policy ON appointments
  FOR ALL USING (studio_id IN (SELECT id FROM studios))
  WITH CHECK (studio_id IN (SELECT id FROM studios));

-- ============================================================================
-- blocked_slots
-- ============================================================================
CREATE TABLE blocked_slots (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  studio_id       UUID NOT NULL REFERENCES studios(id) ON DELETE CASCADE,
  professional_id UUID NOT NULL REFERENCES professionals(id) ON DELETE CASCADE,
  date            DATE NOT NULL,
  start_time      TIMESTAMPTZ NOT NULL,
  end_time        TIMESTAMPTZ NOT NULL,
  reason          TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX blocked_slots_prof_date_idx ON blocked_slots (professional_id, date);

ALTER TABLE blocked_slots ENABLE ROW LEVEL SECURITY;

CREATE POLICY blocked_slots_policy ON blocked_slots
  FOR ALL USING (studio_id IN (SELECT id FROM studios))
  WITH CHECK (studio_id IN (SELECT id FROM studios));

-- ============================================================================
-- packages
-- ============================================================================
CREATE TABLE packages (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  studio_id      UUID NOT NULL REFERENCES studios(id) ON DELETE CASCADE,
  service_id     UUID NOT NULL REFERENCES services(id),
  name           TEXT NOT NULL,
  total_sessions INTEGER NOT NULL,
  price          INTEGER NOT NULL,
  validity_days  INTEGER NOT NULL,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TRIGGER packages_updated_at
  BEFORE UPDATE ON packages
  FOR EACH ROW EXECUTE FUNCTION updated_at_trigger();

ALTER TABLE packages ENABLE ROW LEVEL SECURITY;

CREATE POLICY packages_policy ON packages
  FOR ALL USING (studio_id IN (SELECT id FROM studios))
  WITH CHECK (studio_id IN (SELECT id FROM studios));

-- ============================================================================
-- package_subscriptions
-- ============================================================================
CREATE TABLE package_subscriptions (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  studio_id      UUID NOT NULL REFERENCES studios(id) ON DELETE CASCADE,
  package_id     UUID NOT NULL REFERENCES packages(id),
  client_id      UUID NOT NULL REFERENCES clients(id),
  sessions_used  INTEGER NOT NULL DEFAULT 0,
  sessions_total INTEGER NOT NULL,
  expires_at     TIMESTAMPTZ NOT NULL,
  status         TEXT NOT NULL CHECK (status IN ('active', 'completed', 'expired')) DEFAULT 'active',
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TRIGGER package_subscriptions_updated_at
  BEFORE UPDATE ON package_subscriptions
  FOR EACH ROW EXECUTE FUNCTION updated_at_trigger();

ALTER TABLE package_subscriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY package_subscriptions_policy ON package_subscriptions
  FOR ALL USING (studio_id IN (SELECT id FROM studios))
  WITH CHECK (studio_id IN (SELECT id FROM studios));

-- ============================================================================
-- commissions
-- ============================================================================
CREATE TABLE commissions (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  studio_id           UUID NOT NULL REFERENCES studios(id) ON DELETE CASCADE,
  professional_id     UUID NOT NULL REFERENCES professionals(id),
  appointment_id      UUID NOT NULL REFERENCES appointments(id),
  amount              INTEGER NOT NULL,
  studio_amount       INTEGER NOT NULL,
  professional_amount INTEGER NOT NULL,
  card_fee_amount     INTEGER NOT NULL DEFAULT 0,
  who_paid_fee        TEXT CHECK (who_paid_fee IN ('studio', 'professional', 'split')),
  period_start        DATE NOT NULL,
  period_end          DATE NOT NULL,
  status              TEXT NOT NULL CHECK (status IN ('pending', 'paid')) DEFAULT 'pending',
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE commissions ENABLE ROW LEVEL SECURITY;

CREATE POLICY commissions_policy ON commissions
  FOR ALL USING (studio_id IN (SELECT id FROM studios))
  WITH CHECK (studio_id IN (SELECT id FROM studios));

-- ============================================================================
-- payments
-- ============================================================================
CREATE TABLE payments (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  studio_id           UUID NOT NULL REFERENCES studios(id) ON DELETE CASCADE,
  appointment_id      UUID NOT NULL REFERENCES appointments(id),
  client_id           UUID NOT NULL REFERENCES clients(id),
  amount              INTEGER NOT NULL,
  method              TEXT NOT NULL CHECK (method IN ('cash', 'pix', 'debit', 'credit')),
  card_fee_percentage NUMERIC(5,2),
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

CREATE POLICY payments_policy ON payments
  FOR ALL USING (studio_id IN (SELECT id FROM studios))
  WITH CHECK (studio_id IN (SELECT id FROM studios));

-- ============================================================================
-- conversations
-- ============================================================================
CREATE TABLE conversations (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  studio_id       UUID NOT NULL REFERENCES studios(id) ON DELETE CASCADE,
  client_id       UUID REFERENCES clients(id),
  whatsapp_number TEXT NOT NULL,
  status          TEXT NOT NULL CHECK (status IN ('active', 'closed', 'escalated')) DEFAULT 'active',
  started_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  last_message_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Dashboard: list active conversations by studio
CREATE INDEX conversations_studio_status_idx ON conversations (studio_id, status);

ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;

CREATE POLICY conversations_policy ON conversations
  FOR ALL USING (studio_id IN (SELECT id FROM studios))
  WITH CHECK (studio_id IN (SELECT id FROM studios));

-- ============================================================================
-- messages
-- ============================================================================
CREATE TABLE messages (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  studio_id       UUID NOT NULL REFERENCES studios(id) ON DELETE CASCADE,
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  role            TEXT NOT NULL CHECK (role IN ('client', 'assistant', 'system')),
  content         TEXT NOT NULL,
  metadata        JSONB NOT NULL DEFAULT '{}',
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Conversation thread: load messages by conversation ordered by time
CREATE INDEX messages_conversation_idx ON messages (conversation_id, created_at);

ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY messages_policy ON messages
  FOR ALL USING (studio_id IN (SELECT id FROM studios))
  WITH CHECK (studio_id IN (SELECT id FROM studios));

-- ============================================================================
-- ai_configs
-- ============================================================================
CREATE TABLE ai_configs (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  studio_id        UUID NOT NULL UNIQUE REFERENCES studios(id) ON DELETE CASCADE,
  tone_of_voice    TEXT,
  greeting_message TEXT,
  scheduling_rules JSONB NOT NULL DEFAULT '{}',
  fallback_message TEXT,
  enabled          BOOLEAN NOT NULL DEFAULT false,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TRIGGER ai_configs_updated_at
  BEFORE UPDATE ON ai_configs
  FOR EACH ROW EXECUTE FUNCTION updated_at_trigger();

ALTER TABLE ai_configs ENABLE ROW LEVEL SECURITY;

CREATE POLICY ai_configs_policy ON ai_configs
  FOR ALL USING (studio_id IN (SELECT id FROM studios))
  WITH CHECK (studio_id IN (SELECT id FROM studios));

-- ============================================================================
-- device_tokens (RLS by user_id, not studio_id)
-- ============================================================================
CREATE TABLE device_tokens (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  token      TEXT NOT NULL,
  platform   TEXT NOT NULL CHECK (platform IN ('android', 'ios')),
  is_active  BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX device_tokens_user_token_key ON device_tokens (user_id, token);

CREATE TRIGGER device_tokens_updated_at
  BEFORE UPDATE ON device_tokens
  FOR EACH ROW EXECUTE FUNCTION updated_at_trigger();

ALTER TABLE device_tokens ENABLE ROW LEVEL SECURITY;

CREATE POLICY device_tokens_policy ON device_tokens
  FOR ALL USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- ============================================================================
-- notification_logs (partitioned by month, TTL 90 days)
-- ============================================================================
CREATE TABLE notification_logs (
  id             UUID NOT NULL DEFAULT gen_random_uuid(),
  studio_id      UUID NOT NULL,
  user_id        UUID NOT NULL,
  appointment_id UUID,
  type           TEXT NOT NULL CHECK (type IN ('new_booking', 'reminder', 'cancellation')),
  status         TEXT NOT NULL CHECK (status IN ('sent', 'delivered', 'failed')),
  sent_at        TIMESTAMPTZ NOT NULL DEFAULT now()
) PARTITION BY RANGE (sent_at);

-- Initial partitions (extend as needed via pg_cron or migration)
CREATE TABLE notification_logs_2026_03 PARTITION OF notification_logs
  FOR VALUES FROM ('2026-03-01') TO ('2026-04-01');
CREATE TABLE notification_logs_2026_04 PARTITION OF notification_logs
  FOR VALUES FROM ('2026-04-01') TO ('2026-05-01');
CREATE TABLE notification_logs_2026_05 PARTITION OF notification_logs
  FOR VALUES FROM ('2026-05-01') TO ('2026-06-01');

ALTER TABLE notification_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY notification_logs_policy ON notification_logs
  FOR ALL USING (
    studio_id IN (SELECT id FROM studios)
  )
  WITH CHECK (
    studio_id IN (SELECT id FROM studios)
  );

-- ============================================================================
-- subscriptions
-- ============================================================================
CREATE TABLE subscriptions (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  studio_id               UUID NOT NULL UNIQUE REFERENCES studios(id) ON DELETE CASCADE,
  plan                    TEXT NOT NULL CHECK (plan IN ('basic', 'pro', 'premium')),
  price_cents             INTEGER NOT NULL,
  billing_cycle           TEXT NOT NULL DEFAULT 'monthly',
  status                  TEXT NOT NULL CHECK (status IN ('active', 'past_due', 'cancelled')) DEFAULT 'active',
  current_period_start    TIMESTAMPTZ NOT NULL,
  current_period_end      TIMESTAMPTZ NOT NULL,
  gateway_subscription_id TEXT,
  created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at              TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TRIGGER subscriptions_updated_at
  BEFORE UPDATE ON subscriptions
  FOR EACH ROW EXECUTE FUNCTION updated_at_trigger();

ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY subscriptions_policy ON subscriptions
  FOR ALL USING (
    EXISTS (SELECT 1 FROM studios s WHERE s.id = subscriptions.studio_id AND s.owner_id = auth.uid())
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM studios s WHERE s.id = subscriptions.studio_id AND s.owner_id = auth.uid())
  );

-- ============================================================================
-- invoices
-- ============================================================================
CREATE TABLE invoices (
  id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  studio_id          UUID NOT NULL REFERENCES studios(id) ON DELETE CASCADE,
  subscription_id    UUID NOT NULL REFERENCES subscriptions(id),
  amount_cents       INTEGER NOT NULL,
  status             TEXT NOT NULL CHECK (status IN ('pending', 'paid', 'failed')) DEFAULT 'pending',
  gateway_invoice_id TEXT,
  due_at             TIMESTAMPTZ NOT NULL,
  paid_at            TIMESTAMPTZ,
  created_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX invoices_studio_due_idx ON invoices (studio_id, due_at);

ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;

CREATE POLICY invoices_policy ON invoices
  FOR ALL USING (
    EXISTS (SELECT 1 FROM studios s WHERE s.id = invoices.studio_id AND s.owner_id = auth.uid())
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM studios s WHERE s.id = invoices.studio_id AND s.owner_id = auth.uid())
  );

-- ============================================================================
-- consent_records (append-only — never UPDATE)
-- ============================================================================
CREATE TABLE consent_records (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id  UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
  studio_id  UUID NOT NULL REFERENCES studios(id) ON DELETE CASCADE,
  type       TEXT NOT NULL CHECK (type IN ('marketing_whatsapp', 'marketing_push')),
  action     TEXT NOT NULL CHECK (action IN ('granted', 'revoked')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX consent_records_lookup_idx ON consent_records (client_id, studio_id, type, created_at DESC);

ALTER TABLE consent_records ENABLE ROW LEVEL SECURITY;

-- Append-only: only SELECT and INSERT allowed (LGPD traceability)
CREATE POLICY consent_records_select ON consent_records
  FOR SELECT USING (studio_id IN (SELECT id FROM studios));

CREATE POLICY consent_records_insert ON consent_records
  FOR INSERT WITH CHECK (studio_id IN (SELECT id FROM studios));

-- ============================================================================
-- audit_logs (partitioned by month, TTL 365 days)
-- ============================================================================
CREATE TABLE audit_logs (
  id          UUID NOT NULL DEFAULT gen_random_uuid(),
  studio_id   UUID NOT NULL,
  user_id     UUID NOT NULL,
  action      TEXT NOT NULL CHECK (action IN ('view', 'export', 'delete')),
  entity_type TEXT NOT NULL,
  entity_id   UUID NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
) PARTITION BY RANGE (created_at);

-- Initial partitions
CREATE TABLE audit_logs_2026_03 PARTITION OF audit_logs
  FOR VALUES FROM ('2026-03-01') TO ('2026-04-01');
CREATE TABLE audit_logs_2026_04 PARTITION OF audit_logs
  FOR VALUES FROM ('2026-04-01') TO ('2026-05-01');
CREATE TABLE audit_logs_2026_05 PARTITION OF audit_logs
  FOR VALUES FROM ('2026-05-01') TO ('2026-06-01');

CREATE INDEX audit_logs_studio_created_idx ON audit_logs (studio_id, created_at);

ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- INSERT: handled by service_role key in backend (no RLS restriction needed for insert)
-- SELECT: only studio owner
CREATE POLICY audit_logs_select ON audit_logs
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM studios s WHERE s.id = audit_logs.studio_id AND s.owner_id = auth.uid())
  );

-- ============================================================================
-- onboarding_states
-- ============================================================================
CREATE TABLE onboarding_states (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  studio_id    UUID NOT NULL UNIQUE REFERENCES studios(id) ON DELETE CASCADE,
  current_step TEXT NOT NULL CHECK (current_step IN ('studio_data', 'services', 'business_hours', 'complete')) DEFAULT 'studio_data',
  completed_at TIMESTAMPTZ,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TRIGGER onboarding_states_updated_at
  BEFORE UPDATE ON onboarding_states
  FOR EACH ROW EXECUTE FUNCTION updated_at_trigger();

ALTER TABLE onboarding_states ENABLE ROW LEVEL SECURITY;

CREATE POLICY onboarding_states_policy ON onboarding_states
  FOR ALL USING (studio_id IN (SELECT id FROM studios))
  WITH CHECK (studio_id IN (SELECT id FROM studios));

-- ============================================================================
-- campaigns
-- ============================================================================
CREATE TABLE campaigns (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  studio_id           UUID NOT NULL REFERENCES studios(id) ON DELETE CASCADE,
  type                TEXT NOT NULL CHECK (type IN ('birthday', 'reactivation', 'custom')),
  message_template    TEXT NOT NULL,
  discount_percentage INTEGER,
  inactivity_days     INTEGER DEFAULT 60,
  channel             TEXT NOT NULL CHECK (channel IN ('whatsapp', 'push', 'both')),
  is_active           BOOLEAN NOT NULL DEFAULT true,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TRIGGER campaigns_updated_at
  BEFORE UPDATE ON campaigns
  FOR EACH ROW EXECUTE FUNCTION updated_at_trigger();

ALTER TABLE campaigns ENABLE ROW LEVEL SECURITY;

CREATE POLICY campaigns_policy ON campaigns
  FOR ALL USING (studio_id IN (SELECT id FROM studios))
  WITH CHECK (studio_id IN (SELECT id FROM studios));

-- ============================================================================
-- campaign_logs
-- ============================================================================
CREATE TABLE campaign_logs (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  studio_id   UUID NOT NULL REFERENCES studios(id) ON DELETE CASCADE,
  campaign_id UUID NOT NULL REFERENCES campaigns(id) ON DELETE CASCADE,
  client_id   UUID NOT NULL REFERENCES clients(id),
  sent_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  status      TEXT NOT NULL CHECK (status IN ('sent', 'delivered', 'failed')),
  result      TEXT CHECK (result IN ('returned', 'no_response'))
);

CREATE UNIQUE INDEX campaign_logs_dedup_key ON campaign_logs (campaign_id, client_id, sent_at);

ALTER TABLE campaign_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY campaign_logs_policy ON campaign_logs
  FOR ALL USING (studio_id IN (SELECT id FROM studios))
  WITH CHECK (studio_id IN (SELECT id FROM studios));

-- ============================================================================
-- financial_summaries (materialized view)
-- ============================================================================
CREATE MATERIALIZED VIEW financial_summaries AS
SELECT
  p.studio_id,
  EXTRACT(YEAR FROM p.created_at)::INTEGER  AS period_year,
  EXTRACT(MONTH FROM p.created_at)::INTEGER AS period_month,
  SUM(p.amount)                              AS total_revenue,
  COALESCE(SUM(comm.total_professional), 0)  AS total_commissions,
  CASE WHEN COUNT(p.id) > 0
    THEN SUM(p.amount) / COUNT(p.id)
    ELSE 0
  END                                        AS avg_ticket
FROM payments p
LEFT JOIN LATERAL (
  SELECT SUM(c.professional_amount) AS total_professional
  FROM commissions c
  WHERE c.appointment_id = p.appointment_id
) comm ON true
GROUP BY p.studio_id, period_year, period_month;

-- Required for REFRESH MATERIALIZED VIEW CONCURRENTLY
CREATE UNIQUE INDEX financial_summaries_key
  ON financial_summaries (studio_id, period_year, period_month);

-- ============================================================================
-- Seed: global service categories
-- ============================================================================
INSERT INTO service_categories (id, studio_id, name, icon, position) VALUES
  (gen_random_uuid(), NULL, 'Unhas',        'nail',      1),
  (gen_random_uuid(), NULL, 'Cílios',       'eyelash',   2),
  (gen_random_uuid(), NULL, 'Sobrancelha',  'eyebrow',   3),
  (gen_random_uuid(), NULL, 'Cabelo',       'hair',      4),
  (gen_random_uuid(), NULL, 'Maquiagem',    'makeup',    5),
  (gen_random_uuid(), NULL, 'Depilação',    'wax',       6),
  (gen_random_uuid(), NULL, 'Estética',     'skincare',  7),
  (gen_random_uuid(), NULL, 'Massagem',     'massage',   8),
  (gen_random_uuid(), NULL, 'Barbearia',    'barber',    9),
  (gen_random_uuid(), NULL, 'Outro',        'other',    10);
