import type { ClientNoteRepository } from "../repositories/client-note.repository.js";

export class ClientNoteService {
	constructor(private repo: ClientNoteRepository) {}

	async create(
		studioId: string,
		clientId: string,
		professionalId: string,
		content: string,
	) {
		return this.repo.create(studioId, clientId, professionalId, content);
	}

	async listByClient(
		studioId: string,
		clientId: string,
		cursor?: string,
		limit = 20,
	) {
		const rows = await this.repo.listByClient(
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
}
