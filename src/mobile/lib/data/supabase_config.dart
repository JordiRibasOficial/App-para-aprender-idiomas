/// Supabase project URL and publishable (anon) key — safe to ship in the
/// compiled app, same as [AdUnitIds]: the publishable key identifies the
/// project, it doesn't grant privileged access. Every table it can reach is
/// behind Row Level Security (see src/backend/supabase/migrations); the
/// service role key that bypasses RLS lives only in the Edge Function's
/// server-side environment, never in this app.
class SupabaseConfig {
  const SupabaseConfig._();

  static const url = 'https://nfkhnrwyekqbjxwxmctu.supabase.co';
  static const publishableKey =
      'sb_publishable_ecySXGpLbxhpmaWRSYCT1A_ejg38nFT';
}
