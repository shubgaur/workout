// Licensed under the Reps Source License
//
//  animated-gradient.metal
//  Reps
//
//  GPU-accelerated animated gradient using dynamic palette colors
//  Based on AnyDistance gradient animation by Daniel Kuntz

#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float2 position;
};

struct VertexOut {
    float4 position [[position]];
    float time;
    float2 viewSize;
    int page;
};

struct Uniforms {
    float time;
    int page;                // 0-3: mapped from palette
    float brightness;        // 0.0-1.0: overall brightness (default 0.5 for subtle)
    float _padding;          // Align float3 to 16-byte boundary
    float3 accentColor;      // Palette accent (fallback)
    float3 backgroundColor;  // Palette background
    float3 secondaryColor;   // Palette secondary
};

/// Passthrough vertex shader
vertex VertexOut gradient_animation_vertex(
    const device packed_float3* in [[buffer(0)]],
    constant float &time [[buffer(1)]],
    const device packed_float2* viewSize [[buffer(2)]],
    constant int &page [[buffer(3)]],
    unsigned int vid [[vertex_id]]) {

    VertexOut out;
    out.position = float4(in[vid], 1);
    out.time = time + (float)page * 10.0;  // Page offset for variation
    out.viewSize = float2(viewSize->x, viewSize->y);
    out.page = page;
    return out;
}

float noise1(float seed1, float seed2){
    return(
        fract(seed1 + 12.34567 *
              fract(100.0 * (abs(seed1 * 0.91) + seed2 + 94.68) *
                    fract((abs(seed2 * 0.41) + 45.46) *
                          fract((abs(seed2) + 757.21) *
                                fract(seed1 * 0.0171))))))
        * 1.0038 - 0.00185;
}

float noise2(float seed1, float seed2, float seed3){
    float buff1 = abs(seed1 + 100.81) + 1000.3;
    float buff2 = abs(seed2 + 100.45) + 1000.2;
    float buff3 = abs(noise1(seed1, seed2) + seed3) + 1000.1;
    buff1 = (buff3 * fract(buff2 * fract(buff1 * fract(buff2 * 0.146))));
    buff2 = (buff2 * fract(buff2 * fract(buff1 + buff2 * fract(buff3 * 0.52))));
    buff1 = noise1(buff1, buff2);
    return(buff1);
}

float noise3(float seed1, float seed2, float seed3) {
    float buff1 = abs(seed1 + 100.813) + 1000.314;
    float buff2 = abs(seed2 + 100.453) + 1000.213;
    float buff3 = abs(noise1(buff2, buff1) + seed3) + 1000.17;
    buff1 = (buff3 * fract(buff2 * fract(buff1 * fract(buff2 * 0.14619))));
    buff2 = (buff2 * fract(buff2 * fract(buff1 + buff2 * fract(buff3 * 0.5215))));
    buff1 = noise2(noise1(seed2, buff1), noise1(seed1, buff2), noise1(seed3, buff3));
    return(buff1);
}

/// Fragment shader for animated gradient with page-based color schemes
fragment float4 gradient_animation_fragment(
    VertexOut in [[stage_in]],
    constant Uniforms &uniforms [[buffer(0)]]) {

    float2 st = in.position.xy / in.viewSize.xy;
    st = float2(tan(st.x), sin(st.y));

    // Coordinate warping for organic motion
    st.x += (sin(in.time / 2.1) + 2.0) * 0.12 * sin(sin(st.y * st.x + in.time / 6.0) * 8.2);
    st.y -= (cos(in.time / 1.73) + 2.0) * 0.12 * cos(st.x * st.y * 5.1 - in.time / 4.0);

    float3 bg = float3(0.0);

    // Page-based color schemes (exact AnyDistance colors)
    float3 color1;
    float3 color2;
    float3 color3;
    float3 color4;
    float3 color5;

    if (in.page == 0) {
        // Orange/Red - Dark, Sunset, Ember palettes
        color1 = float3(252.0/255.0, 60.0/255.0, 0.0/255.0);
        color2 = float3(253.0/255.0, 0.0/255.0, 12.0/255.0);
        color3 = float3(26.0/255.0, 0.5/255.0, 6.0/255.0);
        color4 = float3(128.0/255.0, 0.0/255.0, 17.0/255.0);
        color5 = float3(255.0/255.0, 15.0/255.0, 8.0/255.0);
    } else if (in.page == 1) {
        // Blue/Cyan - Ocean, Midnight palettes
        color1 = float3(183.0/255.0, 246.0/255.0, 254.0/255.0);
        color2 = float3(50.0/255.0, 160.0/255.0, 251.0/255.0);
        color3 = float3(3.0/255.0, 79.0/255.0, 231.0/255.0);
        color4 = float3(1.0/255.0, 49.0/255.0, 161.0/255.0);
        color5 = float3(3.0/255.0, 12.0/255.0, 47.0/255.0);
    } else if (in.page == 2) {
        // Teal/Green - Forest palette
        color1 = float3(102.0/255.0, 231.0/255.0, 255.0/255.0);
        color2 = float3(4.0/255.0, 207.0/255.0, 213.0/255.0);
        color3 = float3(0.0/255.0, 160.0/255.0, 119.0/255.0);
        color4 = float3(0.0/255.0, 175.0/255.0, 139.0/255.0);
        color5 = float3(2.0/255.0, 37.0/255.0, 27.0/255.0);
    } else {
        // Vibrant multi-color - Custom/Magic palettes
        color1 = float3(255.0/255.0, 50.0/255.0, 134.0/255.0);
        color2 = float3(236.0/255.0, 18.0/255.0, 60.0/255.0);
        color3 = float3(178.0/255.0, 254.0/255.0, 0.0/255.0);
        color4 = float3(0.0/255.0, 248.0/255.0, 209.0/255.0);
        color5 = float3(0.0/255.0, 186.0/255.0, 255.0/255.0);
    }

    // 10 organic blobs with softer edges and varied shapes
    // Using wider smoothstep ranges for softer gradients
    float mixValue = smoothstep(0.05, 1.1, distance(st, float2(sin(in.time / 7.2) + 0.4, sin(in.time / 8.3) + 0.6)));
    float3 outColor = mix(color1, bg, mixValue);

    mixValue = smoothstep(0.08, 1.0, distance(st, float2(sin(in.time / 5.1) + 0.8, sin(in.time / 5.8) - 0.15)));
    outColor = mix(color2, outColor, mixValue);

    mixValue = smoothstep(0.12, 0.95, distance(st, float2(sin(in.time / 4.7) + 0.15, sin(in.time / 4.5) + 0.5)));
    outColor = mix(color3, outColor, mixValue);

    mixValue = smoothstep(0.1, 1.05, distance(st, float2(sin(in.time / 6.8) - 0.25, sin(in.time / 7.3) + 0.75)));
    outColor = mix(color4, outColor, mixValue);

    mixValue = smoothstep(0.03, 1.0, distance(st, float2(sin(in.time / 11.2) + 0.28, sin(in.time / 5.2) + 0.18)));
    outColor = mix(color5, outColor, mixValue);

    // Second set with cos-based motion - larger, softer blobs
    mixValue = smoothstep(0.02, 1.1, distance(st, float2(cos(in.time / 9.8) / 2.0 + 0.1, sin(in.time / 6.2) - 0.2)));
    outColor = mix(color1, outColor, mixValue);

    mixValue = smoothstep(0.06, 1.05, distance(st, float2(cos(in.time / 8.2) / 2.0 + 0.65, sin(in.time / 5.5) + 0.7)));
    outColor = mix(color2, outColor, mixValue);

    mixValue = smoothstep(0.09, 0.98, distance(st, float2(cos(in.time / 5.9) / 2.0 + 0.25, sin(in.time / 7.8) + 0.9)));
    outColor = mix(color3, outColor, mixValue);

    mixValue = smoothstep(0.11, 1.02, distance(st, float2(cos(in.time / 12.1) / 2.0 - 0.35, sin(in.time / 7.1) + 0.85)));
    outColor = mix(color4, outColor, mixValue);

    mixValue = smoothstep(0.04, 1.08, distance(st, float2(cos(in.time / 6.1) / 2.0 + 0.58, sin(in.time / 6.3) + 0.88)));
    outColor = mix(color5, outColor, mixValue);

    // Subtle noise for texture
    float2 st_unwarped = in.position.xy / in.viewSize.xy;
    float3 noise = float3(noise3(st_unwarped.x * 0.000001, st_unwarped.y * 0.000001, in.time * 1e-15));
    // Apply brightness control (default 0.5 for subtle background)
    outColor = (outColor * uniforms.brightness) - (noise * 0.05);

    return float4(outColor, 1.0);
}
