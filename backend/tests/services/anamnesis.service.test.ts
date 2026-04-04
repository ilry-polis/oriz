import { describe, it, expect, vi, beforeEach } from "vitest";
import { AnamnesisService } from "../../src/services/anamnesis.service.js";

const mockRepo = {
	upsert: vi.fn(),
	getByClientAndCategory: vi.fn(),
	listByClient: vi.fn(),
};

describe("AnamnesisService", () => {
	let service: AnamnesisService;

	beforeEach(() => {
		vi.clearAllMocks();
		service = new AnamnesisService(mockRepo as any);
	});

	describe("getTemplateDefaults", () => {
		it("returns template fields for known categories", () => {
			const lashDefaults = service.getTemplateDefaults("lash");
			expect(lashDefaults.length).toBeGreaterThan(0);
			expect(lashDefaults[0]).toHaveProperty("key");
			expect(lashDefaults[0]).toHaveProperty("label");
			expect(lashDefaults[0]).toHaveProperty("type");
		});

		it("returns empty array for unknown category", () => {
			expect(service.getTemplateDefaults("unknown")).toEqual([]);
		});

		it("has templates for all expected categories", () => {
			for (const cat of ["lash", "micropig", "unhas", "estetica", "cabelo"]) {
				expect(service.getTemplateDefaults(cat).length).toBeGreaterThan(0);
			}
		});
	});

	describe("mergeWithTemplate", () => {
		it("merges stored fields over template defaults", () => {
			const stored = { alergia_cola: true, custom_field: "extra" };
			const merged = service.mergeWithTemplate("lash", stored);
			expect(merged.alergia_cola).toBe(true);
			expect(merged.custom_field).toBe("extra");
			// Template fields not in stored data get defaults
			expect(merged.lentes_contato).toBe(false);
		});

		it("returns only stored fields for unknown category", () => {
			const stored = { key1: "val1" };
			const merged = service.mergeWithTemplate("unknown", stored);
			expect(merged).toEqual({ key1: "val1" });
		});
	});

	describe("upsert", () => {
		it("delegates to repository", async () => {
			const expected = { id: "a1", fields: { alergia_cola: true } };
			mockRepo.upsert.mockResolvedValue(expected);

			const result = await service.upsert("s1", "c1", "cat1", {
				alergia_cola: true,
			});
			expect(result).toEqual(expected);
			expect(mockRepo.upsert).toHaveBeenCalledWith("s1", "c1", "cat1", {
				alergia_cola: true,
			});
		});
	});

	describe("getByClientAndCategory", () => {
		it("returns stored anamnesis", async () => {
			const stored = {
				id: "a1",
				fields: { alergia_cola: true },
			};
			mockRepo.getByClientAndCategory.mockResolvedValue(stored);

			const result = await service.getByClientAndCategory("s1", "c1", "cat1");
			expect(result).toEqual(stored);
		});

		it("returns null when no anamnesis exists", async () => {
			mockRepo.getByClientAndCategory.mockResolvedValue(null);
			const result = await service.getByClientAndCategory("s1", "c1", "cat1");
			expect(result).toBeNull();
		});
	});

	describe("listByClient", () => {
		it("returns all anamneses for a client", async () => {
			const list = [
				{ id: "a1", service_category_id: "cat1" },
				{ id: "a2", service_category_id: "cat2" },
			];
			mockRepo.listByClient.mockResolvedValue(list);

			const result = await service.listByClient("s1", "c1");
			expect(result).toEqual(list);
			expect(mockRepo.listByClient).toHaveBeenCalledWith("s1", "c1");
		});
	});
});
