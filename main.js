export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    if (request.method === "POST" && url.pathname === "/chat") {
      try {
        const { prompt } = await request.json();
        const aiRes = await fetch("https://api.cloudflare.com/client/v4/accounts/YOUR_ACCOUNT_ID/ai/run/@cf/meta/llama-2-7b-chat-fp16", {
          method: "POST",
          headers: {
            Authorization: `Bearer ${env.AI_API_KEY}`,
            "Content-Type": "application/json"
          },
          body: JSON.stringify({ messages: [{ role: "user", content: prompt }] })
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
