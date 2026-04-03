import { describe, it, expect, vi } from 'vitest';

const mockClient = { from: vi.fn(), auth: { admin: {} } };

vi.mock('@supabase/supabase-js', () => ({
  createClient: vi.fn(() => mockClient),
}));

describe('createSupabaseAdmin', () => {
  it('creates a client with service role key and auth admin disabled', async () => {
    const { createClient } = await import('@supabase/supabase-js');
    const { createSupabaseAdmin } = await import('../../src/config/supabase.js');

    const client = createSupabaseAdmin('https://project.supabase.co', 'service-role-key');

    expect(createClient).toHaveBeenCalledWith(
      'https://project.supabase.co',
      'service-role-key',
      expect.objectContaining({
        auth: expect.objectContaining({
          autoRefreshToken: false,
          persistSession: false,
        }),
      }),
    );
    expect(client).toBe(mockClient);
  });
});
