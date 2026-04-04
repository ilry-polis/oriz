import type {
	ClientRepository,
	ClientRow,
	CreateClientInput,
	ListClientsOptions,
	UpdateClientInput,
} from "../repositories/client.repository.js";
import { NotFoundError } from "../utils/errors.js";
import type { AuditLogService } from "./audit-log.service.js";
import type { ConsentService } from "./consent.service.js";

// ─── Types ───────────────────────────────────────────────────

export type ClientWithAutoTags = ClientRow & {
	auto_tags: string[];
};

export type CreateClientParams = CreateClientInput & {
	marketing_consent?: boolean;
};

export type ListClientsResult = {
	data: ClientWithAutoTags[];
	meta: {
		has_more: boolean;
		next_cursor: string | null;
	};
};

// ─── Auto-tag enrichment ─────────────────────────────────────

const INACTIVE_DAYS_THRESHOLD = 60;

function enrichAutoTags(client: ClientRow): ClientWithAutoTags {
	const auto_tags: string[] = [];

	if (!client.last_appointment_at) {
		auto_tags.push("novo");
	} else {
		const lastAppt = new Date(client.last_appointment_at);
		const diffMs = Date.now() - lastAppt.getTime();
		const diffDays = diffMs / (1000 * 60 * 60 * 24);
		if (diffDays >= INACTIVE_DAYS_THRESHOLD) {
			auto_tags.push("inativo");
		}
	}

	return { ...client, auto_tags };
}

// ─── Service ─────────────────────────────────────────────────

export class ClientService {
	constructor(
		private repo: ClientRepository,
		private consentService: ConsentService,
		private auditLogService: AuditLogService,
	) {}

	async createClient(
		studioId: string,
		userId: string,
		data: CreateClientParams,
	): Promise<ClientRow> {
		const { marketing_consent, ...clientData } = data;

		const client = await this.repo.create(studioId, clientData);

		if (marketing_consent) {
			// Fire-and-forget consent — failure should not prevent client creation
			await this.consentService.grant(
				client.id,
				studioId,
				"marketing_whatsapp",
			);
		}

		return client;
	}

	async listClients(
		studioId: string,
		opts: ListClientsOptions,
	): Promise<ListClientsResult> {
		const { rows, has_more, next_cursor } = await this.repo.list(
			studioId,
			opts,
		);

		const data = rows.map(enrichAutoTags);

		return {
			data,
			meta: { has_more, next_cursor },
		};
	}

	async getClientById(
		studioId: string,
		userId: string,
		clientId: string,
	): Promise<ClientWithAutoTags> {
		const client = await this.repo.getById(studioId, clientId);

		if (!client) {
			throw new NotFoundError("Client not found");
		}

		// LGPD: audit every view of client data
		await this.auditLogService.log({
			studioId,
			userId,
			action: "view",
			entityType: "client",
			entityId: clientId,
		});

		return enrichAutoTags(client);
	}

	async updateClient(
		studioId: string,
		userId: string,
		clientId: string,
		data: UpdateClientInput,
	): Promise<ClientRow> {
		const client = await this.repo.update(studioId, clientId, data);

		if (!client) {
			throw new NotFoundError("Client not found");
		}

		// LGPD: audit every edit of client data
		await this.auditLogService.log({
			studioId,
			userId,
			action: "edit",
			entityType: "client",
			entityId: clientId,
		});

		return client;
	}

	async updateTags(
		studioId: string,
		clientId: string,
		tags: string[],
	): Promise<ClientRow> {
		const client = await this.repo.update(studioId, clientId, { tags });

		if (!client) {
			throw new NotFoundError("Client not found");
		}

		return client;
	}

	async listAppointments(
		studioId: string,
		clientId: string,
		cursor?: string,
		limit = 20,
	) {
		const rows = await this.repo.listAppointments(
			studioId,
			clientId,
			cursor,
			limit + 1,
		);
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

	async anonymizeClient(
		studioId: string,
		userId: string,
		clientId: string,
	): Promise<ClientRow> {
		const client = await this.repo.anonymize(studioId, clientId);

		// LGPD: audit the data deletion/anonymization
		await this.auditLogService.log({
			studioId,
			userId,
			action: "delete",
			entityType: "client",
			entityId: clientId,
		});

		return client;
	}
}
