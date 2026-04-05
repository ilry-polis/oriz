import type {
	ListSubscriptionsResult,
	PackageSubscriptionRepository,
	PackageSubscriptionRow,
	SubscriptionStatus,
} from "../repositories/package-subscription.repository.js";
import type {
	ListPackagesResult,
	PackageRepository,
	PackageRow,
	UpdatePackageInput,
} from "../repositories/package.repository.js";
import type { PaymentRepository } from "../repositories/payment.repository.js";
import type { ServiceRepository } from "../repositories/service.repository.js";
import { NotFoundError } from "../utils/errors.js";

// ─── Types ─────────────────────────────────────────────────────────────────

export type CreatePackageParams = {
	serviceId: string;
	name: string;
	totalSessions: number;
	price: number;
	validityDays: number;
};

export type UpdatePackageParams = UpdatePackageInput;

export type ListPackagesOptions = {
	serviceId?: string;
	cursor?: string;
	limit?: number;
};

export type ListSubscriptionsOptions = {
	packageId?: string;
	clientId?: string;
	status?: SubscriptionStatus;
	cursor?: string;
	limit?: number;
};

// ─── Service ────────────────────────────────────────────────────────────────

export class PackageService {
	constructor(
		private packageRepo: PackageRepository,
		private packageSubRepo: PackageSubscriptionRepository,
		private serviceRepo: ServiceRepository,
		private paymentRepo: PaymentRepository,
	) {}

	// ─── Package CRUD ──────────────────────────────────────────────────────────

	async create(
		studioId: string,
		params: CreatePackageParams,
	): Promise<PackageRow> {
		const svc = await this.serviceRepo.getById(studioId, params.serviceId);
		if (!svc) {
			throw new NotFoundError(`Service not found: ${params.serviceId}`);
		}

		return this.packageRepo.create({
			studioId,
			serviceId: params.serviceId,
			name: params.name,
			totalSessions: params.totalSessions,
			price: params.price,
			validityDays: params.validityDays,
		});
	}

	async list(
		studioId: string,
		options: ListPackagesOptions = {},
	): Promise<ListPackagesResult> {
		return this.packageRepo.list(studioId, options);
	}

	async getById(studioId: string, packageId: string): Promise<PackageRow> {
		const pkg = await this.packageRepo.getById(studioId, packageId);
		if (!pkg) {
			throw new NotFoundError(`Package not found: ${packageId}`);
		}
		return pkg;
	}

	async update(
		studioId: string,
		packageId: string,
		params: UpdatePackageParams,
	): Promise<PackageRow> {
		// Validate existence first
		await this.getById(studioId, packageId);
		const updated = await this.packageRepo.update(studioId, packageId, params);
		if (!updated) {
			throw new NotFoundError(`Package not found: ${packageId}`);
		}
		return updated;
	}

	async delete(studioId: string, packageId: string): Promise<void> {
		// Validate existence — throws NotFoundError if missing
		await this.getById(studioId, packageId);
		// Repository throws ConflictError if active subscriptions exist
		await this.packageRepo.delete(studioId, packageId);
	}

	// ─── Subscription Management ───────────────────────────────────────────────

	/**
	 * Creates a package subscription for a client and records a payment row
	 * with type='pacote' so the sale appears as revenue in the financial dashboard.
	 *
	 * Expiration: computed as now() + validity_days (in milliseconds).
	 */
	async createSubscription(
		studioId: string,
		packageId: string,
		clientId: string,
	): Promise<PackageSubscriptionRow> {
		const pkg = await this.getById(studioId, packageId);

		const expiresAt = new Date(
			Date.now() + pkg.validity_days * 86400000,
		).toISOString();

		const subscription = await this.packageSubRepo.create({
			studioId,
			packageId,
			clientId,
			sessionsTotal: pkg.total_sessions,
			expiresAt,
		});

		// Record the package sale as revenue (type='pacote', no linked appointment)
		await this.paymentRepo.create({
			studioId,
			clientId,
			appointmentId: null,
			amount: pkg.price,
			method: "pix", // default; future enhancement: accept payment method as param
			type: "pacote",
			discountAmount: 0,
		});

		return subscription;
	}

	async listSubscriptions(
		studioId: string,
		options: ListSubscriptionsOptions = {},
	): Promise<ListSubscriptionsResult> {
		return this.packageSubRepo.list(studioId, options);
	}

	async getActiveForClientService(
		studioId: string,
		clientId: string,
		serviceId: string,
	): Promise<PackageSubscriptionRow | null> {
		return this.packageSubRepo.getActiveForClientService(
			studioId,
			clientId,
			serviceId,
		);
	}

	async extendSubscriptionExpiry(
		studioId: string,
		subscriptionId: string,
		newExpiresAt: string,
	): Promise<PackageSubscriptionRow | null> {
		return this.packageSubRepo.updateExpiresAt(
			studioId,
			subscriptionId,
			newExpiresAt,
		);
	}

	async getSubscriptionById(
		studioId: string,
		subscriptionId: string,
	): Promise<PackageSubscriptionRow | null> {
		return this.packageSubRepo.getById(studioId, subscriptionId);
	}

	async deductSession(
		studioId: string,
		subscriptionId: string,
	): Promise<PackageSubscriptionRow | null> {
		return this.packageSubRepo.deductSession(studioId, subscriptionId);
	}
}
