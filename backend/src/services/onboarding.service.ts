import type { OnboardingRepository } from "../repositories/onboarding.repository.js";
import { NotFoundError, ValidationError } from "../utils/errors.js";

const STEP_ORDER = [
	"studio_data",
	"services",
	"business_hours",
	"complete",
] as const;

export class OnboardingService {
	constructor(private repo: OnboardingRepository) {}

	async getByStudioId(studioId: string) {
		const state = await this.repo.findByStudioId(studioId);
		if (!state) throw new NotFoundError("Onboarding state not found");
		return state;
	}

	async updateStep(studioId: string, step: string) {
		// Validate forward-only transitions (skipping allowed, going back not)
		const current = await this.repo.findByStudioId(studioId);
		if (!current) throw new NotFoundError("Onboarding state not found");

		const currentIdx = STEP_ORDER.indexOf(
			current.current_step as (typeof STEP_ORDER)[number],
		);
		const targetIdx = STEP_ORDER.indexOf(step as (typeof STEP_ORDER)[number]);
		if (targetIdx <= currentIdx) {
			throw new ValidationError("Cannot go back to a previous step");
		}

		const updated = await this.repo.updateStep(studioId, step);
		if (!updated) throw new NotFoundError("Onboarding state not found");
		return updated;
	}
}
