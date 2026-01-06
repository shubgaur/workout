import SwiftUI
import SwiftData

struct PersonalRecordsView: View {
    @Query(sort: \PersonalRecord.achievedAt, order: .reverse) private var records: [PersonalRecord]

    @State private var filterType: RecordType?

    var body: some View {
        Group {
            if records.isEmpty {
                emptyState
            } else {
                recordsList
            }
        }
        .navigationTitle("Personal Records")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var emptyState: some View {
        VStack(spacing: RepsTheme.Spacing.lg) {
            Spacer()

            Image(systemName: "trophy.fill")
                .font(.system(size: 64))
                .foregroundStyle(RepsTheme.Colors.warning.opacity(0.5))

            Text("No Records Yet")
                .font(RepsTheme.Typography.headline)
                .foregroundStyle(RepsTheme.Colors.text)

            Text("Set your first PR by completing a workout")
                .font(RepsTheme.Typography.body)
                .foregroundStyle(RepsTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(RepsTheme.Spacing.xl)
    }

    private var recordsList: some View {
        ScrollView {
            VStack(spacing: RepsTheme.Spacing.md) {
                // Filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: RepsTheme.Spacing.sm) {
                        FilterChip(
                            title: "All",
                            isSelected: filterType == nil
                        ) {
                            filterType = nil
                        }

                        ForEach(RecordType.allCases, id: \.self) { type in
                            FilterChip(
                                title: type.displayName,
                                isSelected: filterType == type
                            ) {
                                filterType = type
                            }
                        }
                    }
                }

                // Records list
                ForEach(filteredRecords) { record in
                    PersonalRecordCell(record: record)
                }
            }
            .padding(RepsTheme.Spacing.md)
        }
        .background(RepsTheme.Colors.background)
    }

    private var filteredRecords: [PersonalRecord] {
        if let filterType = filterType {
            return records.filter { $0.recordType == filterType }
        }
        return records
    }
}

// MARK: - Personal Record Cell

struct PersonalRecordCell: View {
    let record: PersonalRecord

    var body: some View {
        HStack(spacing: RepsTheme.Spacing.md) {
            // Trophy icon
            ZStack {
                Circle()
                    .fill(trophyColor.opacity(0.2))
                    .frame(width: 48, height: 48)

                Image(systemName: "trophy.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(trophyColor)
            }

            // Details
            VStack(alignment: .leading, spacing: RepsTheme.Spacing.xxs) {
                Text(record.exercise?.name ?? "Unknown Exercise")
                    .font(RepsTheme.Typography.headline)
                    .foregroundStyle(RepsTheme.Colors.text)

                HStack(spacing: RepsTheme.Spacing.sm) {
                    Text(record.recordType.displayName)
                        .font(RepsTheme.Typography.caption)
                        .foregroundStyle(RepsTheme.Colors.accent)

                    Text(formatDate(record.achievedAt))
                        .font(RepsTheme.Typography.caption)
                        .foregroundStyle(RepsTheme.Colors.textTertiary)
                }
            }

            Spacer()

            // Value
            Text(formatValue(record))
                .font(RepsTheme.Typography.title)
                .foregroundStyle(RepsTheme.Colors.text)
        }
        .padding(RepsTheme.Spacing.md)
        .background(RepsTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.md))
    }

    private var trophyColor: Color {
        switch record.recordType {
        case .maxWeight: return RepsTheme.Colors.warning
        case .estimated1RM: return RepsTheme.Colors.accent
        case .maxVolume: return RepsTheme.Colors.success
        case .maxReps: return .purple
        case .maxDistance: return .blue
        case .fastestTime: return .green
        }
    }

    private func formatValue(_ record: PersonalRecord) -> String {
        switch record.recordType {
        case .maxWeight, .estimated1RM, .maxVolume:
            return "\(Int(record.value)) kg"
        case .maxReps:
            return "\(Int(record.value))"
        case .maxDistance:
            return record.value >= 1000 ? String(format: "%.1f km", record.value / 1000) : "\(Int(record.value)) m"
        case .fastestTime:
            let mins = Int(record.value) / 60
            let secs = Int(record.value) % 60
            return mins > 0 ? "\(mins):\(String(format: "%02d", secs))" : "\(secs)s"
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Recent PRs Section (for Profile)

struct RecentPRsSection: View {
    @Query(sort: \PersonalRecord.achievedAt, order: .reverse) private var records: [PersonalRecord]

    var body: some View {
        VStack(alignment: .leading, spacing: RepsTheme.Spacing.md) {
            HStack {
                Text("RECENT PRs")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(RepsTheme.Colors.textSecondary)

                Spacer()

                NavigationLink {
                    PersonalRecordsView()
                } label: {
                    Text("See All")
                        .font(RepsTheme.Typography.caption)
                        .foregroundStyle(RepsTheme.Colors.accent)
                }
            }

            if records.isEmpty {
                Text("No records yet")
                    .font(RepsTheme.Typography.body)
                    .foregroundStyle(RepsTheme.Colors.textSecondary)
                    .padding(RepsTheme.Spacing.md)
                    .frame(maxWidth: .infinity)
                    .background(RepsTheme.Colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.md))
            } else {
                ForEach(Array(records.prefix(3))) { record in
                    MiniPRCell(record: record)
                }
            }
        }
    }
}

// MARK: - Mini PR Cell

struct MiniPRCell: View {
    let record: PersonalRecord

    var body: some View {
        HStack(spacing: RepsTheme.Spacing.sm) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 14))
                .foregroundStyle(RepsTheme.Colors.warning)

            Text(record.exercise?.name ?? "Unknown")
                .font(RepsTheme.Typography.body)
                .foregroundStyle(RepsTheme.Colors.text)
                .lineLimit(1)

            Spacer()

            Text(formatValue(record))
                .font(RepsTheme.Typography.mono)
                .foregroundStyle(RepsTheme.Colors.accent)
        }
        .padding(RepsTheme.Spacing.sm)
        .background(RepsTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.sm))
    }

    private func formatValue(_ record: PersonalRecord) -> String {
        switch record.recordType {
        case .maxWeight, .estimated1RM, .maxVolume:
            return "\(Int(record.value)) kg"
        case .maxReps:
            return "\(Int(record.value)) reps"
        case .maxDistance:
            return record.value >= 1000 ? String(format: "%.1f km", record.value / 1000) : "\(Int(record.value)) m"
        case .fastestTime:
            let mins = Int(record.value) / 60
            let secs = Int(record.value) % 60
            return mins > 0 ? "\(mins):\(String(format: "%02d", secs))" : "\(secs)s"
        }
    }
}
