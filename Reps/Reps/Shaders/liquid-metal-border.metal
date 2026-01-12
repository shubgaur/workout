// Licensed under the Reps Source License
//
//  liquid-metal-border.metal
//  Reps
//
//  Liquid metal border effect with theme-aware tinting
//  Chrome base with accent color chromatic aberration

#include <metal_stdlib>
using namespace metal;

// Constants
constant half TWO_PI_H = 6.28318h;
constant half DEG_TO_RAD = 0.0174533h;

// Soft step function for smooth transitions
half softStep(half edge0, half edge1, half x) {
    half t = clamp((x - edge0) / (edge1 - edge0), 0.0h, 1.0h);
    return t * t * (3.0h - 2.0h * t);
}

// MARK: - Liquid Metal Border Shader

[[stitchable]] half4 liquidMetalBorder(
    float2 position,
    half4 color,
    float2 size,
    float time,
    float lightAngle,
    half4 accentColor  // Theme accent color (RGBA)
) {
    // Skip transparent pixels
    if (color.a < 0.01h) {
        return color;
    }

    // Normalize position
    half2 uv = half2(position / size);
    half2 center = half2(0.5h, 0.5h);

    // Angle from center to this pixel (0 to 2PI)
    half2 toPixel = uv - center;
    half pixelAngle = atan2(toPixel.y, toPixel.x);
    if (pixelAngle < 0.0h) pixelAngle += TWO_PI_H;

    // Light angle in radians (normalized 0 to 2PI)
    half lightRad = fmod(half(lightAngle) * DEG_TO_RAD + TWO_PI_H, TWO_PI_H);

    // Angle relative to light position
    half relativeAngle = fmod(pixelAngle - lightRad + TWO_PI_H, TWO_PI_H);

    // === CHROME BASE ===
    // Smooth gradient from light to dark using cosine
    half chromeBase = 0.35h + 0.45h * cos(relativeAngle);

    // === ACCENT-TINTED CHROMATIC ABERRATION ===
    // Extract accent RGB
    half3 accent = accentColor.rgb;

    // Create complementary/shifted colors for chromatic effect
    // Shift hue slightly for the "aberration" channels
    half3 warmShift = half3(
        accent.r * 1.2h + 0.1h,  // Boost red/warm
        accent.g * 0.9h,
        accent.b * 0.7h           // Reduce blue
    );
    half3 coolShift = half3(
        accent.r * 0.7h,          // Reduce red
        accent.g * 0.9h,
        accent.b * 1.2h + 0.1h    // Boost blue/cool
    );

    // Chromatic channel offsets
    half shiftAmount = 0.1h;

    // Warm channel - slightly ahead
    half warmAngle = fmod(relativeAngle + shiftAmount * TWO_PI_H, TWO_PI_H);
    half warmIntensity = 0.3h + 0.6h * cos(warmAngle);

    // Cool channel - slightly behind
    half coolAngle = fmod(relativeAngle - shiftAmount * TWO_PI_H + TWO_PI_H, TWO_PI_H);
    half coolIntensity = 0.3h + 0.6h * cos(coolAngle);

    // Center channel (main accent color)
    half centerIntensity = chromeBase;

    // === COMPOSE FINAL COLOR ===
    // Blend chrome with accent-tinted chromatic aberration
    half3 chrome = half3(chromeBase);

    // Mix in the chromatic channels
    half3 warmContribution = warmShift * warmIntensity * 0.4h;
    half3 coolContribution = coolShift * coolIntensity * 0.4h;
    half3 accentContribution = accent * centerIntensity * 0.3h;

    half3 finalColor = chrome * 0.5h + warmContribution + coolContribution + accentContribution;

    // === SPECULAR HIGHLIGHT ===
    half highlightWidth = 0.12h;
    half highlightDist = min(relativeAngle, TWO_PI_H - relativeAngle) / TWO_PI_H;
    half specular = softStep(highlightWidth, 0.0h, highlightDist) * 0.7h;

    // Add white specular with slight accent tint
    half3 specularColor = mix(half3(1.0h), accent, 0.2h);
    finalColor += specularColor * specular;

    // Subtle time-based shimmer
    half shimmer = sin(half(time) * 0.5h + pixelAngle) * 0.012h;
    finalColor += shimmer;

    return half4(clamp(finalColor, 0.0h, 1.0h), color.a);
}
