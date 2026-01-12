import SwiftUI

// MARK: - Skeleton Loading Views

/// Shimmer animation overlay for loading states
struct SkeletonModifier: ViewModifier {
    @State private var phase: CGFloat = -1
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    if !reduceMotion {
                        LinearGradient(
                            colors: [
                                .clear,
                                .white.opacity(0.15),
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: geo.size.width * 2)
                        .offset(x: phase * geo.size.width * 2)
                    }
                }
                .mask(content)
            )
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

extension View {
    /// Apply skeleton shimmer effect
    func skeleton() -> some View {
        modifier(SkeletonModifier())
    }
}

// MARK: - Skeleton Shapes

/// Generic skeleton placeholder
struct SkeletonShape: View {
    var width: CGFloat? = nil
    var height: CGFloat = 16
    var radius: CGFloat = RepsTheme.Radius.sm

    var body: some View {
        RoundedRectangle(cornerRadius: radius)
            .fill(RepsTheme.Colors.surfaceElevated)
            .frame(width: width, height: height)
            .skeleton()
    }
}

/// Skeleton for text lines
struct SkeletonText: View {
    var lines: Int = 3
    var lastLineWidth: CGFloat = 0.6

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(0..<lines, id: \.self) { index in
                SkeletonShape(
                    width: index == lines - 1 ? nil : nil,
                    height: 14
                )
                .frame(maxWidth: index == lines - 1 ? .infinity : .infinity)
                .scaleEffect(x: index == lines - 1 ? lastLineWidth : 1, anchor: .leading)
            }
        }
    }
}

/// Skeleton for stat card
struct SkeletonStatCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: RepsTheme.Spacing.sm) {
            SkeletonShape(width: 80, height: 32, radius: RepsTheme.Radius.xs)
            SkeletonShape(width: 60, height: 12, radius: RepsTheme.Radius.xs)
        }
        .padding(RepsTheme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RepsTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.md))
    }
}

/// Skeleton for workout card
struct SkeletonWorkoutCard: View {
    var body: some View {
        HStack(spacing: RepsTheme.Spacing.md) {
            // Icon placeholder
            SkeletonShape(width: 44, height: 44, radius: RepsTheme.Radius.sm)

            VStack(alignment: .leading, spacing: RepsTheme.Spacing.xs) {
                SkeletonShape(width: 120, height: 16)
                SkeletonShape(width: 80, height: 12)
            }

            Spacer()

            // Chevron placeholder
            SkeletonShape(width: 8, height: 14, radius: 2)
        }
        .padding(RepsTheme.Spacing.md)
        .background(RepsTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.md))
    }
}

/// Skeleton for exercise row
struct SkeletonExerciseRow: View {
    var body: some View {
        HStack(spacing: RepsTheme.Spacing.md) {
            // Image placeholder
            SkeletonShape(width: 56, height: 56, radius: RepsTheme.Radius.sm)

            VStack(alignment: .leading, spacing: RepsTheme.Spacing.xs) {
                SkeletonShape(width: 140, height: 16)
                HStack(spacing: RepsTheme.Spacing.xs) {
                    SkeletonShape(width: 50, height: 20, radius: RepsTheme.Radius.full)
                    SkeletonShape(width: 60, height: 20, radius: RepsTheme.Radius.full)
                }
            }

            Spacer()
        }
        .padding(RepsTheme.Spacing.md)
        .background(RepsTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.md))
    }
}

/// Skeleton for chart
struct SkeletonChart: View {
    var body: some View {
        VStack(alignment: .leading, spacing: RepsTheme.Spacing.md) {
            // Header
            HStack {
                SkeletonShape(width: 100, height: 16)
                Spacer()
                SkeletonShape(width: 60, height: 24, radius: RepsTheme.Radius.full)
            }

            // Chart area
            SkeletonShape(height: 180, radius: RepsTheme.Radius.md)

            // Legend
            HStack(spacing: RepsTheme.Spacing.lg) {
                SkeletonShape(width: 80, height: 12)
                SkeletonShape(width: 80, height: 12)
            }
        }
        .padding(RepsTheme.Spacing.md)
        .background(RepsTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.lg))
    }
}

// MARK: - Preview

#Preview("Skeleton Components") {
    ScrollView {
        VStack(spacing: RepsTheme.Spacing.md) {
            Text("Stat Cards")
                .font(RepsTheme.Typography.label)
                .foregroundStyle(RepsTheme.Colors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: RepsTheme.Spacing.sm) {
                SkeletonStatCard()
                SkeletonStatCard()
            }

            Text("Workout Card")
                .font(RepsTheme.Typography.label)
                .foregroundStyle(RepsTheme.Colors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            SkeletonWorkoutCard()

            Text("Exercise Row")
                .font(RepsTheme.Typography.label)
                .foregroundStyle(RepsTheme.Colors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            SkeletonExerciseRow()

            Text("Chart")
                .font(RepsTheme.Typography.label)
                .foregroundStyle(RepsTheme.Colors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            SkeletonChart()
        }
        .padding()
    }
    .background(RepsTheme.Colors.background)
}
