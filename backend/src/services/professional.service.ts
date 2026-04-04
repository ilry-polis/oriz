import type {
	ProfessionalRepository,
	UpdateProfessionalData,
} from "../repositories/professional.repository.js";
import { NotFoundError } from "../utils/errors.js";

export class ProfessionalService {
	constructor(private repo: ProfessionalRepository) {}

	// ─── Existing method (preserved) ─────────────────────────────────────────────

	async updateWorkingHours(
		professionalId: string,
		studioId: string,
		workingHours: Record<string, unknown>,
	) {
		const result = await this.repo.updateWorkingHours(
			professionalId,
			studioId,
			workingHours,
		);
		if (!result)
			throw new NotFoundError("Professional not found in this studio");
		return result;
	}

	async getProfessionalByUserId(userId: string, studioId: string) {
		return this.repo.findByUserId(userId, studioId);
	}

	// ─── New methods ──────────────────────────────────────────────────────────────

	/**
	 * Lists professionals in a studio with cursor-based pagination.
	 * Returns { data, meta: { has_more, next_cursor } }.
	 */
	async listProfessionals(studioId: string, cursor?: string, limit = 20) {
		const rows = await this.repo.list(studioId, cursor, limit + 1);
		const hasMore = rows.length > limit;
		const data = hasMore ? rows.slice(0, limit) : rows;
		return {
			data,
			meta: {
				has_more: hasMore,
				next_cursor: hasMore ? data[data.length - 1].id : null,
			},
		};
	}

	/**
	 * Returns a single professional with their service_ids, or throws NotFoundError.
	 */
	async getProfessionalById(studioId: string, professionalId: string) {
		const professional = await this.repo.getById(studioId, professionalId);
		if (!professional)
			throw new NotFoundError("Professional not found in this studio");

		const serviceIds = await this.repo.getServiceLinks(
			professionalId,
			studioId,
		);
		return { ...professional, service_ids: serviceIds };
	}

	/**
	 * Updates professional fields; optionally replaces service links atomically.
	 */
	async updateProfessional(
		studioId: string,
		professionalId: string,
		data: UpdateProfessionalData & { service_ids?: string[] },
	) {
		const { service_ids, ...updateData } = data;

		const updated = await this.repo.update(
			studioId,
			professionalId,
			updateData,
		);
		if (!updated)
			throw new NotFoundError("Professional not found in this studio");

		if (service_ids !== undefined) {
			await this.repo.replaceServiceLinks(
				professionalId,
				studioId,
				service_ids,
			);
		}

		return updated;
	}

	/**
	 * Toggles professional active/inactive status.
	 */
	async toggleActive(
		studioId: string,
		professionalId: string,
		isActive: boolean,
	) {
		const updated = await this.repo.update(studioId, professionalId, {
			isActive,
		});
		if (!updated)
			throw new NotFoundError("Professional not found in this studio");
		return updated;
	}

	/**
	 * Atomically replaces all service links for a professional.
	 * Validates professional belongs to studio before modifying.
	 */
	async replaceServiceLinks(
		studioId: string,
		professionalId: string,
		serviceIds: string[],
	) {
		const professional = await this.repo.getById(studioId, professionalId);
		if (!professional)
			throw new NotFoundError("Professional not found in this studio");
		await this.repo.replaceServiceLinks(professionalId, studioId, serviceIds);
	}
}
