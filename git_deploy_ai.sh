#!/bin/bash

set -e

echo "🚀 開始部署 Elsa Workers AI + Telegram 整合..."

# 讀取環境變數
echo "🔧 使用參數如下："
echo "WORKERS_ENDPOINT = $WORKERS_ENDPOINT"
echo "WORKERS_KV_NAMESPACE = $WORKERS_KV_NAMESPACE"
echo "TELEGRAM_BOT_TOKEN = $TELEGRAM_BOT_TOKEN"
echo "TELEGRAM_CHAT_ID = $TELEGRAM_CHAT_ID"
echo "GIT_REPO_URL = $GIT_REPO_URL"
echo

# 建立必要檔案（範例 main.js）
cat > main.js << 'EOL'
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

# 初始化 git 並推送
git init
git remote add origin "$GIT_REPO_URL" 2>/dev/null || echo "✅ Git 已設定"
git add .
git commit -m "🌟 部署 Workers AI + Telegram Bot"
git branch -M main
git push -u origin main

echo "✅ Git 推送完成"

# Wrangler 部署
wrangler publish

echo
echo "✅ 部署完成！前往網址：$WORKERS_ENDPOINT/chat"
