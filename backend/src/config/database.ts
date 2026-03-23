import pg from 'pg';

const { Pool } = pg;

export type PoolOptions = {
  max?: number;
  idleTimeoutMillis?: number;
  connectionTimeoutMillis?: number;
};

export function createPool(connectionString: string, options?: PoolOptions): pg.Pool {
  return new Pool({
    connectionString,
    max: options?.max ?? 20,
    idleTimeoutMillis: options?.idleTimeoutMillis ?? 30_000,
    connectionTimeoutMillis: options?.connectionTimeoutMillis ?? 5_000,
  });
}
