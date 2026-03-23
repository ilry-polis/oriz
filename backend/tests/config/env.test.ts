import { describe, it, expect, beforeEach, afterEach } from 'vitest';

describe('parseEnv', () => {
  const validEnv = {
    DATABASE_URL: 'postgresql://user:pass@host:5432/db',
    SUPABASE_URL: 'https://project.supabase.co',
    SUPABASE_ANON_KEY: 'anon-key-value',
    SUPABASE_SERVICE_ROLE: 'service-role-value',
    SUPABASE_JWT_SECRET: 'super-secret-jwt-key-at-least-32-chars-long',
    PORT: '3000',
    NODE_ENV: 'development',
  };

  let originalEnv: NodeJS.ProcessEnv;

  beforeEach(() => {
    originalEnv = { ...process.env };
    // Clear all relevant env vars
    for (const key of Object.keys(validEnv)) {
      delete process.env[key];
    }
  });

  afterEach(() => {
    process.env = originalEnv;
  });

  it('parses valid environment variables', async () => {
    Object.assign(process.env, validEnv);
    const { parseEnv } = await import('../../src/config/env.js');
    const env = parseEnv();

    expect(env.DATABASE_URL).toBe(validEnv.DATABASE_URL);
    expect(env.SUPABASE_URL).toBe(validEnv.SUPABASE_URL);
    expect(env.PORT).toBe(3000); // number, not string
    expect(env.NODE_ENV).toBe('development');
  });

  it('throws on missing DATABASE_URL', async () => {
    const { DATABASE_URL: _, ...partial } = validEnv;
    Object.assign(process.env, partial);
    const { parseEnv } = await import('../../src/config/env.js');

    expect(() => parseEnv()).toThrow();
  });

  it('throws on missing SUPABASE_JWT_SECRET', async () => {
    const { SUPABASE_JWT_SECRET: _, ...partial } = validEnv;
    Object.assign(process.env, partial);
    const { parseEnv } = await import('../../src/config/env.js');

    expect(() => parseEnv()).toThrow();
  });

  it('defaults PORT to 3000 when not set', async () => {
    const { PORT: _, ...partial } = validEnv;
    Object.assign(process.env, partial);
    const { parseEnv } = await import('../../src/config/env.js');
    const env = parseEnv();

    expect(env.PORT).toBe(3000);
  });

  it('defaults NODE_ENV to development when not set', async () => {
    const { NODE_ENV: _, ...partial } = validEnv;
    Object.assign(process.env, partial);
    const { parseEnv } = await import('../../src/config/env.js');
    const env = parseEnv();

    expect(env.NODE_ENV).toBe('development');
  });

  it('rejects invalid NODE_ENV value', async () => {
    Object.assign(process.env, { ...validEnv, NODE_ENV: 'invalid' });
    const { parseEnv } = await import('../../src/config/env.js');

    expect(() => parseEnv()).toThrow();
  });

  it('coerces PORT string to number', async () => {
    Object.assign(process.env, { ...validEnv, PORT: '8080' });
    const { parseEnv } = await import('../../src/config/env.js');
    const env = parseEnv();

    expect(env.PORT).toBe(8080);
    expect(typeof env.PORT).toBe('number');
  });
});
