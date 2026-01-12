import SwiftUI

/// A card displaying a personal record on the timeline
struct PRTimelineCard: View {
    let records: [PersonalRecord]
    let date: Date
    @State private var isExpanded = false

    private var isGrouped: Bool { records.count > 1 }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main card content
            if isGrouped {
                groupedContent
            } else if let record = records.first {
                singleRecordContent(record)
            }
        }
        .background(RepsTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: RepsTheme.Radius.md)
                .stroke(RepsTheme.Colors.border, lineWidth: 1)
        )
    }

    // MARK: - Single Record View

    private func singleRecordContent(_ record: PersonalRecord) -> some View {
        HStack(spacing: RepsTheme.Spacing.md) {
            // Trophy icon
            trophyIcon(for: record.recordType)

            // Details
            VStack(alignment: .leading, spacing: RepsTheme.Spacing.xxs) {
                Text(record.exercise?.name ?? "Unknown Exercise")
                    .font(RepsTheme.Typography.headline)
                    .foregroundStyle(RepsTheme.Colors.text)
                    .lineLimit(1)

                HStack(spacing: RepsTheme.Spacing.sm) {
                    Text(record.recordType.displayName)
                        .font(RepsTheme.Typography.caption)
                        .foregroundStyle(trophyColor(for: record.recordType))

                    Text(formatDate(date))
                        .font(RepsTheme.Typography.caption)
                        .foregroundStyle(RepsTheme.Colors.textTertiary)
                }
            }

            Spacer()

            // Value
            Text(record.formattedValue)
                .font(RepsTheme.Typography.mono)
                .foregroundStyle(RepsTheme.Colors.accent)
        }
        .padding(RepsTheme.Spacing.md)
    }

    // MARK: - Grouped Records View

    private var groupedContent: some View {
        VStack(spacing: 0) {
            // Header - tappable to expand/collapse
            Button {
                withAnimation(RepsTheme.Animations.expand) {
                    isExpanded.toggle()
                }
                HapticManager.light()
            } label: {
                HStack(spacing: RepsTheme.Spacing.md) {
                    // Stacked trophy icons with layered opacity
                    ZStack {
                        ForEach(Array(records.prefix(3).enumerated().reversed()), id: \.offset) { index, record in
                            trophyIcon(for: record.recordType)
                                .opacity(index == 0 ? 1.0 : (index == 1 ? 0.7 : 0.4))
                                .offset(x: CGFloat(index) * 12)
                                .zIndex(Double(3 - index))
                        }
                    }
                    .frame(width: 48 + 24, alignment: .leading)

                    VStack(alignment: .leading, spacing: RepsTheme.Spacing.xxs) {
                        Text("\(records.count) Personal Records")
                            .font(RepsTheme.Typography.headline)
                            .foregroundStyle(RepsTheme.Colors.text)

                        Text(formatDate(date))
                            .font(RepsTheme.Typography.caption)
                            .foregroundStyle(RepsTheme.Colors.textTertiary)
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(RepsTheme.Colors.textSecondary)
                }
                .padding(RepsTheme.Spacing.md)
            }
            .buttonStyle(.plain)

            // Expanded list
            if isExpanded {
                Divider()
                    .background(RepsTheme.Colors.border)

                VStack(spacing: 0) {
                    ForEach(records) { record in
                        expandedRecordRow(record)

                        if record.id != records.last?.id {
                            Divider()
                                .background(RepsTheme.Colors.border)
                                .padding(.leading, 60)
                        }
                    }
                }
            }
        }
    }

    private func expandedRecordRow(_ record: PersonalRecord) -> some View {
        HStack(spacing: RepsTheme.Spacing.md) {
            trophyIcon(for: record.recordType)
                .scaleEffect(0.8)

            VStack(alignment: .leading, spacing: 2) {
                Text(record.exercise?.name ?? "Unknown")
                    .font(RepsTheme.Typography.subheadline)
                    .foregroundStyle(RepsTheme.Colors.text)
                    .lineLimit(1)

                Text(record.recordType.displayName)
                    .font(RepsTheme.Typography.caption)
                    .foregroundStyle(trophyColor(for: record.recordType))
            }

            Spacer()

            Text(record.formattedValue)
                .font(RepsTheme.Typography.monoSmall)
                .foregroundStyle(RepsTheme.Colors.accent)
        }
        .padding(.horizontal, RepsTheme.Spacing.md)
        .padding(.vertical, RepsTheme.Spacing.sm)
    }

    // MARK: - Helper Views

    private func trophyIcon(for recordType: RecordType) -> some View {
        ZStack {
            Circle()
                .fill(trophyColor(for: recordType).opacity(0.2))
                .frame(width: 44, height: 44)

            Image(systemName: "trophy.fill")
                .font(.system(size: 18))
                .foregroundStyle(trophyColor(for: recordType))
        }
    }

    private func trophyColor(for recordType: RecordType) -> Color {
        switch recordType {
        case .maxWeight: return RepsTheme.Colors.warning
        case .estimated1RM: return RepsTheme.Colors.accent
        case .maxVolume: return RepsTheme.Colors.success
        case .maxReps: return .purple
        case .maxDistance: return .blue
        case .fastestTime: return .green
        }
    }

    private func formatDate(_ date: Date) -> String {
        Self.dateFormatter.string(from: date)
    }
}

#Preview {
    VStack(spacing: 16) {
        // Single record preview would need mock data
        Text("PR Timeline Cards")
            .font(.headline)
    }
    .padding()
    .background(RepsTheme.Colors.background)
    .preferredColorScheme(.dark)
}
