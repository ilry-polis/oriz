import type { Pool } from "pg";

export type ServiceRow = {
	id: string;
	studio_id: string;
	category_id: string;
	name: string;
	duration_minutes: number;
	price: number;
	buffer_minutes: number;
	is_active: boolean;
	deleted_at: string | null;
	created_at: string;
	updated_at: string;
};

export type CreateServiceInput = {
	studioId: string;
	categoryId: string;
	name: string;
	durationMinutes: number;
	price: number;
	bufferMinutes: number;
	isActive: boolean;
};

export type UpdateServiceInput = {
	categoryId?: string;
	name?: string;
	durationMinutes?: number;
	price?: number;
	bufferMinutes?: number;
};

export type ListServicesResult = {
	services: ServiceRow[];
	hasMore: boolean;
	nextCursor: string | null;
};

const SERVICE_COLUMNS = `
  s.id,
  s.studio_id,
  s.category_id,
  s.name,
  s.duration_minutes,
  s.price,
  s.buffer_minutes,
  s.is_active,
  s.deleted_at,
  s.created_at,
  s.updated_at
`.trim();

export class ServiceRepository {
	constructor(private pool: Pool) {}

	async create(input: CreateServiceInput): Promise<ServiceRow> {
		const { rows } = await this.pool.query<ServiceRow>(
			`INSERT INTO services (id, studio_id, category_id, name, duration_minutes, price, buffer_minutes, is_active)
       VALUES (gen_random_uuid(), $1, $2, $3, $4, $5, $6, $7)
       RETURNING id, studio_id, category_id, name, duration_minutes, price, buffer_minutes, is_active, deleted_at, created_at, updated_at`,
			[
				input.studioId,
				input.categoryId,
				input.name,
				input.durationMinutes,
				input.price,
				input.bufferMinutes,
				input.isActive,
			],
		);
		return rows[0] as ServiceRow;
	}

	async list(
		studioId: string,
		cursor?: string,
		limit = 20,
	): Promise<ListServicesResult> {
		const fetchLimit = limit + 1;
		const params: unknown[] = [studioId, fetchLimit];

		let cursorClause = "";
		if (cursor) {
			params.push(cursor);
			cursorClause = `AND (sc.name, s.name, s.id) > (SELECT sc2.name, s2.name, s2.id FROM services s2 LEFT JOIN service_categories sc2 ON sc2.id = s2.category_id WHERE s2.id = $${params.length} AND s2.studio_id = $1)`;
		}

		const { rows } = await this.pool.query<
			ServiceRow & { category_name: string }
		>(
			`SELECT ${SERVICE_COLUMNS}, sc.name AS category_name
       FROM services s
       LEFT JOIN service_categories sc ON sc.id = s.category_id
       WHERE s.studio_id = $1
         AND s.deleted_at IS NULL
         ${cursorClause}
       ORDER BY sc.name ASC, s.name ASC, s.id ASC
       LIMIT $2`,
			params,
		);

		const hasMore = rows.length > limit;
		const services = hasMore ? rows.slice(0, limit) : rows;
		const nextCursor = hasMore
			? (services[services.length - 1]?.id ?? null)
			: null;

		return {
			services: services as unknown as ServiceRow[],
			hasMore,
			nextCursor,
		};
	}

	async getById(
		studioId: string,
		serviceId: string,
	): Promise<ServiceRow | null> {
		const { rows } = await this.pool.query<ServiceRow>(
			`SELECT ${SERVICE_COLUMNS}
       FROM services s
       WHERE s.studio_id = $1
         AND s.id = $2
         AND s.deleted_at IS NULL`,
			[studioId, serviceId],
		);
		return rows[0] ?? null;
	}

	async update(
		studioId: string,
		serviceId: string,
		data: UpdateServiceInput,
	): Promise<ServiceRow> {
		const setClauses: string[] = [];
		const params: unknown[] = [];

		if (data.categoryId !== undefined) {
			params.push(data.categoryId);
			setClauses.push(`category_id = $${params.length}`);
		}
		if (data.name !== undefined) {
			params.push(data.name);
			setClauses.push(`name = $${params.length}`);
		}
		if (data.durationMinutes !== undefined) {
			params.push(data.durationMinutes);
			setClauses.push(`duration_minutes = $${params.length}`);
		}
		if (data.price !== undefined) {
			params.push(data.price);
			setClauses.push(`price = $${params.length}`);
		}
		if (data.bufferMinutes !== undefined) {
			params.push(data.bufferMinutes);
			setClauses.push(`buffer_minutes = $${params.length}`);
		}

		setClauses.push("updated_at = NOW()");

		params.push(studioId);
		const studioParam = params.length;
		params.push(serviceId);
		const idParam = params.length;

		const { rows } = await this.pool.query<ServiceRow>(
			`UPDATE services
       SET ${setClauses.join(", ")}
       WHERE studio_id = $${studioParam}
         AND id = $${idParam}
         AND deleted_at IS NULL
       RETURNING id, studio_id, category_id, name, duration_minutes, price, buffer_minutes, is_active, deleted_at, created_at, updated_at`,
			params,
		);
		return rows[0] as ServiceRow;
	}

	async setActive(
		studioId: string,
		serviceId: string,
		isActive: boolean,
	): Promise<ServiceRow> {
		const { rows } = await this.pool.query<ServiceRow>(
			`UPDATE services
       SET is_active = $1, updated_at = NOW()
       WHERE studio_id = $2
         AND id = $3
         AND deleted_at IS NULL
       RETURNING id, studio_id, category_id, name, duration_minutes, price, buffer_minutes, is_active, deleted_at, created_at, updated_at`,
			[isActive, studioId, serviceId],
		);
		return rows[0] as ServiceRow;
	}

	async softDelete(studioId: string, serviceId: string): Promise<void> {
		await this.pool.query(
			`UPDATE services
       SET deleted_at = NOW(), updated_at = NOW()
       WHERE studio_id = $1
         AND id = $2
         AND deleted_at IS NULL`,
			[studioId, serviceId],
		);
	}
}
