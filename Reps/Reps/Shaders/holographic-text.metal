// Licensed under the Reps Source License
//
//  holographic-text.metal
//  Reps
//
//  GPU-accelerated holographic text effect with rainbow shift and metallic specular
//  Responds to unified light angle from MotionManager for coordinated effects

#include <metal_stdlib>
using namespace metal;

// MARK: - Color Utilities

/// Convert HSL to RGB for rainbow effect
half3 hsl2rgb(half h, half s, half l) {
    half c = (1.0h - abs(2.0h * l - 1.0h)) * s;
    half x = c * (1.0h - abs(fmod(h * 6.0h, 2.0h) - 1.0h));
    half m = l - c / 2.0h;

    half3 rgb;
    if (h < 1.0h/6.0h) {
        rgb = half3(c, x, 0.0h);
    } else if (h < 2.0h/6.0h) {
        rgb = half3(x, c, 0.0h);
    } else if (h < 3.0h/6.0h) {
        rgb = half3(0.0h, c, x);
    } else if (h < 4.0h/6.0h) {
        rgb = half3(0.0h, x, c);
    } else if (h < 5.0h/6.0h) {
        rgb = half3(x, 0.0h, c);
    } else {
        rgb = half3(c, 0.0h, x);
    }

    return rgb + m;
}

// MARK: - Holographic Text Shader

/// Main holographic effect - rainbow hue shift with metallic specular
/// Parameters:
///   - position: current pixel position
///   - color: input color (text alpha mask)
///   - size: view size for normalization
///   - lightAngle: unified light angle (0-360) from MotionManager
///   - time: animation time for subtle shimmer
///   - accentHue: base hue from palette accent color (0-1)
[[stitchable]] half4 holographicText(
    float2 position,
    half4 color,
    float2 size,
    float lightAngle,
    float time,
    float accentHue
) {
    // Skip fully transparent pixels
    if (color.a < 0.01h) {
        return color;
    }

    // Normalized UV coordinates (0-1)
    float2 uv = position / size;

    // Convert light angle to radians
    float lightRad = lightAngle * 0.0174533; // degrees to radians

    // MARK: Rainbow Hue Shift
    // Position-based hue that shifts with light angle
    // Creates holographic rainbow effect across the text
    float hueShift = uv.x * 0.4 + uv.y * 0.2;           // Position gradient
    hueShift += lightAngle / 360.0;                      // Light-responsive shift
    hueShift += sin(time * 0.5) * 0.05;                  // Subtle animation

    // Combine with accent hue for palette awareness
    float finalHue = fract(accentHue + hueShift * 0.6);

    // MARK: Metallic Specular Highlight
    // Simulates light reflection on metallic surface
    float specularPos = (uv.x - 0.5) * 3.14159 + lightRad;
    float specular = pow(max(0.0, cos(specularPos)), 12.0);

    // Secondary specular for depth
    float specular2 = pow(max(0.0, cos(specularPos * 1.5 + 0.5)), 8.0) * 0.3;

    // MARK: Vertical Gradient (top-lit metallic)
    float verticalGrad = 1.0 - uv.y * 0.3; // Brighter at top

    // MARK: Final Color Composition
    // Base holographic color (saturated rainbow)
    half3 holoColor = hsl2rgb(half(finalHue), 0.85h, 0.55h);

    // Add specular highlights (white for metallic shine)
    holoColor += half3(specular * 0.6);
    holoColor += half3(specular2 * 0.4);

    // Apply vertical gradient
    holoColor *= half(verticalGrad);

    // Boost saturation and contrast for premium feel
    holoColor = mix(half3(dot(holoColor, half3(0.299h, 0.587h, 0.114h))), holoColor, 1.3h);

    // Clamp to valid range
    holoColor = clamp(holoColor, 0.0h, 1.0h);

    return half4(holoColor, color.a);
}

// MARK: - Subtle Shimmer Variant

/// Lighter holographic effect - more metallic, less rainbow
/// Better for longer text or subtitles
[[stitchable]] half4 shimmerText(
    float2 position,
    half4 color,
    float2 size,
    float lightAngle,
    float time,
    float accentHue
) {
    if (color.a < 0.01h) {
        return color;
    }

    float2 uv = position / size;
    float lightRad = lightAngle * 0.0174533;

    // Subtle hue shift (less rainbow, more metallic)
    float hueShift = uv.x * 0.15 + lightAngle / 720.0;
    float finalHue = fract(accentHue + hueShift);

    // Strong metallic specular
    float specular = pow(max(0.0, cos((uv.x - 0.5) * 3.14159 + lightRad)), 16.0);

    // Moving shimmer band
    float shimmerBand = sin((uv.x + uv.y) * 20.0 - time * 2.0);
    shimmerBand = smoothstep(0.7, 1.0, shimmerBand) * 0.15;

    // Base metallic color
    half3 baseColor = hsl2rgb(half(finalHue), 0.4h, 0.7h);

    // Add specular and shimmer
    baseColor += half3(specular * 0.5 + shimmerBand);

    // Vertical gradient
    baseColor *= half(1.0 - uv.y * 0.2);

    return half4(clamp(baseColor, 0.0h, 1.0h), color.a);
}
