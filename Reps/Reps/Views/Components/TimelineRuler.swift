import SwiftUI

/// Vertical timeline ruler that shows months and animates with scroll
struct TimelineRuler: View {
    let months: [MonthMarker]
    let currentMonthIndex: Int
    let totalHeight: CGFloat

    static let width: CGFloat = 60

    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            ForEach(Array(months.enumerated()), id: \.element.id) { index, month in
                VStack(alignment: .trailing, spacing: 4) {
                    // Month label
                    Text(month.shortName)
                        .font(.system(size: 11, weight: index == currentMonthIndex ? .bold : .medium, design: .monospaced))
                        .foregroundStyle(index == currentMonthIndex ? RepsTheme.Colors.accent : RepsTheme.Colors.textTertiary)

                    // Year (only show for first month or January)
                    if index == 0 || month.month == 1 {
                        Text(String(month.year))
                            .font(.system(size: 9, weight: .regular, design: .monospaced))
                            .foregroundStyle(RepsTheme.Colors.textTertiary)
                    }
                }
                .frame(height: month.height, alignment: .top)
                .padding(.top, 4)
            }

            Spacer()
        }
        .frame(width: Self.width)
        .padding(.trailing, RepsTheme.Spacing.xs)
    }
}

// MARK: - Month Marker

struct MonthMarker: Identifiable {
    let id = UUID()
    let month: Int // 1-12
    let year: Int
    let height: CGFloat
    let recordCount: Int

    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter
    }()

    var shortName: String {
        var components = DateComponents()
        components.month = month
        components.year = year
        if let date = Calendar.current.date(from: components) {
            return Self.monthFormatter.string(from: date).uppercased()
        }
        return ""
    }
}

// MARK: - Timeline Connector

/// Vertical line connecting timeline cards
struct TimelineConnector: View {
    let isFirst: Bool
    let isLast: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Top line
            if !isFirst {
                Rectangle()
                    .fill(RepsTheme.Colors.border)
                    .frame(width: 2)
            }

            // Dot
            Circle()
                .fill(RepsTheme.Colors.accent)
                .frame(width: 10, height: 10)

            // Bottom line
            if !isLast {
                Rectangle()
                    .fill(RepsTheme.Colors.border)
                    .frame(width: 2)
            }
        }
        .frame(width: 20)
    }
}

#Preview {
    HStack(alignment: .top) {
        TimelineRuler(
            months: [
                MonthMarker(month: 12, year: 2024, height: 150, recordCount: 3),
                MonthMarker(month: 11, year: 2024, height: 200, recordCount: 5),
                MonthMarker(month: 10, year: 2024, height: 100, recordCount: 2)
            ],
            currentMonthIndex: 0,
            totalHeight: 450
        )

        VStack(spacing: 12) {
            ForEach(0..<5) { i in
                HStack(alignment: .center) {
                    TimelineConnector(isFirst: i == 0, isLast: i == 4)
                        .frame(height: 80)

                    RoundedRectangle(cornerRadius: 8)
                        .fill(RepsTheme.Colors.surface)
                        .frame(height: 80)
                }
            }
        }
    }
    .padding()
    .background(RepsTheme.Colors.background)
    .preferredColorScheme(.dark)
}
