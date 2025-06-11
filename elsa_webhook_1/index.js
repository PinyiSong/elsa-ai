export default {
  async fetch(request, env, ctx) {
    return new Response("🧠 Elsa AI Webhook Online", {
      headers: { "Content-Type": "text/plain" },
    });
  }
};
