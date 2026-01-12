import SwiftUI

// MARK: - Holographic Text

/// Alias to use new holographic shader for all gradient titles
typealias GradientTitle = HolographicText

/// Premium title text with holographic rainbow shift, parallax, and dynamic shadows
/// Uses Metal shader for GPU-accelerated effect
/// Responds to unified light source from MotionManager
struct HolographicText: View {
    let text: String
    var fontSize: CGFloat = 34
    var parallaxIntensity: CGFloat = 3   // Degrees of rotation
    var shadowIntensity: CGFloat = 0.4
    var useShimmer: Bool = false         // Use subtle shimmer variant

    @ObservedObject private var motion = MotionManager.shared
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State private var startDate = Date.now
    @State private var size: CGSize = .zero

    private var accentHue: Float {
        let uiColor = UIColor(RepsTheme.Colors.accent)
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return Float(h)
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0/30.0, paused: reduceMotion)) { timeline in
            let time = Float(timeline.date.timeIntervalSince(startDate))
            // Use estimated size based on font for shader, avoiding zero-size issue
            let effectiveWidth = max(size.width, fontSize * CGFloat(text.count) * 0.6)
            let effectiveHeight = max(size.height, fontSize * 1.2)

            Text(text)
                .font(.system(size: fontSize, weight: .bold, design: .rounded))
                .foregroundStyle(holographicShaderSafe(time: time, width: effectiveWidth, height: effectiveHeight))
                .rotation3DEffect(
                    .degrees(reduceMotion ? 0 : motion.pitch * parallaxIntensity),
                    axis: (x: 1, y: 0, z: 0),
                    perspective: 0.5
                )
                .rotation3DEffect(
                    .degrees(reduceMotion ? 0 : motion.roll * parallaxIntensity),
                    axis: (x: 0, y: 1, z: 0),
                    perspective: 0.5
                )
                .shadow(
                    color: RepsTheme.Colors.accent.opacity(shadowIntensity),
                    radius: 4 + abs(motion.roll) * 2,
                    x: CGFloat(motion.roll * 4),
                    y: CGFloat(motion.pitch * 4)
                )
                .shadow(
                    color: .black.opacity(0.3),
                    radius: 2,
                    x: 0,
                    y: 2
                )
        }
        .drawingGroup()  // GPU-accelerate composite of shader + rotations + shadows
        .background(
            GeometryReader { geo in
                Color.clear
                    .onAppear { size = geo.size }
                    .onChange(of: geo.size) { _, newSize in size = newSize }
            }
        )
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: motion.pitch)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: motion.roll)
        .onAppear { motion.startUpdates() }
        .onDisappear { motion.stopUpdates() }
    }

    private func holographicShaderSafe(time: Float, width: CGFloat, height: CGFloat) -> Shader {
        if useShimmer {
            return ShaderLibrary.shimmerText(
                .float2(Float(width), Float(height)),
                .float(Float(motion.lightAngle)),
                .float(time),
                .float(accentHue)
            )
        } else {
            return ShaderLibrary.holographicText(
                .float2(Float(width), Float(height)),
                .float(Float(motion.lightAngle)),
                .float(time),
                .float(accentHue)
            )
        }
    }
}

// MARK: - View Modifier

struct HolographicModifier: ViewModifier {
    var intensity: CGFloat = 0.8
    var useShimmer: Bool = false

    @ObservedObject private var motion = MotionManager.shared
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State private var startDate = Date.now
    @State private var size: CGSize = .zero

    private var accentHue: Float {
        let uiColor = UIColor(RepsTheme.Colors.accent)
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return Float(h)
    }

    func body(content: Content) -> some View {
        TimelineView(.animation(minimumInterval: 1.0/30.0, paused: reduceMotion)) { timeline in
            let time = Float(timeline.date.timeIntervalSince(startDate))

            content
                .foregroundStyle(shader(time: time))
        }
        .drawingGroup()  // GPU-accelerate shader composite
        .background(
            GeometryReader { geo in
                Color.clear
                    .onAppear { size = geo.size }
                    .onChange(of: geo.size) { _, newSize in size = newSize }
            }
        )
        .onAppear { motion.startUpdates() }
        .onDisappear { motion.stopUpdates() }
    }

    private func shader(time: Float) -> Shader {
        if useShimmer {
            return ShaderLibrary.shimmerText(
                .float2(Float(size.width), Float(size.height)),
                .float(Float(motion.lightAngle)),
                .float(time),
                .float(accentHue)
            )
        } else {
            return ShaderLibrary.holographicText(
                .float2(Float(size.width), Float(size.height)),
                .float(Float(motion.lightAngle)),
                .float(time),
                .float(accentHue)
            )
        }
    }
}

// MARK: - View Extension

extension View {
    /// Apply holographic effect to any view (text works best)
    func holographic(intensity: CGFloat = 0.8, shimmer: Bool = false) -> some View {
        modifier(HolographicModifier(intensity: intensity, useShimmer: shimmer))
    }
}

// MARK: - Preview

#Preview("Holographic Text") {
    VStack(spacing: 32) {
        HolographicText(text: "Workout")
            .padding()

        HolographicText(text: "Premium", fontSize: 28, useShimmer: true)

        Text("Shimmer")
            .font(.system(size: 24, weight: .bold))
            .holographic(shimmer: true)

        // Side-by-side comparison
        HStack(spacing: 24) {
            VStack {
                Text("Holo")
                    .font(.title.bold())
                    .holographic()
                Text("With shader")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VStack {
                Text("Plain")
                    .font(.title.bold())
                    .foregroundStyle(.white)
                Text("No effect")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.black)
}
