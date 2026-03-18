// MacOS-Dino – Supabase Edge Function: live-preview-websocket
// Wallpaper canlı önizleme WebSocket sunucusu
// Deno runtime

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

// Aktif preview oturumları
const activeSessions = new Map<string, WebSocket>();

serve(async (req: Request) => {
  // CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  // WebSocket upgrade
  const { socket, response } = Deno.upgradeWebSocket(req);
  const sessionId = crypto.randomUUID();

  socket.onopen = () => {
    console.log(`🔌 Preview oturumu açıldı: ${sessionId}`);
    activeSessions.set(sessionId, socket);

    socket.send(
      JSON.stringify({
        type: "connected",
        sessionId,
        message: "MacOS-Dino Live Preview bağlantısı kuruldu",
      })
    );
  };

  socket.onmessage = (event) => {
    try {
      const data = JSON.parse(event.data);

      switch (data.type) {
        case "preview_request":
          // Wallpaper önizleme isteği
          socket.send(
            JSON.stringify({
              type: "preview_ready",
              wallpaperId: data.wallpaperId,
              previewUrl: data.previewUrl,
              quality: data.quality || "medium",
            })
          );
          break;

        case "shader_params_update":
          // Shader parametreleri canlı güncelleme
          socket.send(
            JSON.stringify({
              type: "shader_update",
              shaderName: data.shaderName,
              parameters: data.parameters,
            })
          );
          break;

        case "ping":
          socket.send(JSON.stringify({ type: "pong" }));
          break;

        default:
          console.log(`Bilinmeyen mesaj tipi: ${data.type}`);
      }
    } catch (error) {
      console.error(`Mesaj işleme hatası: ${error.message}`);
    }
  };

  socket.onclose = () => {
    console.log(`🔌 Preview oturumu kapandı: ${sessionId}`);
    activeSessions.delete(sessionId);
  };

  socket.onerror = (error) => {
    console.error(`WebSocket hatası [${sessionId}]:`, error);
    activeSessions.delete(sessionId);
  };

  return response;
});
