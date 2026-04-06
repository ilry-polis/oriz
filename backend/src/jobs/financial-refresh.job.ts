import type { Pool } from "pg";

// ─── Types ─────────────────────────────────────────────────────────────────

/**
 * Interface for the financial refresh queue.
 * Implementations: BullMQ (when Redis available) or in-process debounced fallback.
 * Uses studioId as jobId to deduplicate — multiple rapid completions for the same
 * studio only trigger one refresh.
 */
export interface FinancialRefreshQueue {
	add(studioId: string): void;
}

// ─── In-process Fallback ────────────────────────────────────────────────────

/**
 * In-process debounced fallback for when Redis is unavailable.
 * Deduplicates per studioId: clears existing timer and sets a new 5s delay.
 */
class InProcessFinancialRefreshQueue implements FinancialRefreshQueue {
	private timers = new Map<string, ReturnType<typeof setTimeout>>();

	constructor(private pool: Pool) {}

	add(studioId: string): void {
		// Cancel any pending refresh for this studio
		const existing = this.timers.get(studioId);
		if (existing) clearTimeout(existing);

		const timer = setTimeout(async () => {
			this.timers.delete(studioId);
			try {
				await this.pool.query(
					"REFRESH MATERIALIZED VIEW CONCURRENTLY financial_summaries",
				);
			} catch {
				// Non-critical: view refresh failure is silent (data is stale but not missing)
			}
		}, 5000);

		this.timers.set(studioId, timer);
	}
}

// ─── BullMQ Queue ──────────────────────────────────────────────────────────

/**
 * BullMQ-backed queue using Redis for reliable deduplication across processes.
 * Uses jobId = studioId so duplicate jobs are coalesced automatically by BullMQ.
 */
class BullMQFinancialRefreshQueue implements FinancialRefreshQueue {
	private queue: import("bullmq").Queue;
	private worker: import("bullmq").Worker;

	constructor(
		pool: Pool,
		redisConnection: { host: string; port: number } | { url: string },
	) {
		// Dynamic import to avoid hard dependency when BullMQ not available
		const { Queue, Worker } = require("bullmq");

		this.queue = new Queue("financial-refresh", {
			connection: redisConnection,
			defaultJobOptions: {
				attempts: 3,
				backoff: { type: "exponential", delay: 5000 },
				removeOnComplete: { count: 10 },
				removeOnFail: { count: 50 },
			},
		});

		this.worker = new Worker(
			"financial-refresh",
			async () => {
				await pool.query(
					"REFRESH MATERIALIZED VIEW CONCURRENTLY financial_summaries",
				);
			},
			{
				connection: redisConnection,
				concurrency: 1,
			},
		);

		this.worker.on("failed", (_job: unknown, err: Error) => {
			console.error("[financial-refresh] Job failed:", err.message);
		});
	}

	add(studioId: string): void {
		// Fire-and-forget: jobId = studioId deduplicates in BullMQ
		this.queue
			.add("refresh", { studioId }, { jobId: studioId })
			.catch((err: Error) => {
				console.error(
					"[financial-refresh] Failed to enqueue refresh:",
					err.message,
				);
			});
	}

	async close(): Promise<void> {
		await this.worker.close();
		await this.queue.close();
	}
}

// ─── Factory ───────────────────────────────────────────────────────────────

/**
 * Creates a FinancialRefreshQueue. Uses BullMQ if Redis URL provided,
 * otherwise falls back to in-process debounced implementation.
 *
 * @param pool - pg Pool for executing the REFRESH query
 * @param redisUrl - Optional Redis URL (e.g., "redis://localhost:6379")
 */
export function createFinancialRefreshQueue(
	pool: Pool,
	redisUrl?: string,
): FinancialRefreshQueue {
	if (redisUrl) {
		try {
			return new BullMQFinancialRefreshQueue(pool, { url: redisUrl });
		} catch {
			// BullMQ init failed: fall through to in-process fallback
		}
	}
	return new InProcessFinancialRefreshQueue(pool);
}
