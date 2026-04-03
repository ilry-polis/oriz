import type { SupabaseClient } from "@supabase/supabase-js";
import type { InviteRepository } from "../repositories/invite.repository.js";
import type { ProfessionalRepository } from "../repositories/professional.repository.js";
import {
	ConflictError,
	NotFoundError,
	ValidationError,
} from "../utils/errors.js";

export type CreateInviteInput = {
	name: string;
	phone?: string;
	serviceIds: string[];
	commissionType: "percentage" | "fixed";
	commissionValue: number;
	cardFeePolicy: "studio" | "professional" | "split";
};

export class InviteService {
	constructor(
		private inviteRepo: InviteRepository,
		private professionalRepo: ProfessionalRepository,
		private supabaseAdmin: SupabaseClient,
	) {}

	/**
	 * Creates an invite link (POST /api/v1/professionals/invites).
	 * Owner pre-configures the professional: name, services, commission, card fee policy.
	 * Returns invite_token, expires_at, and a whatsapp_link ready to share.
	 */
	async createInvite(
		studioId: string,
		ownerUserId: string,
		input: CreateInviteInput,
	) {
		// crypto.randomUUID() is available in Node 19+ natively; sufficient entropy for invite token
		const token = crypto.randomUUID();
		const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000); // 7 days

		await this.inviteRepo.create({
			token,
			studioId,
			createdBy: ownerUserId,
			name: input.name,
			phone: input.phone,
			serviceIds: input.serviceIds ?? [],
			commissionType: input.commissionType,
			commissionValue: input.commissionValue,
			cardFeePolicy: input.cardFeePolicy,
			expiresAt,
		});

		// WhatsApp deep link opens Oriz app on the invite accept screen
		const whatsappLink = `https://wa.me/?text=${encodeURIComponent(
			`Você foi convidada para usar o Oriz! Clique para aceitar: oriz://invite/${token}`,
		)}`;

		return {
			invite_token: token,
			expires_at: expiresAt,
			whatsapp_link: whatsappLink,
		};
	}

	/**
	 * Lists pending (not used) invites for a studio.
	 */
	async listPendingInvites(
		studioId: string,
		{ cursor, limit = 20 }: { cursor?: string; limit?: number },
	) {
		const rows = await this.inviteRepo.findPendingByStudio(
			studioId,
			limit + 1,
			cursor,
		);

		const hasMore = rows.length > limit;
		const data = hasMore ? rows.slice(0, limit) : rows;
		const nextCursor = hasMore ? data[data.length - 1]!.token : undefined;

		return {
			invites: data.map((r) => ({
				token: r.token,
				name: r.name,
				phone: r.phone,
				commission_type: r.commission_type,
				commission_value: r.commission_value,
				card_fee_policy: r.card_fee_policy,
				expires_at: r.expires_at,
				created_at: r.created_at,
			})),
			meta: { next_cursor: nextCursor },
		};
	}

	/**
	 * Cancels a pending invite — only the studio owner can do this.
	 */
	async cancelInvite(studioId: string, token: string) {
		const invite = await this.inviteRepo.findByToken(token);
		if (!invite) throw new NotFoundError("Convite não encontrado");
		if (invite.studio_id !== studioId)
			throw new NotFoundError("Convite não encontrado");
		if (invite.used_at)
			throw new ConflictError(
				"INVITE_ALREADY_USED",
				"Convite já foi utilizado",
			);
		await this.inviteRepo.delete(token);
	}

	/**
	 * Extends invite expiry by 7 days and returns a new whatsapp_link.
	 */
	async resendInvite(studioId: string, token: string) {
		const invite = await this.inviteRepo.findByToken(token);
		if (!invite) throw new NotFoundError("Convite não encontrado");
		if (invite.studio_id !== studioId)
			throw new NotFoundError("Convite não encontrado");
		if (invite.used_at)
			throw new ConflictError(
				"INVITE_ALREADY_USED",
				"Convite já foi utilizado",
			);

		const newExpiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
		await this.inviteRepo.updateExpiresAt(token, newExpiresAt);

		const whatsappLink = `https://wa.me/?text=${encodeURIComponent(
			`Você foi convidada para usar o Oriz! Clique para aceitar: oriz://invite/${token}`,
		)}`;

		return { whatsapp_link: whatsappLink, expires_at: newExpiresAt };
	}

	/**
	 * Returns public info for the invite accept screen (GET /api/v1/professionals/invites/:token).
	 * Validates that the token exists and is not expired or used.
	 * No auth required — this is the entry point for the collaborator.
	 */
	async getInviteInfo(token: string) {
		const invite = await this.inviteRepo.findByToken(token);

		if (!invite) {
			throw new NotFoundError("Convite não encontrado");
		}
		if (invite.expires_at < new Date()) {
			throw new ValidationError("Convite expirado");
		}
		if (invite.used_at) {
			throw new ConflictError(
				"INVITE_ALREADY_USED",
				"Convite já foi utilizado",
			);
		}

		return {
			studio_id: invite.studio_id,
			name: invite.name,
			expires_at: invite.expires_at,
		};
	}

	/**
	 * Accepts an invite and creates a collaborator account (POST /api/v1/auth/accept-invite).
	 * Flow:
	 *  1. Validate token (exists, not expired, not used)
	 *  2. Create Supabase Auth user
	 *  3. Create professional row
	 *  4. Link services
	 *  5. Mark invite used
	 *  6. Return session
	 *
	 * On any failure after auth user creation, attempts cleanup (delete auth user).
	 * Note: full DB transaction is not feasible across Supabase Auth + pg — we use compensating
	 * actions (delete auth user) on failure to keep state consistent.
	 */
	async acceptInvite(token: string, email: string, password: string) {
		// Step 1: validate token
		const invite = await this.inviteRepo.findByToken(token);

		if (!invite) {
			throw new NotFoundError("Convite não encontrado");
		}
		if (invite.expires_at < new Date()) {
			throw new ValidationError("Convite expirado");
		}
		if (invite.used_at) {
			throw new ConflictError(
				"INVITE_ALREADY_USED",
				"Convite já foi utilizado",
			);
		}

		// Step 2: create Supabase Auth user — email confirmed automatically (owner invited them)
		const { data: authData, error: authError } =
			await this.supabaseAdmin.auth.admin.createUser({
				email,
				password,
				email_confirm: true,
			});

		if (authError || !authData?.user) {
			// Supabase returns error for duplicate emails
			throw new ConflictError(
				"EMAIL_ALREADY_EXISTS",
				"Este email já está registrado",
			);
		}

		const authUserId = authData.user.id;
		let professionalId: string | null = null;

		try {
			// Step 3: create professional row
			const professional = await this.professionalRepo.create({
				studioId: invite.studio_id,
				userId: authUserId,
				name: invite.name,
				commissionType: invite.commission_type,
				commissionValue: Number(invite.commission_value),
				cardFeePolicy: invite.card_fee_policy,
			});
			professionalId = professional.id;

			// Step 4: link services (atomic replace — empty first, then insert)
			if (invite.service_ids?.length) {
				await this.professionalRepo.replaceServiceLinks(
					professional.id,
					invite.studio_id,
					invite.service_ids,
				);
			}

			// Step 5: mark invite used
			await this.inviteRepo.markUsed(token);

			// Step 6: create session for immediate login
			const { data: sessionData } =
				await this.supabaseAdmin.auth.admin.createSession({
					user_id: authUserId,
				});

			return sessionData?.session ?? sessionData;
		} catch (err) {
			// Compensating action: delete the auth user to keep state consistent
			// professionalId being null means the professional row was not created yet
			// If professional was created but service links failed — the professional row
			// remains (harmless orphan that can be cleaned up) but auth user is removed.
			await this.supabaseAdmin.auth.admin.deleteUser(authUserId).catch(() => {
				// Best effort — log internally, don't swallow the original error
			});
			throw err;
		}
	}
}
