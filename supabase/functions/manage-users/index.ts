// manage-users — HopAlong admin Edge Function.
//
// Admin-managed password login (replaces Twilio phone OTP):
//   - an admin creates users with a mobile number + temporary password
//   - the user must pick their own password at first sign-in
//   - an admin can reset a password or make/remove another admin
//
// The service-role key never leaves the server: this function is the only
// place that can create auth users or write the admins table.
//
// Auth: the caller passes their Supabase JWT (Authorization: Bearer ...).
// Every action except the bootstrap requires the caller to already be an
// admin. Bootstrap: when the admins table is still empty, the caller may
// promote THEMSELVES only — that is how the first admin (Sree) is made.
//
// Login emails are synthetic: <digits>@hopalong.app (digits = the Indian
// mobile with country code, e.g. 919876543210@hopalong.app). The app builds
// the same address from the number the user types. No real email is ever
// sent; "forgot password" is an admin reset, not a self-service email.
//
// Deploy (on your machine, from the repo root):
//   supabase link --project-ref tuioalyrubqkgwsbfiqg
//   supabase functions deploy manage-users
// No secrets to set: SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are
// injected into Edge Functions automatically.

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const LOGIN_DOMAIN = 'hopalong.app';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
};

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

function digitsOnly(phone: string): string {
  const d = phone.replace(/\D/g, '');
  if (d.length === 10) return `91${d}`;
  if (d.length === 12 && d.startsWith('91')) return d;
  if (d.length === 11 && d.startsWith('0')) return `91${d.slice(1)}`;
  return d;
}

function loginEmail(phone: string): string {
  return `${digitsOnly(phone)}@${LOGIN_DOMAIN}`;
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  const supabase = createClient(SUPABASE_URL, SERVICE_KEY, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  let payload: Record<string, unknown>;
  try {
    payload = await req.json();
  } catch {
    return json({ error: 'Invalid JSON body.' }, 400);
  }
  const action = payload.action as string | undefined;

  // Who is calling? The JWT is verified against Auth, not trusted blind.
  const token = req.headers
    .get('Authorization')
    ?.replace(/^Bearer\s+/i, '');
  if (!token) return json({ error: 'Not signed in.' }, 401);
  const { data: { user }, error: userError } =
    await supabase.auth.getUser(token);
  if (userError || !user) {
    return json({ error: 'Not signed in.' }, 401);
  }

  const { data: adminRows } = await supabase
    .from('admins')
    .select('user_id');
  const adminIds = new Set((adminRows ?? []).map((r) => r.user_id as string));
  const isAdmin = adminIds.has(user.id);

  // Bootstrap: with no admins yet, the caller may promote themselves
  // (and set their own password). Nobody else can be promoted this way.
  if (action === 'bootstrap') {
    if (adminIds.size > 0) {
      return json({ error: 'An admin already exists.' }, 403);
    }
    const password = payload.password as string | undefined;
    if (!password || password.length < 6) {
      return json({ error: 'Password must be at least 6 characters.' }, 400);
    }
    const { error: insertError } = await supabase
      .from('admins')
      .insert({ user_id: user.id });
    if (insertError) return json({ error: insertError.message }, 400);
    const { error: pwError } = await supabase.auth.admin.updateUserById(
      user.id,
      { password },
    );
    if (pwError) return json({ error: pwError.message }, 400);
    await supabase
      .from('profiles')
      .update({ must_reset_password: false })
      .eq('id', user.id);
    return json({ ok: true, isAdmin: true });
  }

  // Every other action needs an existing admin.
  if (!isAdmin) return json({ error: 'Admin only.' }, 403);

  if (action === 'create-user') {
    const name = (payload.name as string | undefined)?.trim();
    const phone = (payload.phone as string | undefined)?.trim();
    const password = payload.password as string | undefined;
    if (!name) return json({ error: 'Name is required.' }, 400);
    if (!phone || digitsOnly(phone).length !== 12) {
      return json({ error: 'Enter a valid 10-digit mobile number.' }, 400);
    }
    if (!password || password.length < 6) {
      return json({ error: 'Password must be at least 6 characters.' }, 400);
    }
    const { data: created, error: createError } =
      await supabase.auth.admin.createUser({
        email: loginEmail(phone),
        password,
        email_confirm: true,
        user_metadata: { phone: digitsOnly(phone), full_name: name },
      });
    if (createError || !created.user) {
      return json(
        { error: createError?.message ?? 'Could not create the user.' },
        400,
      );
    }
    const { error: profileError } = await supabase.from('profiles').insert({
      id: created.user.id,
      full_name: name,
      dob: null,
      gender: 'Prefer not to say',
      phone: digitsOnly(phone),
      email: null,
      avatar_url: '',
      mode: 'member',
      completed_rides: 0,
      must_reset_password: true,
    });
    if (profileError) {
      // The auth user exists but the profile did not — report it plainly
      // so the admin retries instead of leaving a half-made account.
      return json({ error: profileError.message }, 400);
    }
    return json({ ok: true, userId: created.user.id });
  }

  if (action === 'set-password') {
    const userId = payload.userId as string | undefined;
    const password = payload.password as string | undefined;
    if (!userId) return json({ error: 'User is required.' }, 400);
    if (!password || password.length < 6) {
      return json({ error: 'Password must be at least 6 characters.' }, 400);
    }
    const { error: pwError } = await supabase.auth.admin.updateUserById(
      userId,
      { password },
    );
    if (pwError) return json({ error: pwError.message }, 400);
    await supabase
      .from('profiles')
      .update({ must_reset_password: true })
      .eq('id', userId);
    return json({ ok: true });
  }

  if (action === 'set-admin') {
    const userId = payload.userId as string | undefined;
    const makeAdmin = payload.makeAdmin === true;
    if (!userId) return json({ error: 'User is required.' }, 400);
    if (userId === user.id && !makeAdmin) {
      return json({ error: 'You cannot remove your own admin access.' }, 400);
    }
    if (makeAdmin) {
      const { error } = await supabase
        .from('admins')
        .upsert({ user_id: userId });
      if (error) return json({ error: error.message }, 400);
    } else {
      const { error } = await supabase
        .from('admins')
        .delete()
        .eq('user_id', userId);
      if (error) return json({ error: error.message }, 400);
    }
    return json({ ok: true });
  }

  return json({ error: `Unknown action: ${action ?? ''}` }, 400);
});
