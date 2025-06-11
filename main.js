export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    if (url.pathname === "/chat" && request.method === "POST") {
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

        // 同時推送至 Telegram
        await fetch("https://api.telegram.org/bot" + env.TELEGRAM_BOT_TOKEN + "/sendMessage", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            chat_id: env.TELEGRAM_CHAT_ID,
            text: "🤖 Elsa 回覆：\n\n" + reply
          })
        });

        return new Response(JSON.stringify({ reply }), {
          headers: { "Content-Type": "application/json" }
        });
      } catch (err) {
        return new Response(JSON.stringify({ reply: "❌ AI 回覆失敗" }), {
          headers: { "Content-Type": "application/json" }
        });
      }
    }

    return new Response("Elsa Workers Online", { status: 200 });
  }
}
