-- ============================================================================
-- Oriz — Financial Schema Updates (Phase 4)
-- Adds: discount fields + type to payments; package_subscription_id to
--       appointments; fixes financial_summaries view for split payments.
-- ============================================================================

-- ── 1. payments: add created_at (if not present), discount columns, type ──────
-- created_at already exists in initial schema, but we add the new columns:

ALTER TABLE payments
  ADD COLUMN IF NOT EXISTS discount_amount  INTEGER      NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS discount_reason  TEXT,
  ADD COLUMN IF NOT EXISTS type             TEXT         NOT NULL DEFAULT 'avulso'
    CHECK (type IN ('avulso', 'pacote'));

-- Allow appointment_id to be nullable (package sales have no appointment)
ALTER TABLE payments
  ALTER COLUMN appointment_id DROP NOT NULL;

-- ── 2. appointments: add package_subscription_id FK ──────────────────────────

ALTER TABLE appointments
  ADD COLUMN IF NOT EXISTS package_subscription_id UUID
    REFERENCES package_subscriptions(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS appointments_package_subscription_idx
  ON appointments (package_subscription_id)
  WHERE package_subscription_id IS NOT NULL;

-- ── 3. financial_summaries: drop and recreate with correct aggregation ────────
--
-- Old view summed amount per payment row → split payments (multiple rows per
-- appointment) would double-count revenue.  The fix: GROUP BY appointment_id
-- first (per-appointment net), then aggregate per studio/period.
-- Package sales (appointment_id IS NULL) are counted as standalone rows.
-- Net amount: amount - discount_amount.

DROP MATERIALIZED VIEW IF EXISTS financial_summaries;

CREATE MATERIALIZED VIEW financial_summaries AS
WITH per_appointment AS (
  -- For payments linked to an appointment: one revenue row per appointment
  -- using the FIRST payment's period (edge case: split across calendar months
  -- is intentionally ignored — simpler and correct for 99% of cases)
  SELECT
    studio_id,
    appointment_id,
    MIN(created_at)                          AS period_at,
    SUM(amount - discount_amount)            AS net_amount
  FROM payments
  WHERE appointment_id IS NOT NULL
  GROUP BY studio_id, appointment_id

  UNION ALL

  -- Package sales (no appointment): each payment row is independent revenue
  SELECT
    studio_id,
    NULL::UUID                               AS appointment_id,
    created_at                               AS period_at,
    (amount - discount_amount)               AS net_amount
  FROM payments
  WHERE appointment_id IS NULL
)
SELECT
  pa.studio_id,
  EXTRACT(YEAR  FROM pa.period_at)::INTEGER AS period_year,
  EXTRACT(MONTH FROM pa.period_at)::INTEGER AS period_month,
  SUM(pa.net_amount)                         AS total_revenue,
  COALESCE(SUM(comm.total_professional), 0)  AS total_commissions,
  CASE WHEN COUNT(pa.appointment_id) > 0
    THEN SUM(pa.net_amount) / COUNT(pa.appointment_id)
    ELSE 0
  END                                        AS avg_ticket
FROM per_appointment pa
LEFT JOIN LATERAL (
  SELECT SUM(c.professional_amount) AS total_professional
  FROM commissions c
  WHERE c.appointment_id = pa.appointment_id
) comm ON true
GROUP BY pa.studio_id, period_year, period_month;

-- Required for REFRESH MATERIALIZED VIEW CONCURRENTLY
CREATE UNIQUE INDEX financial_summaries_key
  ON financial_summaries (studio_id, period_year, period_month);
