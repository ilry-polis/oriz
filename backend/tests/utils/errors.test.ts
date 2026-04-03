import { describe, it, expect } from 'vitest';
import {
  AppError,
  NotFoundError,
  ConflictError,
  ValidationError,
  UnauthorizedError,
  ForbiddenError,
} from '../../src/utils/errors.js';

describe('AppError', () => {
  it('stores code, statusCode, and message', () => {
    const err = new AppError('CUSTOM_ERROR', 'Something went wrong', 418);
    expect(err.code).toBe('CUSTOM_ERROR');
    expect(err.message).toBe('Something went wrong');
    expect(err.statusCode).toBe(418);
    expect(err).toBeInstanceOf(Error);
  });

  it('optionally stores field', () => {
    const err = new AppError('INVALID', 'Bad email', 400, 'email');
    expect(err.field).toBe('email');
  });
});

describe('NotFoundError', () => {
  it('defaults to 404 with RESOURCE_NOT_FOUND code', () => {
    const err = new NotFoundError('Studio not found');
    expect(err.statusCode).toBe(404);
    expect(err.code).toBe('RESOURCE_NOT_FOUND');
    expect(err.message).toBe('Studio not found');
  });
});

describe('ConflictError', () => {
  it('defaults to 409', () => {
    const err = new ConflictError('SLUG_TAKEN', 'Slug already in use', 'slug');
    expect(err.statusCode).toBe(409);
    expect(err.code).toBe('SLUG_TAKEN');
    expect(err.field).toBe('slug');
  });
});

describe('ValidationError', () => {
  it('defaults to 400 with VALIDATION_ERROR code', () => {
    const err = new ValidationError('Invalid email', 'email');
    expect(err.statusCode).toBe(400);
    expect(err.code).toBe('VALIDATION_ERROR');
    expect(err.field).toBe('email');
  });
});

describe('UnauthorizedError', () => {
  it('defaults to 401 with UNAUTHORIZED code', () => {
    const err = new UnauthorizedError();
    expect(err.statusCode).toBe(401);
    expect(err.code).toBe('UNAUTHORIZED');
  });

  it('accepts custom message', () => {
    const err = new UnauthorizedError('Token expired');
    expect(err.message).toBe('Token expired');
  });
});

describe('ForbiddenError', () => {
  it('defaults to 403 with FORBIDDEN code', () => {
    const err = new ForbiddenError();
    expect(err.statusCode).toBe(403);
    expect(err.code).toBe('FORBIDDEN');
  });
});
