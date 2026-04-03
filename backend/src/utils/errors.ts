export class AppError extends Error {
	readonly code: string;
	readonly statusCode: number;
	readonly field?: string;

	constructor(
		code: string,
		message: string,
		statusCode: number,
		field?: string,
	) {
		super(message);
		this.name = "AppError";
		this.code = code;
		this.statusCode = statusCode;
		this.field = field;
	}
}

export class NotFoundError extends AppError {
	constructor(message = "Resource not found") {
		super("RESOURCE_NOT_FOUND", message, 404);
	}
}

export class ConflictError extends AppError {
	constructor(code: string, message: string, field?: string) {
		super(code, message, 409, field);
	}
}

export class ValidationError extends AppError {
	constructor(message: string, field?: string) {
		super("VALIDATION_ERROR", message, 400, field);
	}
}

export class UnauthorizedError extends AppError {
	constructor(message = "Authentication required") {
		super("UNAUTHORIZED", message, 401);
	}
}

export class ForbiddenError extends AppError {
	constructor(message = "Insufficient permissions") {
		super("FORBIDDEN", message, 403);
	}
}
