import { beforeEach, describe, expect, it, vi } from "vitest";
import type {
	PackageSubscriptionRepository,
	PackageSubscriptionRow,
} from "../../src/repositories/package-subscription.repository.js";
import type {
	PackageRepository,
	PackageRow,
} from "../../src/repositories/package.repository.js";
import type { PaymentRepository } from "../../src/repositories/payment.repository.js";
import type {
	ServiceRepository,
	ServiceRow,
} from "../../src/repositories/service.repository.js";
import { PackageService } from "../../src/services/package.service.js";
import { ConflictError, NotFoundError } from "../../src/utils/errors.js";

// ─── Factories ────────────────────────────────────────────────────────────────

function makePackage(overrides: Partial<PackageRow> = {}): PackageRow {
	return {
		id: "pkg-1",
		studio_id: "studio-A",
		service_id: "svc-1",
		name: "Pacote Cílios 10 sessões",
		total_sessions: 10,
		price: 150000, // R$1500,00
		validity_days: 180,
		created_at: "2026-01-01T00:00:00Z",
		updated_at: "2026-01-01T00:00:00Z",
		...overrides,
	};
}

function makeService(overrides: Partial<ServiceRow> = {}): ServiceRow {
	return {
		id: "svc-1",
		studio_id: "studio-A",
		category_id: "cat-1",
		name: "Cílios Volume Russo",
		duration_minutes: 120,
		price: 18000,
		buffer_minutes: 15,
		is_active: true,
		deleted_at: null,
		created_at: "2026-01-01T00:00:00Z",
		updated_at: "2026-01-01T00:00:00Z",
		...overrides,
	};
}

function makeSubscription(
	overrides: Partial<PackageSubscriptionRow> = {},
): PackageSubscriptionRow {
	const now = new Date();
	const expires = new Date(now.getTime() + 90 * 86400000).toISOString();
	return {
		id: "sub-1",
		studio_id: "studio-A",
		package_id: "pkg-1",
		client_id: "client-1",
		sessions_used: 0,
		sessions_total: 10,
		expires_at: expires,
		status: "active",
		created_at: now.toISOString(),
		updated_at: now.toISOString(),
		...overrides,
	};
}

// ─── Setup ────────────────────────────────────────────────────────────────────

describe("PackageService", () => {
	let service: PackageService;
	let packageRepo: PackageRepository;
	let packageSubRepo: PackageSubscriptionRepository;
	let serviceRepo: ServiceRepository;
	let paymentRepo: PaymentRepository;

	beforeEach(() => {
		packageRepo = {
			list: vi.fn(),
			getById: vi.fn(),
			create: vi.fn(),
			update: vi.fn(),
			delete: vi.fn(),
			getUnitPrice: vi.fn(),
		} as unknown as PackageRepository;

		packageSubRepo = {
			create: vi.fn(),
			deductSession: vi.fn(),
			getActiveForClientService: vi.fn(),
			list: vi.fn(),
			getById: vi.fn(),
			updateExpiresAt: vi.fn(),
		} as unknown as PackageSubscriptionRepository;

		serviceRepo = {
			getById: vi.fn(),
		} as unknown as ServiceRepository;

		paymentRepo = {
			create: vi.fn(),
		} as unknown as PaymentRepository;

		service = new PackageService(
			packageRepo,
			packageSubRepo,
			serviceRepo,
			paymentRepo,
		);
	});

	// ─── Package CRUD ─────────────────────────────────────────────────────────

	describe("create", () => {
		it("succeeds with valid service_id", async () => {
			const svc = makeService();
			const pkg = makePackage();
			(serviceRepo.getById as ReturnType<typeof vi.fn>).mockResolvedValue(svc);
			(packageRepo.create as ReturnType<typeof vi.fn>).mockResolvedValue(pkg);

			const result = await service.create("studio-A", {
				serviceId: "svc-1",
				name: "Pacote Cílios 10 sessões",
				totalSessions: 10,
				price: 150000,
				validityDays: 180,
			});

			expect(result).toEqual(pkg);
			expect(serviceRepo.getById).toHaveBeenCalledWith("studio-A", "svc-1");
			expect(packageRepo.create).toHaveBeenCalledWith({
				studioId: "studio-A",
				serviceId: "svc-1",
				name: "Pacote Cílios 10 sessões",
				totalSessions: 10,
				price: 150000,
				validityDays: 180,
			});
		});

		it("fails with unknown service_id (NotFoundError)", async () => {
			(serviceRepo.getById as ReturnType<typeof vi.fn>).mockResolvedValue(null);

			await expect(
				service.create("studio-A", {
					serviceId: "nonexistent-svc",
					name: "Pacote",
					totalSessions: 5,
					price: 50000,
					validityDays: 90,
				}),
			).rejects.toThrow(NotFoundError);
		});
	});

	describe("delete", () => {
		it("fails when active subscriptions exist (ConflictError)", async () => {
			// packageRepo.delete already throws ConflictError if active subs exist
			// Service delegates to repo after getById validation
			const pkg = makePackage();
			(packageRepo.getById as ReturnType<typeof vi.fn>).mockResolvedValue(pkg);
			(packageRepo.delete as ReturnType<typeof vi.fn>).mockRejectedValue(
				new ConflictError(
					"PACKAGE_HAS_SUBSCRIPTIONS",
					"Cannot delete package with active subscriptions",
				),
			);

			await expect(service.delete("studio-A", "pkg-1")).rejects.toThrow(
				ConflictError,
			);
		});
	});

	// ─── Subscription Creation ─────────────────────────────────────────────────

	describe("createSubscription", () => {
		it("computes correct expires_at from validity_days", async () => {
			const pkg = makePackage({ validity_days: 90 });
			const sub = makeSubscription();
			(packageRepo.getById as ReturnType<typeof vi.fn>).mockResolvedValue(pkg);
			(packageSubRepo.create as ReturnType<typeof vi.fn>).mockResolvedValue(
				sub,
			);
			(paymentRepo.create as ReturnType<typeof vi.fn>).mockResolvedValue({});

			const before = Date.now();
			await service.createSubscription("studio-A", "pkg-1", "client-1");
			const after = Date.now();

			const createCall = (packageSubRepo.create as ReturnType<typeof vi.fn>)
				.mock.calls[0]?.[0];
			const expiresAt = new Date(createCall.expiresAt).getTime();
			const expectedMin = before + 90 * 86400000;
			const expectedMax = after + 90 * 86400000;

			expect(expiresAt).toBeGreaterThanOrEqual(expectedMin);
			expect(expiresAt).toBeLessThanOrEqual(expectedMax);
		});

		it('creates a payment row with type="pacote" and amount=package.price', async () => {
			const pkg = makePackage({ price: 150000 });
			const sub = makeSubscription();
			(packageRepo.getById as ReturnType<typeof vi.fn>).mockResolvedValue(pkg);
			(packageSubRepo.create as ReturnType<typeof vi.fn>).mockResolvedValue(
				sub,
			);
			(paymentRepo.create as ReturnType<typeof vi.fn>).mockResolvedValue({});

			await service.createSubscription("studio-A", "pkg-1", "client-1");

			expect(paymentRepo.create).toHaveBeenCalledWith(
				expect.objectContaining({
					studioId: "studio-A",
					clientId: "client-1",
					appointmentId: null,
					amount: 150000,
					type: "pacote",
				}),
			);
		});
	});

	// ─── Session Deduction ────────────────────────────────────────────────────

	describe("deductSession", () => {
		it("returns updated subscription with sessions_used + 1", async () => {
			const sub = makeSubscription({
				sessions_used: 2,
				sessions_total: 10,
				status: "active",
			});
			const updatedSub = makeSubscription({
				sessions_used: 3,
				sessions_total: 10,
				status: "active",
			});
			(
				packageSubRepo.deductSession as ReturnType<typeof vi.fn>
			).mockResolvedValue(updatedSub);

			const result = await service.deductSession("studio-A", sub.id);

			expect(result).toEqual(updatedSub);
			expect(result?.sessions_used).toBe(3);
		});

		it("returns null for expired subscription (atomic guard)", async () => {
			(
				packageSubRepo.deductSession as ReturnType<typeof vi.fn>
			).mockResolvedValue(null);

			const result = await service.deductSession("studio-A", "expired-sub-1");

			expect(result).toBeNull();
		});

		it('marks status="completed" when sessions_used reaches sessions_total', async () => {
			const completedSub = makeSubscription({
				sessions_used: 10,
				sessions_total: 10,
				status: "completed",
			});
			(
				packageSubRepo.deductSession as ReturnType<typeof vi.fn>
			).mockResolvedValue(completedSub);

			const result = await service.deductSession("studio-A", "sub-1");

			expect(result?.status).toBe("completed");
			expect(result?.sessions_used).toBe(10);
		});
	});

	// ─── Multi-tenancy ────────────────────────────────────────────────────────

	describe("multi-tenancy", () => {
		it("create: studio-A cannot create with service from studio-B", async () => {
			// serviceRepo.getById returns null for studio-A + service from studio-B
			(serviceRepo.getById as ReturnType<typeof vi.fn>).mockResolvedValue(null);

			await expect(
				service.create("studio-A", {
					serviceId: "svc-from-studio-B",
					name: "Pacote",
					totalSessions: 5,
					price: 50000,
					validityDays: 90,
				}),
			).rejects.toThrow(NotFoundError);
		});
	});
});
