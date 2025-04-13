// Supabase Edge Function
import { serve } from "https://deno.land/std/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js";

serve(async (req) => {
  const { email, password, phone } = await req.json();

  const supabase = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);

  // Authentifier l'utilisateur
  const { data: session, error: loginError } = await supabase.auth.signInWithPassword({ email, password });

  if (loginError || !session.user) {
    return new Response(JSON.stringify({ error: { message: "Identifiants invalides" } }), { status: 401 });
  }

  const user = session.user;

  // Générer un token
  const token = crypto.randomUUID();
  await supabase.from('delete_tokens').insert({
    user_id: user.id,
    token,
    expires_at: new Date(Date.now() + 1000 * 60 * 30) // 30 min
  });

  // Envoyer l'e-mail (à adapter avec votre service d'envoi)
  const deleteUrl = `https://votresite.com/confirm-delete?token=${token}`;
  await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${Deno.env.get("RESEND_API_KEY")}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      from: "Mon App <noreply@votresite.com>",
      to: email,
      subject: "Confirmation de suppression de compte",
      html: `Cliquez ici pour supprimer votre compte : <a href="${deleteUrl}">${deleteUrl}</a>`,
    }),
  });

  return new Response(JSON.stringify({ success: true }));
});
