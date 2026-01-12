import SwiftUI

// MARK: - Stat Metric Card (AnyDistance 2x2 Grid Style)

/// Metric display card with large monospace value and change indicator
struct StatMetricCard: View {
    var value: String
    var unit: String
    var label: String
    var percentChange: Double? = nil
    var isSelected: Bool = false
    var showBackground: Bool = true
    var showChevron: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: RepsTheme.Spacing.xxs) {
            // Value + Unit
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(RepsTheme.Typography.metricLarge)
                    .foregroundColor(isSelected ? .black : RepsTheme.Colors.text)

                Text(unit)
                    .font(RepsTheme.Typography.label)
                    .foregroundColor(isSelected ? .black.opacity(0.7) : RepsTheme.Colors.textSecondary)
                    .baselineOffset(12)

                if showChevron {
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(RepsTheme.Colors.textTertiary)
                }
            }

            // Label + Change
            HStack(spacing: RepsTheme.Spacing.xs) {
                Text(label)
                    .font(RepsTheme.Typography.footnote)
                    .foregroundColor(isSelected ? .black.opacity(0.6) : RepsTheme.Colors.textSecondary)

                if let change = percentChange {
                    ChangeIndicator(value: change, isSelected: isSelected)
                }
            }
        }
        .padding(RepsTheme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(ConditionalCardStyle(showBackground: showBackground, isSelected: isSelected))
    }
}

/// Conditional card style that applies repsCard-like styling based on state
private struct ConditionalCardStyle: ViewModifier {
    var showBackground: Bool
    var isSelected: Bool

    func body(content: Content) -> some View {
        if showBackground {
            content
                .background(
                    RoundedRectangle(cornerRadius: RepsTheme.Radius.md)
                        .fill(isSelected ? Color.white : RepsTheme.Colors.surface)
                        .shadow(
                            color: RepsTheme.Shadow.md.color,
                            radius: RepsTheme.Shadow.md.radius,
                            x: RepsTheme.Shadow.md.x,
                            y: RepsTheme.Shadow.md.y
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: RepsTheme.Radius.md)
                        .stroke(RepsTheme.Colors.border, lineWidth: 1)
                )
        } else {
            content
        }
    }
}

// MARK: - Change Indicator

struct ChangeIndicator: View {
    var value: Double
    var isSelected: Bool = false

    private var isPositive: Bool { value >= 0 }

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                .font(.system(size: 10, weight: .semibold))

            Text("\(abs(Int(value)))%")
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundColor(indicatorColor)
    }

    private var indicatorColor: Color {
        if isSelected {
            return isPositive ? RepsTheme.Colors.chartGreen : RepsTheme.Colors.chartRed
        }
        return isPositive ? RepsTheme.Colors.chartGreen : RepsTheme.Colors.chartRed
    }
}

// MARK: - Compact Metric Card

/// Smaller metric card for inline displays
struct CompactMetricCard: View {
    var value: String
    var unit: String
    var label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 1) {
                Text(value)
                    .font(RepsTheme.Typography.metricMedium)
                    .foregroundColor(RepsTheme.Colors.text)

                Text(unit)
                    .font(RepsTheme.Typography.labelSmall)
                    .foregroundColor(RepsTheme.Colors.textSecondary)
                    .baselineOffset(8)
            }

            Text(label)
                .font(RepsTheme.Typography.caption)
                .foregroundColor(RepsTheme.Colors.textSecondary)
        }
    }
}

// MARK: - Metric Grid (2x2)

struct MetricGrid: View {
    var metrics: [MetricData]
    @Binding var selectedIndex: Int?

    var body: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: RepsTheme.Spacing.xs),
                GridItem(.flexible(), spacing: RepsTheme.Spacing.xs)
            ],
            spacing: RepsTheme.Spacing.xs
        ) {
            ForEach(Array(metrics.enumerated()), id: \.offset) { index, metric in
                Button {
                    withAnimation(RepsTheme.Animations.selection) {
                        selectedIndex = selectedIndex == index ? nil : index
                    }
                    HapticManager.filterSelected()
                } label: {
                    StatMetricCard(
                        value: metric.value,
                        unit: metric.unit,
                        label: metric.label,
                        percentChange: metric.percentChange,
                        isSelected: selectedIndex == index
                    )
                }
                .buttonStyle(ScalingPressButtonStyle())
            }
        }
    }
}

// MARK: - Metric Data Model

struct MetricData: Identifiable {
    let id = UUID()
    var value: String
    var unit: String
    var label: String
    var percentChange: Double?
}

#Preview {
    VStack(spacing: 24) {
        StatMetricCard(
            value: "12,450",
            unit: "lbs",
            label: "Total Volume",
            percentChange: 12
        )

        StatMetricCard(
            value: "225",
            unit: "lbs",
            label: "Max Bench",
            percentChange: -5,
            isSelected: true
        )

        MetricGrid(
            metrics: [
                MetricData(value: "12", unit: "", label: "Workouts", percentChange: 8),
                MetricData(value: "45.2k", unit: "lbs", label: "Volume", percentChange: 15),
                MetricData(value: "3", unit: "", label: "PRs", percentChange: nil),
                MetricData(value: "4.2", unit: "hrs", label: "Time", percentChange: -3)
            ],
            selectedIndex: .constant(nil)
        )
    }
    .padding()
    .background(RepsTheme.Colors.background)
}
