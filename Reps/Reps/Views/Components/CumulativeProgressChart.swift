import SwiftUI
import Charts

// MARK: - Cumulative Progress Chart (AnyDistance-style Line Graph)

/// Line chart showing cumulative volume/progress over time with YoY comparison
@available(iOS 16.0, *)
struct CumulativeProgressChart: View {
    var currentPeriodData: [ChartDataPoint]
    var previousPeriodData: [ChartDataPoint]?
    var lineColor: Color = RepsTheme.Colors.chartLine
    var previousLineColor: Color = Color.white.opacity(0.3)
    var showGrid: Bool = true
    var height: CGFloat = 200
    var xAxisLabelFormatter: ((Int) -> String)? = nil  // Custom x-axis label formatter

    @State private var selectedPoint: ChartDataPoint?

    var body: some View {
        VStack(alignment: .leading, spacing: RepsTheme.Spacing.sm) {
            // Header with comparison
            if let previousData = previousPeriodData,
               let currentLast = currentPeriodData.last,
               let previousLast = previousData.last {
                ComparisonHeader(
                    currentValue: currentLast.value,
                    previousValue: previousLast.value
                )
            }

            // Chart
            Chart {
                // Previous period (dashed)
                if let previousData = previousPeriodData {
                    ForEach(previousData) { point in
                        LineMark(
                            x: .value("Day", point.index),
                            y: .value("Volume", point.value)
                        )
                        .foregroundStyle(previousLineColor)
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                    }
                }

                // Current period (solid)
                ForEach(currentPeriodData) { point in
                    LineMark(
                        x: .value("Day", point.index),
                        y: .value("Volume", point.value)
                    )
                    .foregroundStyle(lineColor)
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))

                    AreaMark(
                        x: .value("Day", point.index),
                        y: .value("Volume", point.value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [lineColor.opacity(0.3), lineColor.opacity(0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }

                // Selected point indicator
                if let selected = selectedPoint {
                    PointMark(
                        x: .value("Day", selected.index),
                        y: .value("Volume", selected.value)
                    )
                    .foregroundStyle(lineColor)
                    .symbolSize(100)

                    RuleMark(x: .value("Day", selected.index))
                        .foregroundStyle(Color.white.opacity(0.3))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.white.opacity(0.1))
                    AxisTick(stroke: StrokeStyle(lineWidth: 0))
                    if let formatter = xAxisLabelFormatter, let intValue = value.as(Int.self) {
                        AxisValueLabel {
                            Text(formatter(intValue))
                                .foregroundStyle(RepsTheme.Colors.textSecondary)
                                .font(RepsTheme.Typography.caption)
                        }
                    } else {
                        AxisValueLabel()
                            .foregroundStyle(RepsTheme.Colors.textSecondary)
                            .font(RepsTheme.Typography.caption)
                    }
                }
            }
            .chartYAxis {
                AxisMarks(values: .automatic) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.white.opacity(showGrid ? 0.1 : 0))
                    AxisTick(stroke: StrokeStyle(lineWidth: 0))
                    AxisValueLabel()
                        .foregroundStyle(RepsTheme.Colors.textSecondary)
                        .font(RepsTheme.Typography.caption)
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geo in
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    guard let plotFrame = proxy.plotFrame else { return }
                                    let x = value.location.x - geo[plotFrame].origin.x
                                    if let index: Int = proxy.value(atX: x) {
                                        selectedPoint = currentPeriodData.first { $0.index == index }
                                        HapticManager.valueChanged()
                                    }
                                }
                                .onEnded { _ in
                                    withAnimation(RepsTheme.Animations.selection) {
                                        selectedPoint = nil
                                    }
                                }
                        )
                }
            }
            .frame(height: height)

            // Legend
            if previousPeriodData != nil {
                ChartLegend()
            }
        }
    }
}

// MARK: - Comparison Header

struct ComparisonHeader: View {
    var currentValue: Double
    var previousValue: Double

    private var percentChange: Double {
        guard previousValue > 0 else { return 0 }
        return ((currentValue - previousValue) / previousValue) * 100
    }

    private var isPositive: Bool { percentChange >= 0 }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: RepsTheme.Spacing.xs) {
            Text(formattedValue(currentValue))
                .font(RepsTheme.Typography.metricLarge)
                .foregroundColor(RepsTheme.Colors.text)

            Text("lbs")
                .font(RepsTheme.Typography.label)
                .foregroundColor(RepsTheme.Colors.textSecondary)

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                Text("\(abs(Int(percentChange)))%")
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(isPositive ? RepsTheme.Colors.chartGreen : RepsTheme.Colors.chartRed)

            Text("vs last period")
                .font(RepsTheme.Typography.caption)
                .foregroundColor(RepsTheme.Colors.textSecondary)
        }
    }

    private func formattedValue(_ value: Double) -> String {
        if value >= 1000000 {
            return String(format: "%.1fM", value / 1000000)
        } else if value >= 1000 {
            return String(format: "%.1fk", value / 1000)
        }
        return "\(Int(value))"
    }
}

// MARK: - Chart Legend

struct ChartLegend: View {
    var body: some View {
        HStack(spacing: RepsTheme.Spacing.md) {
            LegendItem(color: RepsTheme.Colors.chartLine, label: "This Period", dashed: false)
            LegendItem(color: .white.opacity(0.3), label: "Last Period", dashed: true)
        }
    }
}

struct LegendItem: View {
    var color: Color
    var label: String
    var dashed: Bool

    var body: some View {
        HStack(spacing: RepsTheme.Spacing.xxs) {
            if dashed {
                HStack(spacing: 2) {
                    ForEach(0..<3, id: \.self) { _ in
                        Rectangle()
                            .fill(color)
                            .frame(width: 4, height: 2)
                    }
                }
            } else {
                Rectangle()
                    .fill(color)
                    .frame(width: 16, height: 2)
            }

            Text(label)
                .font(RepsTheme.Typography.caption)
                .foregroundColor(RepsTheme.Colors.textSecondary)
        }
    }
}

// MARK: - Chart Data Point

struct ChartDataPoint: Identifiable {
    let id = UUID()
    var index: Int
    var value: Double
    var label: String?
}

// MARK: - Simple Spark Line (for inline displays)

@available(iOS 16.0, *)
struct SparkLine: View {
    var data: [Double]
    var color: Color = RepsTheme.Colors.chartLine
    var height: CGFloat = 30

    var body: some View {
        Chart {
            ForEach(Array(data.enumerated()), id: \.offset) { index, value in
                LineMark(
                    x: .value("X", index),
                    y: .value("Y", value)
                )
                .foregroundStyle(color)
                .lineStyle(StrokeStyle(lineWidth: 1.5, lineCap: .round))
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .frame(height: height)
    }
}

// MARK: - Weekly Volume Chart

@available(iOS 16.0, *)
struct WeeklyVolumeChart: View {
    var data: [DayVolumeData]
    var barColor: Color = RepsTheme.Colors.accent

    var body: some View {
        Chart {
            ForEach(data) { day in
                BarMark(
                    x: .value("Day", day.dayName),
                    y: .value("Volume", day.volume)
                )
                .foregroundStyle(
                    day.isToday ? barColor : barColor.opacity(0.5)
                )
                .cornerRadius(4)
            }
        }
        .chartXAxis {
            AxisMarks { _ in
                AxisValueLabel()
                    .foregroundStyle(RepsTheme.Colors.textSecondary)
                    .font(RepsTheme.Typography.caption)
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color.white.opacity(0.1))
            }
        }
    }
}

struct DayVolumeData: Identifiable {
    let id = UUID()
    var dayName: String
    var volume: Double
    var isToday: Bool = false
}

#Preview {
    if #available(iOS 16.0, *) {
        VStack(spacing: 32) {
            CumulativeProgressChart(
                currentPeriodData: [
                    ChartDataPoint(index: 1, value: 5000),
                    ChartDataPoint(index: 2, value: 12000),
                    ChartDataPoint(index: 3, value: 18000),
                    ChartDataPoint(index: 4, value: 25000),
                    ChartDataPoint(index: 5, value: 35000),
                    ChartDataPoint(index: 6, value: 42000),
                    ChartDataPoint(index: 7, value: 50000)
                ],
                previousPeriodData: [
                    ChartDataPoint(index: 1, value: 4500),
                    ChartDataPoint(index: 2, value: 10000),
                    ChartDataPoint(index: 3, value: 15000),
                    ChartDataPoint(index: 4, value: 22000),
                    ChartDataPoint(index: 5, value: 28000),
                    ChartDataPoint(index: 6, value: 35000),
                    ChartDataPoint(index: 7, value: 40000)
                ]
            )

            WeeklyVolumeChart(data: [
                DayVolumeData(dayName: "M", volume: 8000),
                DayVolumeData(dayName: "T", volume: 0),
                DayVolumeData(dayName: "W", volume: 12000),
                DayVolumeData(dayName: "T", volume: 0),
                DayVolumeData(dayName: "F", volume: 15000, isToday: true),
                DayVolumeData(dayName: "S", volume: 0),
                DayVolumeData(dayName: "S", volume: 0)
            ])
            .frame(height: 120)

            SparkLine(data: [10, 15, 12, 18, 22, 20, 25, 30, 28, 35])
                .frame(width: 100)
        }
        .padding()
        .background(RepsTheme.Colors.background)
    }
}
