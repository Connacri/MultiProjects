serve(async (req) => {
  const { searchParams } = new URL(req.url);
  const token = searchParams.get("token");

  const supabase = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);

  // Vérifier le token
  const { data: tokenData } = await supabase.from('delete_tokens').select('*').eq('token', token).single();

  if (!tokenData || new Date(tokenData.expires_at) < new Date()) {
    return new Response("Lien expiré ou invalide", { status: 400 });
  }

  const userId = tokenData.user_id;

  // Supprimer les données
  await supabase.from('users').delete().eq('id', userId); // Remplacer par vos tables
  await supabase.auth.admin.deleteUser(userId);
  await supabase.from('delete_tokens').delete().eq('token', token);

  return new Response("Votre compte a été supprimé.", { status: 200 });
});
