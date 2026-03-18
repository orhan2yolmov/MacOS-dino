// AudioReactive.metal
// MacOS-Dino – Ses Reaktif Shader
// Mikrofon/sistem sesini analiz edip görsel dalga oluşturur

#include <metal_stdlib>
using namespace metal;

struct ShaderUniforms {
    float  time;
    float2 resolution;
    float2 mousePosition;
    float  audioLevel;
    float4 audioSpectrum; // bass, mid, high, peak
    float  customParam1;
    float  customParam2;
    float  customParam3;
    float  customParam4;
};

struct VertexOut {
    float4 position [[position]];
    float2 uv;
};

// --- Audio Reactive Shader ---
fragment float4 fragment_audioReactive(VertexOut in [[stage_in]],
                                        constant ShaderUniforms &u [[buffer(0)]]) {
    float2 uv = in.uv;
    float t = u.time;

    float bass = u.audioSpectrum.x;
    float mid = u.audioSpectrum.y;
    float high = u.audioSpectrum.z;
    float peak = u.audioSpectrum.w;
    float level = u.audioLevel;

    // Merkez referans
    float2 center = float2(0.5, 0.5);
    float2 fromCenter = uv - center;
    float dist = length(fromCenter);
    float angle = atan2(fromCenter.y, fromCenter.x);

    // Arka plan – sese göre nabız atan koyu renk
    float3 bg = float3(0.02, 0.01, 0.04) + float3(0.02, 0.01, 0.03) * bass;

    float3 color = bg;

    // Merkezdeki dairesel dalga – bass'a tepki
    float ringCount = 5.0;
    for (float i = 0.0; i < ringCount; i += 1.0) {
        float radius = 0.1 + i * 0.08 + bass * 0.05 * (i + 1.0);
        float wave = sin(angle * (3.0 + i * 2.0) + t * (1.0 + i * 0.5)) * 0.02 * mid;
        float ring = smoothstep(0.005, 0.0, abs(dist - radius + wave));

        float3 ringColor = mix(
            float3(0.2, 0.5, 1.0),  // Mavi
            float3(1.0, 0.3, 0.5),  // Kırmızı
            i / ringCount
        );
        ringColor *= (1.0 + peak * 2.0);

        color += ringColor * ring * 0.6;
    }

    // Dikey ses çubukları (equalizer tarzı)
    float barCount = 32.0;
    float barWidth = 1.0 / barCount;

    float barIndex = floor(uv.x * barCount);
    float barCenter = (barIndex + 0.5) / barCount;
    float barDist = abs(uv.x - barCenter);

    // Her çubuk için farklı ses frekansı
    float freq = barIndex / barCount;
    float barHeight;
    if (freq < 0.33) {
        barHeight = bass * 0.3;
    } else if (freq < 0.66) {
        barHeight = mid * 0.25;
    } else {
        barHeight = high * 0.2;
    }

    // Animasyonlu yükseklik
    barHeight *= (0.5 + 0.5 * sin(t * 2.0 + barIndex * 0.5));
    barHeight = max(barHeight, 0.01); // Minimum yükseklik

    float bar = step(barDist, barWidth * 0.35) * step(1.0 - uv.y, barHeight + 0.5);
    float barFade = smoothstep(0.5, 0.5 + barHeight, uv.y);

    float3 barColor = mix(
        float3(0.0, 1.0, 0.5),  // Yeşil (düşük)
        float3(1.0, 0.2, 0.1),  // Kırmızı (yüksek)
        uv.y
    );
    color += barColor * bar * barFade * 0.4;

    // Global ışıma – peak'te parlama
    float glow = exp(-dist * dist * 8.0) * peak * 0.3;
    color += float3(0.6, 0.3, 0.9) * glow;

    // Vignette
    float vignette = 1.0 - smoothstep(0.3, 0.8, dist);
    color *= vignette;

    return float4(color, 1.0);
}
