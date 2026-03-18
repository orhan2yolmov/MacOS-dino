// MacOS-Dino – Supabase Edge Function: generate-aerial-format
// Video dosyasını Apple Aerial formatına dönüştürme
// Deno runtime

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req: Request) => {
  // CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    const { videoPath, targetFormat } = await req.json();

    if (!videoPath) {
      return new Response(
        JSON.stringify({ error: "videoPath gereklidir" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Video bilgisini al
    const { data: videoData, error: downloadError } = await supabase.storage
      .from("wallpaper-videos")
      .download(videoPath);

    if (downloadError) {
      throw new Error(`Video indirme hatası: ${downloadError.message}`);
    }

    // Apple Aerial format metadata
    const aerialMetadata = {
      format: targetFormat || "aerial-hevc",
      compatibility: "macOS-14+",
      codec: "HEVC",
      colorSpace: "P3-D65",
      hdr: false,
      loopable: true,
      categories: ["MacOS-Dino"],
      processedAt: new Date().toISOString(),
      sourceVideo: videoPath,
      // Aerial assets metadata format
      assets: [
        {
          accessibilityLabel: videoPath.split("/").pop()?.replace(".mp4", ""),
          id: crypto.randomUUID(),
          type: "video",
          url: `wallpaper-videos/${videoPath}`,
        },
      ],
    };

    // Metadata'yı storage'a kaydet
    const metadataPath = videoPath.replace(/\.[^.]+$/, ".aerial.json");
    const { error: uploadError } = await supabase.storage
      .from("wallpaper-videos")
      .upload(
        metadataPath,
        new Blob([JSON.stringify(aerialMetadata, null, 2)], {
          type: "application/json",
        }),
        { upsert: true }
      );

    if (uploadError) {
      throw new Error(`Metadata kaydetme hatası: ${uploadError.message}`);
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: "Aerial format metadata oluşturuldu",
        metadataPath,
        metadata: aerialMetadata,
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
