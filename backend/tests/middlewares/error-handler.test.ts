import { describe, it, expect, vi } from 'vitest';
import { ZodError, z } from 'zod';
import { AppError, NotFoundError, ValidationError, ConflictError } from '../../src/utils/errors.js';
import { errorHandler } from '../../src/middlewares/error-handler.js';

function createMockReply() {
  const reply: Record<string, unknown> = {};
  reply.status = vi.fn(() => reply);
  reply.send = vi.fn(() => reply);
  return reply as { status: ReturnType<typeof vi.fn>; send: ReturnType<typeof vi.fn> };
}

describe('errorHandler', () => {
  it('handles AppError with correct status and shape', () => {
    const error = new NotFoundError('Studio not found');
    const reply = createMockReply();

    errorHandler(error, {} as never, reply as never);

    expect(reply.status).toHaveBeenCalledWith(404);
    expect(reply.send).toHaveBeenCalledWith({
      errors: [{ code: 'RESOURCE_NOT_FOUND', message: 'Studio not found' }],
    });
  });

  it('includes field when present on AppError', () => {
    const error = new ConflictError('SLUG_TAKEN', 'Slug already in use', 'slug');
    const reply = createMockReply();

    errorHandler(error, {} as never, reply as never);

    expect(reply.status).toHaveBeenCalledWith(409);
    expect(reply.send).toHaveBeenCalledWith({
      errors: [{ code: 'SLUG_TAKEN', message: 'Slug already in use', field: 'slug' }],
    });
  });

  it('handles ZodError as 400 with field-level errors', () => {
    const schema = z.object({ email: z.string().email(), name: z.string().min(1) });
    let zodError: ZodError;
    try {
      schema.parse({ email: 'bad', name: '' });
    } catch (e) {
      zodError = e as ZodError;
    }
    const reply = createMockReply();

    errorHandler(zodError!, {} as never, reply as never);

    expect(reply.status).toHaveBeenCalledWith(400);
    const body = reply.send.mock.calls[0]![0] as { errors: Array<{ code: string; field: string }> };
    expect(body.errors.length).toBeGreaterThanOrEqual(2);
    expect(body.errors.every((e) => e.code === 'VALIDATION_ERROR')).toBe(true);
    expect(body.errors.some((e) => e.field === 'email')).toBe(true);
    expect(body.errors.some((e) => e.field === 'name')).toBe(true);
  });

  it('handles unknown errors as 500 without leaking stack trace', () => {
    const error = new Error('Something broke internally');
    const reply = createMockReply();

    errorHandler(error, {} as never, reply as never);

    expect(reply.status).toHaveBeenCalledWith(500);
    const body = reply.send.mock.calls[0]![0] as { errors: Array<{ code: string; message: string }> };
    expect(body.errors[0]!.code).toBe('INTERNAL_ERROR');
    expect(body.errors[0]!.message).not.toContain('Something broke internally');
  });

  it('handles ValidationError with correct shape', () => {
    const error = new ValidationError('Invalid phone format', 'phone');
    const reply = createMockReply();

    errorHandler(error, {} as never, reply as never);

    expect(reply.status).toHaveBeenCalledWith(400);
    expect(reply.send).toHaveBeenCalledWith({
      errors: [{ code: 'VALIDATION_ERROR', message: 'Invalid phone format', field: 'phone' }],
    });
  });
});
