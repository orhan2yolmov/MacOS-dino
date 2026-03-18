// SimpleWave.metal
// MacOS-Dino – Dalga Efekti Metal Shader
// Sakin, hipnotik dalga hareketi arka planı

#include <metal_stdlib>
using namespace metal;

// Shared uniforms struct
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

// Vertex output
struct VertexOut {
    float4 position [[position]];
    float2 uv;
};

// Passthrough vertex shader (fullscreen quad)
vertex VertexOut vertex_passthrough(uint vid [[vertex_id]]) {
    VertexOut out;

    // Fullscreen triangle strip
    float2 positions[4] = {
        float2(-1, -1),
        float2( 1, -1),
        float2(-1,  1),
        float2( 1,  1)
    };

    float2 uvs[4] = {
        float2(0, 1),
        float2(1, 1),
        float2(0, 0),
        float2(1, 0)
    };

    out.position = float4(positions[vid], 0.0, 1.0);
    out.uv = uvs[vid];
    return out;
}

// --- Simple Wave Shader ---
fragment float4 fragment_simpleWave(VertexOut in [[stage_in]],
                                     constant ShaderUniforms &u [[buffer(0)]]) {
    float2 uv = in.uv;
    float t = u.time * 0.3;

    // Çoklu dalga katmanları
    float wave1 = sin(uv.x * 6.0 + t) * 0.05;
    float wave2 = sin(uv.x * 10.0 - t * 1.3) * 0.03;
    float wave3 = sin(uv.x * 14.0 + t * 0.7) * 0.02;
    float wave = wave1 + wave2 + wave3;

    // UV'yi dalgayla boz
    float2 distortedUV = uv + float2(0.0, wave);

    // Gradyan renkleri – koyu mavi → mor → koyu yeşil
    float3 color1 = float3(0.02, 0.05, 0.15); // Koyu gece mavisi
    float3 color2 = float3(0.10, 0.03, 0.20); // Koyu mor
    float3 color3 = float3(0.03, 0.12, 0.10); // Koyu yeşil

    float blend = distortedUV.y + wave * 2.0;
    float3 color = mix(color1, color2, smoothstep(0.0, 0.5, blend));
    color = mix(color, color3, smoothstep(0.5, 1.0, blend));

    // Parıltı efekti
    float sparkle = fract(sin(dot(uv * 100.0, float2(12.9898, 78.233))) * 43758.5453);
    sparkle = pow(sparkle, 40.0) * 0.5;
    color += sparkle;

    return float4(color, 1.0);
}
