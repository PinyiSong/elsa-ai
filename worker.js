export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const { pathname } = url;

    if (pathname === "/api/chat") {
      const { message } = await request.json();

      await env.ELSA_MEMORY.put(`log-${Date.now()}`, message);

      try {
        const aiRes = await fetch("https://api.cloudflare.com/client/v4/accounts/33dd3105308ff58fb0eb04d51ceda03d/ai/run/@cf/meta/llama-3-8b-instruct", {
          method: "POST",
          headers: {
            "Authorization": "Bearer 3ZQ28qr0RJ_RcZNCGD_KNOLL-NY_uF7JTUUK4Tfq",
            "Content-Type": "application/json"
          },
          body: JSON.stringify({
            prompt: message,
            max_tokens: 300
          })
        });

        const aiJson = await aiRes.json();
        const reply = aiJson.result?.response || "⚠️ Workers AI 無回應";

        return new Response(JSON.stringify({ reply }), {
          headers: { "Content-Type": "application/json" }
        });
      } catch {
        return new Response(JSON.stringify({ reply: "❌ AI 回覆失敗" }), {
          headers: { "Content-Type": "application/json" }
        });
      }
    }

    return new Response("404 Not Found", { status: 404 });
  }
}
