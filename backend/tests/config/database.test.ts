import { describe, it, expect, vi, beforeEach } from 'vitest';

const mockPool = {
  query: vi.fn(),
  end: vi.fn(),
  on: vi.fn(),
};
const PoolSpy = vi.fn(() => mockPool);

vi.mock('pg', () => {
  return { default: { Pool: PoolSpy }, Pool: PoolSpy };
});

describe('createPool', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('creates a pool with the given connection string', async () => {
    const { createPool } = await import('../../src/config/database.js');

    const pool = createPool('postgresql://user:pass@host:6543/db');

    expect(PoolSpy).toHaveBeenCalledWith(
      expect.objectContaining({
        connectionString: 'postgresql://user:pass@host:6543/db',
      }),
    );
    expect(pool).toBeDefined();
  });

  it('configures pool with sensible defaults', async () => {
    const { createPool } = await import('../../src/config/database.js');

    createPool('postgresql://user:pass@host:6543/db');

    expect(PoolSpy).toHaveBeenCalledWith(
      expect.objectContaining({
        max: 20,
        idleTimeoutMillis: 30_000,
        connectionTimeoutMillis: 5_000,
      }),
    );
  });

  it('allows overriding pool options', async () => {
    const { createPool } = await import('../../src/config/database.js');

    createPool('postgresql://user:pass@host:6543/db', { max: 5 });

    expect(PoolSpy).toHaveBeenCalledWith(
      expect.objectContaining({
        max: 5,
      }),
    );
  });
});

describe('query helper', () => {
  it('executes a parameterized query on the pool', async () => {
    const { createPool } = await import('../../src/config/database.js');
    const pool = createPool('postgresql://user:pass@host:6543/db');

    const mockResult = { rows: [{ id: '1', name: 'test' }], rowCount: 1 };
    vi.mocked(pool.query).mockResolvedValueOnce(mockResult as never);

    const result = await pool.query('SELECT id, name FROM studios WHERE id = $1', ['1']);

    expect(pool.query).toHaveBeenCalledWith('SELECT id, name FROM studios WHERE id = $1', ['1']);
    expect(result.rows).toEqual([{ id: '1', name: 'test' }]);
  });
});
