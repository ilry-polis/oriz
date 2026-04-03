import type { FastifyError, FastifyReply, FastifyRequest } from "fastify";
import { ZodError } from "zod";
import { AppError } from "../utils/errors.js";

type ErrorResponse = {
	errors: Array<{ code: string; message: string; field?: string }>;
};

export function errorHandler(
	error: FastifyError | Error,
	_request: FastifyRequest,
	reply: FastifyReply,
): void {
	if (error instanceof AppError) {
		const item: ErrorResponse["errors"][number] = {
			code: error.code,
			message: error.message,
		};
		if (error.field) {
			item.field = error.field;
		}
		reply
			.status(error.statusCode)
			.send({ errors: [item] } satisfies ErrorResponse);
		return;
	}

	if (error instanceof ZodError) {
		const errors = error.issues.map((issue) => ({
			code: "VALIDATION_ERROR",
			message: issue.message,
			field: issue.path.join("."),
		}));
		reply.status(400).send({ errors } satisfies ErrorResponse);
		return;
	}

	// Fastify validation errors (from Zod type provider)
	const fastifyErr = error as FastifyError;
	if (fastifyErr.statusCode === 400 && fastifyErr.code === "FST_ERR_VALIDATION") {
		const validation = (fastifyErr as unknown as { validation?: Array<{ instancePath: string; message: string }> }).validation ?? [];
		const errors = validation.map((v) => ({
			code: "VALIDATION_ERROR",
			message: v.message,
			field: v.instancePath.replace(/^\//, ""),
		}));
		reply.status(400).send({
			errors: errors.length > 0 ? errors : [{ code: "VALIDATION_ERROR", message: fastifyErr.message }],
		} satisfies ErrorResponse);
		return;
	}

	// Unknown error — log internally, never leak to client
	_request.log.error({ err: error, stack: (error as Error).stack, message: (error as Error).message }, "Unhandled error — FULL DETAILS");
	reply.status(500).send({
		errors: [
			{ code: "INTERNAL_ERROR", message: "An unexpected error occurred" },
		],
	} satisfies ErrorResponse);
}
