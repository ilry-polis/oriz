import { describe, it, expect, vi, beforeEach } from "vitest";
import { ClientNoteService } from "../../src/services/client-note.service.js";

const mockRepo = {
	create: vi.fn(),
	listByClient: vi.fn(),
};

describe("ClientNoteService", () => {
	let service: ClientNoteService;

	beforeEach(() => {
		vi.clearAllMocks();
		service = new ClientNoteService(mockRepo as any);
	});

	describe("create", () => {
		it("creates a note and returns it", async () => {
			const note = {
				id: "n1",
				studio_id: "s1",
				client_id: "c1",
				professional_id: "p1",
				content: "Skin patch test OK",
				created_at: "2026-04-02T10:00:00Z",
			};
			mockRepo.create.mockResolvedValue(note);

			const result = await service.create("s1", "c1", "p1", "Skin patch test OK");
			expect(result).toEqual(note);
			expect(mockRepo.create).toHaveBeenCalledWith(
				"s1",
				"c1",
				"p1",
				"Skin patch test OK",
			);
		});
	});

	describe("listByClient", () => {
		it("returns paginated notes in reverse chronological order", async () => {
			const notes = [
				{ id: "n2", content: "Second note", created_at: "2026-04-02T11:00:00Z" },
				{ id: "n1", content: "First note", created_at: "2026-04-02T10:00:00Z" },
			];
			mockRepo.listByClient.mockResolvedValue(notes);

			const result = await service.listByClient("s1", "c1");
			expect(result.data).toHaveLength(2);
			expect(result.meta.has_more).toBe(false);
			expect(result.meta.next_cursor).toBeNull();
		});

		it("detects has_more when results exceed limit", async () => {
			// Service asks for limit+1, so 3 items means has_more with limit=2
			const notes = [
				{ id: "n3", content: "Third", created_at: "2026-04-02T12:00:00Z" },
				{ id: "n2", content: "Second", created_at: "2026-04-02T11:00:00Z" },
				{ id: "n1", content: "First", created_at: "2026-04-02T10:00:00Z" },
			];
			mockRepo.listByClient.mockResolvedValue(notes);

			const result = await service.listByClient("s1", "c1", undefined, 2);
			expect(result.data).toHaveLength(2);
			expect(result.meta.has_more).toBe(true);
			expect(result.meta.next_cursor).toBe("n2");
		});

		it("passes cursor to repository", async () => {
			mockRepo.listByClient.mockResolvedValue([]);

			await service.listByClient("s1", "c1", "cursor-id", 10);
			expect(mockRepo.listByClient).toHaveBeenCalledWith(
				"s1",
				"c1",
				"cursor-id",
				11, // limit + 1
			);
		});
	});
});
