// CursorRepel.metal
// MacOS-Dino – Fare İmleci Etkileşim Shader'ı
// Parçacıklar fare imlecini takip eder / kaçar

#include <metal_stdlib>
using namespace metal;

struct ShaderUniforms {
    float  time;
    float2 resolution;
    float2 mousePosition;
    float  audioLevel;
    float4 audioSpectrum;
    float  customParam1;
    float  customParam2;
    float  customParam3;
    float  customParam4;
};

struct VertexOut {
    float4 position [[position]];
    float2 uv;
};

// Hash fonksiyonu – pseudo-random
float hash21(float2 p) {
    p = fract(p * float2(234.34, 435.345));
    p += dot(p, p + 34.23);
    return fract(p.x * p.y);
}

// --- Cursor Repel Shader ---
fragment float4 fragment_cursorRepel(VertexOut in [[stage_in]],
                                      constant ShaderUniforms &u [[buffer(0)]]) {
    float2 uv = in.uv;
    float2 mouse = u.mousePosition;
    float t = u.time;

    // Arka plan – koyu gradient
    float3 bg = mix(
        float3(0.01, 0.02, 0.06),
        float3(0.04, 0.02, 0.08),
        uv.y
    );

    float3 color = bg;

    // Parçacık sistemi
    float particleCount = 80.0;
    float influence = u.customParam1 > 0 ? u.customParam1 : 0.15; // Fare etki yarıçapı

    for (float i = 0.0; i < particleCount; i += 1.0) {
        // Her parçacık için benzersiz pozisyon
        float2 seed = float2(i * 0.73, i * 1.47);
        float2 basePos = float2(
            hash21(seed),
            hash21(seed + 100.0)
        );

        // Yavaş hareket
        float2 particlePos = basePos + float2(
            sin(t * 0.3 + i) * 0.05,
            cos(t * 0.2 + i * 0.7) * 0.05
        );

        // Fare etkileşimi – uzaklaştırma kuvveti
        float2 toMouse = particlePos - mouse;
        float distToMouse = length(toMouse);
        if (distToMouse < influence && distToMouse > 0.001) {
            float repelStrength = (influence - distToMouse) / influence;
            repelStrength = repelStrength * repelStrength * 0.3;
            particlePos += normalize(toMouse) * repelStrength;
        }

        // Piksel ile parçacık arası mesafe
        float dist = length(uv - particlePos);

        // Parçacık boyutu (rastgele)
        float size = 0.002 + hash21(seed + 200.0) * 0.004;

        // Parlaklık
        float brightness = smoothstep(size, size * 0.3, dist);

        // Renk: yakınsa sıcak, uzaksa soğuk
        float hue = hash21(seed + 300.0);
        float3 particleColor = mix(
            float3(0.3, 0.6, 1.0),  // Mavi
            float3(0.9, 0.4, 0.7),  // Pembe
            hue
        );

        // Fareye yakın parçacıklar daha parlak
        float mouseGlow = 1.0 + smoothstep(influence, 0.0, distToMouse) * 2.0;

        color += particleColor * brightness * mouseGlow;
    }

    // Fare çevresinde hafif ışık
    float mouseDist = length(uv - mouse);
    float mouseHalo = exp(-mouseDist * mouseDist * 20.0) * 0.08;
    color += float3(0.5, 0.3, 0.8) * mouseHalo;

    return float4(color, 1.0);
}
