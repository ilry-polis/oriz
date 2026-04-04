-- Indexes for keyset pagination performance
-- Services: supports ORDER BY (category_name, service_name, id)
CREATE INDEX IF NOT EXISTS idx_services_category_name_id
  ON services (category_id, name, id)
  WHERE deleted_at IS NULL;

-- Appointments: supports month-summary aggregation and date range queries
CREATE INDEX IF NOT EXISTS idx_appointments_studio_date_status
  ON appointments (studio_id, date, status);

-- Appointments: supports date range + professional filter
CREATE INDEX IF NOT EXISTS idx_appointments_studio_prof_date
  ON appointments (studio_id, professional_id, date);

-- Blocked slots: supports date range + professional filter
CREATE INDEX IF NOT EXISTS idx_blocked_slots_studio_prof_date
  ON blocked_slots (studio_id, professional_id, date);
