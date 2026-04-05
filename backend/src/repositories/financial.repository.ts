import type { Pool } from "pg";

// ─── Types ─────────────────────────────────────────────────────────────────

export type LiveQueryResult = {
	total_revenue: number; // in centavos
	avg_ticket: number; // in centavos
	total_appointments: number;
};

export type MaterializedViewRow = {
	studio_id: string;
	period_year: number;
	period_month: number;
	total_revenue: number;
	avg_ticket: number;
	total_appointments: number;
};

export type BreakdownByProfessional = {
	professional_id: string;
	professional_name: string;
	total_amount: number;
	percentage: number;
};

export type BreakdownByService = {
	service_id: string;
	service_name: string;
	total_amount: number;
	percentage: number;
};

export type BreakdownByMethod = {
	method: string;
	total_amount: number;
	count: number;
	percentage: number;
};

export type DailyRevenueRow = {
	date: string;
	total_amount: number;
	appointment_count: number;
};

// ─── Repository ────────────────────────────────────────────────────────────

export class FinancialRepository {
	constructor(private pool: Pool) {}

	/**
	 * Get monthly summary from the materialized view financial_summaries.
	 * Returns null if no data exists yet for the given month.
	 */
	async getFromMaterializedView(
		studioId: string,
		year: number,
		month: number,
	): Promise<LiveQueryResult | null> {
		const { rows } = await this.pool.query<MaterializedViewRow>(
			`SELECT studio_id, period_year, period_month,
              total_revenue, avg_ticket, total_appointments
       FROM financial_summaries
       WHERE studio_id = $1
         AND period_year = $2
         AND period_month = $3
       LIMIT 1`,
			[studioId, year, month],
		);

		if (!rows[0]) return null;

		const row = rows[0];
		return {
			total_revenue: row.total_revenue,
			avg_ticket: row.avg_ticket,
			total_appointments: row.total_appointments,
		};
	}

	/**
	 * Live query for day/week granularity.
	 * Groups by appointment_id first to handle split payments correctly,
	 * then computes revenue/avg_ticket/count.
	 * Uses appointments(studio_id, date) index for efficiency.
	 */
	async getLiveQuery(
		studioId: string,
		dateFrom: string,
		dateTo: string,
	): Promise<LiveQueryResult> {
		const { rows } = await this.pool.query<LiveQueryResult>(
			`WITH appointment_totals AS (
         SELECT p.appointment_id,
                SUM(p.amount) AS appointment_total
         FROM payments p
         JOIN appointments a ON a.id = p.appointment_id
         WHERE a.studio_id = $1
           AND a.date BETWEEN $2 AND $3
           AND a.status = 'completed'
         GROUP BY p.appointment_id
       )
       SELECT
         COALESCE(SUM(appointment_total), 0)::int AS total_revenue,
         COALESCE(AVG(appointment_total), 0)::int AS avg_ticket,
         COUNT(*)::int AS total_appointments
       FROM appointment_totals`,
			[studioId, dateFrom, dateTo],
		);

		return (
			rows[0] ?? { total_revenue: 0, avg_ticket: 0, total_appointments: 0 }
		);
	}

	/**
	 * Revenue breakdown by professional, ranked by total descending.
	 * Uses net amount (amount - discount_amount where applicable).
	 * Leverages appointments(studio_id, date) index.
	 */
	async breakdownByProfessional(
		studioId: string,
		dateFrom: string,
		dateTo: string,
	): Promise<BreakdownByProfessional[]> {
		const { rows } = await this.pool.query<{
			professional_id: string;
			professional_name: string;
			total_amount: string;
			percentage: string;
		}>(
			`WITH totals AS (
         SELECT a.professional_id,
                pr.name AS professional_name,
                SUM(p.amount)::int AS total_amount
         FROM payments p
         JOIN appointments a ON a.id = p.appointment_id
         JOIN professionals pr ON pr.id = a.professional_id
         WHERE a.studio_id = $1
           AND a.date BETWEEN $2 AND $3
           AND a.status = 'completed'
         GROUP BY a.professional_id, pr.name
       ),
       grand_total AS (SELECT SUM(total_amount) AS gt FROM totals)
       SELECT t.professional_id,
              t.professional_name,
              t.total_amount,
              CASE WHEN gt.gt > 0
                   THEN ROUND(t.total_amount::numeric / gt.gt * 100, 2)
                   ELSE 0
              END AS percentage
       FROM totals t, grand_total gt
       ORDER BY t.total_amount DESC`,
			[studioId, dateFrom, dateTo],
		);

		return rows.map((r) => ({
			professional_id: r.professional_id,
			professional_name: r.professional_name,
			total_amount: Number(r.total_amount),
			percentage: Number(r.percentage),
		}));
	}

	/**
	 * Revenue breakdown by service, ranked by total descending.
	 * Leverages appointments(studio_id, date) index.
	 */
	async breakdownByService(
		studioId: string,
		dateFrom: string,
		dateTo: string,
	): Promise<BreakdownByService[]> {
		const { rows } = await this.pool.query<{
			service_id: string;
			service_name: string;
			total_amount: string;
			percentage: string;
		}>(
			`WITH totals AS (
         SELECT a.service_id,
                s.name AS service_name,
                SUM(p.amount)::int AS total_amount
         FROM payments p
         JOIN appointments a ON a.id = p.appointment_id
         JOIN services s ON s.id = a.service_id
         WHERE a.studio_id = $1
           AND a.date BETWEEN $2 AND $3
           AND a.status = 'completed'
         GROUP BY a.service_id, s.name
       ),
       grand_total AS (SELECT SUM(total_amount) AS gt FROM totals)
       SELECT t.service_id,
              t.service_name,
              t.total_amount,
              CASE WHEN gt.gt > 0
                   THEN ROUND(t.total_amount::numeric / gt.gt * 100, 2)
                   ELSE 0
              END AS percentage
       FROM totals t, grand_total gt
       ORDER BY t.total_amount DESC`,
			[studioId, dateFrom, dateTo],
		);

		return rows.map((r) => ({
			service_id: r.service_id,
			service_name: r.service_name,
			total_amount: Number(r.total_amount),
			percentage: Number(r.percentage),
		}));
	}

	/**
	 * Revenue breakdown by payment method, ranked by total descending.
	 * Uses net amount (amount - discount_amount).
	 * Leverages appointments(studio_id, date) index.
	 */
	async breakdownByMethod(
		studioId: string,
		dateFrom: string,
		dateTo: string,
	): Promise<BreakdownByMethod[]> {
		const { rows } = await this.pool.query<{
			method: string;
			total_amount: string;
			count: string;
			percentage: string;
		}>(
			`WITH totals AS (
         SELECT p.method,
                SUM(p.amount - p.discount_amount)::int AS total_amount,
                COUNT(*)::int AS count
         FROM payments p
         JOIN appointments a ON a.id = p.appointment_id
         WHERE a.studio_id = $1
           AND a.date BETWEEN $2 AND $3
           AND a.status = 'completed'
         GROUP BY p.method
       ),
       grand_total AS (SELECT SUM(total_amount) AS gt FROM totals)
       SELECT t.method,
              t.total_amount,
              t.count,
              CASE WHEN gt.gt > 0
                   THEN ROUND(t.total_amount::numeric / gt.gt * 100, 2)
                   ELSE 0
              END AS percentage
       FROM totals t, grand_total gt
       ORDER BY t.total_amount DESC`,
			[studioId, dateFrom, dateTo],
		);

		return rows.map((r) => ({
			method: r.method,
			total_amount: Number(r.total_amount),
			count: Number(r.count),
			percentage: Number(r.percentage),
		}));
	}

	/**
	 * Daily revenue for charting. Returns one row per day in range,
	 * ordered by date ascending.
	 * Leverages appointments(studio_id, date) index.
	 */
	async dailyRevenue(
		studioId: string,
		dateFrom: string,
		dateTo: string,
	): Promise<DailyRevenueRow[]> {
		const { rows } = await this.pool.query<{
			date: string;
			total_amount: string;
			appointment_count: string;
		}>(
			`SELECT a.date,
              SUM(p.amount - p.discount_amount)::int AS total_amount,
              COUNT(DISTINCT a.id)::int AS appointment_count
       FROM payments p
       JOIN appointments a ON a.id = p.appointment_id
       WHERE a.studio_id = $1
         AND a.date BETWEEN $2 AND $3
         AND a.status = 'completed'
       GROUP BY a.date
       ORDER BY a.date ASC`,
			[studioId, dateFrom, dateTo],
		);

		return rows.map((r) => ({
			date: r.date,
			total_amount: Number(r.total_amount),
			appointment_count: Number(r.appointment_count),
		}));
	}
}
