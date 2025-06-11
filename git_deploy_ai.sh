#!/bin/bash
set -e

echo "🚀 Elsa AI 全配部署開始..."

# 建立主程式 main.js
cat > main.js << 'EOL'
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
EOL

# 建立 wrangler.toml
cat > wrangler.toml << EOL
name = "elsa-ai"
main = "main.js"
compatibility_date = "2024-11-11"

[vars]
TELEGRAM_BOT_TOKEN = "$TELEGRAM_BOT_TOKEN"
TELEGRAM_CHAT_ID = "$TELEGRAM_CHAT_ID"

kv_namespaces = [
  { binding = "MEMORY_KV", id = "$WORKERS_KV_NAMESPACE" }
]
EOL

# 初始化 Git 並推送
git init
git remote add origin "$GIT_REPO_URL" 2>/dev/null || true
git add .
git commit -m "🚀 Elsa AI 全配部署"
git branch -M main
git push -u origin main

# 發布到 Cloudflare
wrangler publish

echo "🎉 全配部署完成！"
echo "🔗 API 接點：$WORKERS_ENDPOINT/chat"
echo "📨 回覆也會自動發送至 Telegram！"
