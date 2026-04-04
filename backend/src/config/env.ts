import { z } from "zod";

const envSchema = z.object({
	DATABASE_URL: z.string().startsWith("postgresql://"),
	SUPABASE_URL: z.string().url(),
	SUPABASE_ANON_KEY: z.string().min(1),
	SUPABASE_SERVICE_ROLE: z.string().min(1),
	SUPABASE_JWT_SECRET: z.string().min(32),
	CORS_ORIGINS: z.string().optional(),
	REDIS_URL: z.string().optional(),
	PORT: z.coerce.number().int().positive().default(3000),
	NODE_ENV: z
		.enum(["development", "production", "test"])
		.default("development"),
});

export type Env = z.infer<typeof envSchema>;

export function parseEnv(): Env {
	const result = envSchema.safeParse(process.env);
	if (!result.success) {
		const formatted = result.error.issues
			.map((i) => `  ${i.path.join(".")}: ${i.message}`)
			.join("\n");
		throw new Error(`Invalid environment variables:\n${formatted}`);
	}
	return result.data;
}
