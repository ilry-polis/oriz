import type { AnamnesisRepository } from "../repositories/anamnesis.repository.js";

type TemplateField = {
	key: string;
	label: string;
	type: "boolean" | "text" | "select";
	options?: string[];
};

const TEMPLATE_DEFAULTS: Record<string, TemplateField[]> = {
	lash: [
		{ key: "alergia_cola", label: "Alergia a cola de cílios", type: "boolean" },
		{ key: "lentes_contato", label: "Usa lentes de contato", type: "boolean" },
		{ key: "lagrima_artificial", label: "Usa lágrima artificial", type: "boolean" },
		{ key: "procedimento_anterior", label: "Procedimento anterior em cílios", type: "text" },
		{ key: "sensibilidade_ocular", label: "Sensibilidade ocular", type: "boolean" },
	],
	micropig: [
		{ key: "gravidez", label: "Gestante ou lactante", type: "boolean" },
		{ key: "anticoagulante", label: "Usa anticoagulante", type: "boolean" },
		{ key: "queloides", label: "Tendência a queloides", type: "boolean" },
		{ key: "diabetes", label: "Diabetes", type: "boolean" },
		{ key: "alergias", label: "Alergias conhecidas", type: "text" },
	],
	unhas: [
		{ key: "alergia_acetona", label: "Alergia a acetona ou produtos químicos", type: "boolean" },
		{ key: "fungos", label: "Histórico de fungos/micose", type: "boolean" },
		{ key: "unha_gel_anterior", label: "Procedimento anterior em unhas", type: "text" },
		{ key: "medicamentos", label: "Medicamentos em uso", type: "text" },
	],
	estetica: [
		{ key: "alergias", label: "Alergias conhecidas", type: "text" },
		{ key: "medicamentos", label: "Medicamentos em uso", type: "text" },
		{ key: "gravidez", label: "Gestante ou lactante", type: "boolean" },
		{ key: "problemas_pele", label: "Problemas de pele", type: "text" },
		{ key: "tratamento_dermatologico", label: "Em tratamento dermatológico", type: "boolean" },
	],
	cabelo: [
		{ key: "quimica_recente", label: "Química recente (tintura, alisamento)", type: "text" },
		{ key: "alergias", label: "Alergias a produtos capilares", type: "text" },
		{ key: "queda_cabelo", label: "Queda de cabelo", type: "boolean" },
		{ key: "couro_sensivel", label: "Couro cabeludo sensível", type: "boolean" },
		{ key: "medicamentos", label: "Medicamentos em uso", type: "text" },
	],
};

export class AnamnesisService {
	constructor(private repo: AnamnesisRepository) {}

	getTemplateDefaults(category: string): TemplateField[] {
		return TEMPLATE_DEFAULTS[category] ?? [];
	}

	async upsert(
		studioId: string,
		clientId: string,
		serviceCategoryId: string,
		fields: Record<string, unknown>,
	) {
		return this.repo.upsert(studioId, clientId, serviceCategoryId, fields);
	}

	async getByClientAndCategory(
		studioId: string,
		clientId: string,
		serviceCategoryId: string,
	) {
		const stored = await this.repo.getByClientAndCategory(
			studioId,
			clientId,
			serviceCategoryId,
		);

		// Find category name from service_category_id — for now use stored fields only
		// Template merging happens when we know the category slug
		return stored;
	}

	async listByClient(studioId: string, clientId: string) {
		return this.repo.listByClient(studioId, clientId);
	}

	mergeWithTemplate(
		category: string,
		storedFields: Record<string, unknown>,
	): Record<string, unknown> {
		const template = this.getTemplateDefaults(category);
		const merged: Record<string, unknown> = {};

		for (const field of template) {
			merged[field.key] =
				storedFields[field.key] !== undefined
					? storedFields[field.key]
					: field.type === "boolean"
						? false
						: "";
		}

		// Include any custom fields not in template
		for (const [key, value] of Object.entries(storedFields)) {
			if (!(key in merged)) {
				merged[key] = value;
			}
		}

		return merged;
	}
}
