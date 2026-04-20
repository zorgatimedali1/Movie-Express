import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

/**
 * Require a logged-in user. Uses the official Edge pattern: forward Authorization
 * into the client, then getUser() with no args (getUser(jwt) often fails on newer tokens).
 */
async function requireSignedInUser(req: Request): Promise<Response | null> {
  const auth = req.headers.get("Authorization");
  if (!auth?.startsWith("Bearer ")) {
    return new Response(JSON.stringify({ error: "Missing Authorization bearer token" }), {
      status: 401,
      headers: { ...cors, "Content-Type": "application/json" },
    });
  }
  const url = Deno.env.get("SUPABASE_URL") ?? "";
  const anon = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
  if (!url || !anon) {
    return new Response(JSON.stringify({ error: "Supabase env missing" }), {
      status: 500,
      headers: { ...cors, "Content-Type": "application/json" },
    });
  }
  const supabase = createClient(url, anon, {
    global: { headers: { Authorization: auth } },
  });
  const { data: { user }, error } = await supabase.auth.getUser();
  if (error || !user) {
    const msg =
      error?.message ??
      "Session invalide ou expirée — déconnecte-toi et reconnecte-toi dans l’app.";
    return new Response(JSON.stringify({ error: msg }), {
      status: 401,
      headers: { ...cors, "Content-Type": "application/json" },
    });
  }
  return null;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: cors });
  }

  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Use POST" }), {
      status: 405,
      headers: { ...cors, "Content-Type": "application/json" },
    });
  }

  const authDenied = await requireSignedInUser(req);
  if (authDenied) return authDenied;

  const key = Deno.env.get("ANTHROPIC_API_KEY");
  if (!key) {
    return new Response(
      JSON.stringify({ error: "ANTHROPIC_API_KEY is not set" }),
      {
        status: 500,
        headers: { ...cors, "Content-Type": "application/json" },
      },
    );
  }

  try {
    const body = (await req.json()) as {
      model?: string;
      max_tokens?: number;
      system?: string;
      messages?: unknown[];
    };

    const payload: Record<string, unknown> = {
      model: body.model ?? "claude-sonnet-4-20250514",
      max_tokens: body.max_tokens ?? 1024,
      messages: body.messages ?? [],
    };
    if (body.system != null && body.system !== "") {
      payload.system = body.system;
    }

    const res = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-api-key": key,
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify(payload),
    });

    const raw = await res.text();
    if (!res.ok) {
      return new Response(JSON.stringify({ error: raw }), {
        status: res.status,
        headers: { ...cors, "Content-Type": "application/json" },
      });
    }

    const data = JSON.parse(raw) as {
      content?: Array<{ type?: string; text?: string }>;
    };
    let text = "";
    if (Array.isArray(data.content)) {
      text = data.content
        .map((b) => (typeof b.text === "string" ? b.text : ""))
        .join("");
    }

    return new Response(JSON.stringify({ text }), {
      headers: { ...cors, "Content-Type": "application/json" },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500,
      headers: { ...cors, "Content-Type": "application/json" },
    });
  }
});
