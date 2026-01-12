import SwiftUI

// MARK: - Pulsing Dot (for chart data points)

/// Animated pulsing dot for highlighting latest data points
struct PulsingDot: View {
    var color: Color = RepsTheme.Colors.chartLine
    var size: CGFloat = 8
    var pulseSize: CGFloat = 24
    var duration: Double = 1.4

    @State private var isPulsing = false
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        ZStack {
            // Expanding pulse ring
            if !reduceMotion {
                Circle()
                    .stroke(color.opacity(isPulsing ? 0 : 0.6), lineWidth: 2)
                    .frame(width: isPulsing ? pulseSize : size, height: isPulsing ? pulseSize : size)
                    .animation(
                        .easeOut(duration: duration).repeatForever(autoreverses: false),
                        value: isPulsing
                    )
            }

            // Solid center dot
            Circle()
                .fill(color)
                .frame(width: size, height: size)
                .shadow(color: color.opacity(0.5), radius: 4)
        }
        .onAppear {
            isPulsing = true
        }
    }
}

// MARK: - Animated Line Path

/// Animates a line path drawing from start to end
struct AnimatedLinePath: View {
    var points: [CGPoint]
    var color: Color = RepsTheme.Colors.chartLine
    var lineWidth: CGFloat = 2
    var animationDuration: Double = 0.6
    var showPulsingDot: Bool = true

    @State private var progress: CGFloat = 0
    @State private var showDot = false
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Animated line
                SmoothLinePath(points: points)
                    .trim(from: 0, to: reduceMotion ? 1 : progress)
                    .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                    .animation(
                        reduceMotion ? nil : .timingCurve(0.42, 0.27, 0.34, 0.96, duration: animationDuration),
                        value: progress
                    )

                // Pulsing dot at end
                if showPulsingDot, let lastPoint = points.last, showDot {
                    PulsingDot(color: color)
                        .position(lastPoint)
                        .transition(.opacity)
                }
            }
        }
        .onAppear {
            progress = 1.0
            DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
                withAnimation {
                    showDot = true
                }
            }
        }
    }
}

// MARK: - Smooth Line Path

/// Creates smooth curves between points using quadratic interpolation
struct SmoothLinePath: Shape {
    var points: [CGPoint]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard points.count >= 2 else { return path }

        path.move(to: points[0])

        for i in 1..<points.count {
            let current = points[i]
            let previous = points[i - 1]

            // Calculate midpoint
            let midPoint = CGPoint(
                x: (previous.x + current.x) / 2,
                y: (previous.y + current.y) / 2
            )

            // Use quadratic curve through midpoint
            if i == 1 {
                path.addLine(to: midPoint)
            } else {
                path.addQuadCurve(to: midPoint, control: previous)
            }
        }

        // Connect to last point
        if let last = points.last {
            path.addLine(to: last)
        }

        return path
    }
}

// MARK: - Chart Tooltip

/// Interactive tooltip for displaying data point info
struct ChartTooltip: View {
    var title: String
    var value: String
    var subtitle: String?
    var percentChange: Double?
    var isVisible: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(RepsTheme.Colors.textSecondary)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundStyle(RepsTheme.Colors.text)

                if let change = percentChange {
                    PercentChangeIndicator(value: change)
                }
            }

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundStyle(RepsTheme.Colors.textTertiary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(RepsTheme.Colors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(RepsTheme.Colors.border, lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
        .blurOpacityTransition(isVisible: isVisible)
    }
}

// MARK: - Percent Change Indicator

struct PercentChangeIndicator: View {
    var value: Double
    var size: CGFloat = 11

    var color: Color {
        if value > 0 { return RepsTheme.Colors.chartGreen }
        if value < 0 { return RepsTheme.Colors.chartRed }
        return RepsTheme.Colors.textSecondary
    }

    var iconName: String {
        if value > 0 { return "arrow.up.right" }
        if value < 0 { return "arrow.down.right" }
        return "minus"
    }

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: iconName)
                .font(.system(size: size - 2, weight: .semibold))

            Text("\(abs(Int(value)))%")
                .font(.system(size: size, weight: .medium, design: .monospaced))
        }
        .foregroundStyle(color)
    }
}

// MARK: - Vertical Indicator Line

/// Vertical line for chart scrubbing interaction
struct ChartIndicatorLine: View {
    var height: CGFloat
    var color: Color = RepsTheme.Colors.accent
    var dotSize: CGFloat = 8

    var body: some View {
        VStack(spacing: 0) {
            // Top dot
            Circle()
                .fill(color)
                .frame(width: dotSize, height: dotSize)

            // Vertical line
            Rectangle()
                .fill(color.opacity(0.4))
                .frame(width: 1, height: height - dotSize * 2)

            // Bottom dot
            Circle()
                .fill(color.opacity(0.4))
                .frame(width: dotSize, height: dotSize)
        }
    }
}

// MARK: - Preview

#Preview("Chart Components") {
    VStack(spacing: 40) {
        // Pulsing dot
        PulsingDot()

        // Animated line
        AnimatedLinePath(
            points: [
                CGPoint(x: 20, y: 100),
                CGPoint(x: 80, y: 60),
                CGPoint(x: 140, y: 80),
                CGPoint(x: 200, y: 40),
                CGPoint(x: 260, y: 70),
                CGPoint(x: 320, y: 30)
            ]
        )
        .frame(height: 120)

        // Tooltip
        ChartTooltip(
            title: "Total Volume",
            value: "45,250 kg",
            subtitle: "Nov 15, 2024",
            percentChange: 12.5,
            isVisible: true
        )

        // Percent change indicators
        HStack(spacing: 20) {
            PercentChangeIndicator(value: 15)
            PercentChangeIndicator(value: 0)
            PercentChangeIndicator(value: -8)
        }
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(RepsTheme.Colors.background)
}
