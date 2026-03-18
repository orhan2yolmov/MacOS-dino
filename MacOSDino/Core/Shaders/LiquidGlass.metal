// LiquidGlass.metal
// MacOS-Dino – Liquid Glass Refraction Shader
// macOS Tahoe 26 Liquid Glass efekti simülasyonu

#include <metal_stdlib>
using namespace metal;

struct ShaderUniforms {
    float  time;
    float2 resolution;
    float2 mousePosition;
    float  audioLevel;
    float4 audioSpectrum;
    float  customParam1;  // refraction strength
    float  customParam2;  // blur amount
    float  customParam3;  // glass tint
    float  customParam4;  // edge glow
};

struct VertexOut {
    float4 position [[position]];
    float2 uv;
};

// Simplex noise 2D
float snoise(float2 v) {
    const float4 C = float4(0.211324865405187, 0.366025403784439,
                            -0.577350269189626, 0.024390243902439);
    float2 i = floor(v + dot(v, C.yy));
    float2 x0 = v - i + dot(i, C.xx);
    float2 i1 = (x0.x > x0.y) ? float2(1.0, 0.0) : float2(0.0, 1.0);
    float4 x12 = x0.xyxy + C.xxzz;
    x12.xy -= i1;

    i = fmod(i, 289.0);
    float3 p = fract(sin(float3(
        dot(i, float2(127.1, 311.7)),
        dot(i + i1, float2(127.1, 311.7)),
        dot(i + 1.0, float2(127.1, 311.7))
    )) * 43758.5453) * 2.0 - 1.0;

    float3 m = max(0.5 - float3(dot(x0, x0), dot(x12.xy, x12.xy), dot(x12.zw, x12.zw)), 0.0);
    m = m * m * m * m;

    float3 x_vals = float3(dot(p.x * float2(1, 0), x0), dot(p.y * float2(1, 0), x12.xy), dot(p.z * float2(1, 0), x12.zw));
    return 42.0 * dot(m, x_vals);
}

// --- Liquid Glass Shader ---
fragment float4 fragment_liquidGlass(VertexOut in [[stage_in]],
                                      constant ShaderUniforms &u [[buffer(0)]]) {
    float2 uv = in.uv;
    float t = u.time * 0.15;

    float refractionStrength = u.customParam1 > 0 ? u.customParam1 : 0.03;
    float glassTint = u.customParam3 > 0 ? u.customParam3 : 0.3;
    float edgeGlow = u.customParam4 > 0 ? u.customParam4 : 0.5;

    // Cam yüzey normal haritası – çoklu noise katmanı
    float n1 = snoise(uv * 3.0 + float2(t, t * 0.7)) * 0.5;
    float n2 = snoise(uv * 6.0 - float2(t * 0.5, t)) * 0.25;
    float n3 = snoise(uv * 12.0 + float2(t * 0.3, -t * 0.4)) * 0.125;
    float noise = n1 + n2 + n3;

    // Refraction offset
    float2 refractOffset = float2(
        snoise(uv * 4.0 + t),
        snoise(uv * 4.0 + t + 100.0)
    ) * refractionStrength;

    float2 refractedUV = uv + refractOffset;

    // Arka plan gradient (cam arkasındaki "sahne")
    float3 sceneLower = float3(0.05, 0.08, 0.18); // Koyu mavi
    float3 sceneUpper = float3(0.12, 0.06, 0.22); // Mor

    float3 scene = mix(sceneLower, sceneUpper, refractedUV.y);

    // Hafif ışık noktaları (bokeh etkisi)
    for (int i = 0; i < 8; i++) {
        float fi = float(i);
        float2 bokehPos = float2(
            fract(sin(fi * 127.1) * 43758.5453),
            fract(cos(fi * 311.7) * 43758.5453)
        );
        bokehPos += float2(sin(t + fi), cos(t * 0.7 + fi)) * 0.1;
        float bokeh = exp(-length(refractedUV - bokehPos) * 15.0);
        float3 bokehColor = float3(
            0.3 + 0.7 * fract(sin(fi * 23.1) * 100.0),
            0.3 + 0.7 * fract(cos(fi * 45.3) * 100.0),
            0.6 + 0.4 * fract(sin(fi * 67.5) * 100.0)
        );
        scene += bokehColor * bokeh * 0.15;
    }

    // Cam tint (hafif mavi-beyaz)
    float3 glassColor = float3(0.7, 0.8, 1.0);
    float3 tinted = mix(scene, glassColor, glassTint * 0.15);

    // Fresnel efekti – kenarlarda yansıma artışı
    float2 fromCenter = uv - 0.5;
    float edgeDist = length(fromCenter);
    float fresnel = pow(edgeDist * 1.5, 2.0);
    fresnel = clamp(fresnel, 0.0, 1.0);

    float3 reflectionColor = float3(0.6, 0.7, 0.9);
    tinted = mix(tinted, reflectionColor, fresnel * 0.3);

    // Kenar parlama (edge highlight)
    float edge = abs(noise) * edgeGlow;
    tinted += float3(0.8, 0.85, 1.0) * edge * 0.2;

    // Hafif gökkuşağı dispersiyon (prism efekti)
    float dispersion = noise * 0.02;
    tinted.r += dispersion;
    tinted.b -= dispersion;

    // Specular highlight (ışık yansıması noktası)
    float2 lightPos = float2(0.3, 0.3) + float2(sin(t * 0.5), cos(t * 0.3)) * 0.1;
    float specular = pow(max(0.0, 1.0 - length(uv - lightPos) * 3.0), 8.0);
    tinted += float3(1.0, 1.0, 1.0) * specular * 0.4;

    return float4(tinted, 1.0);
}
