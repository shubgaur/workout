import SwiftUI
import SwiftData

struct PersonalRecordsView: View {
    @Query(sort: \PersonalRecord.achievedAt, order: .reverse) private var records: [PersonalRecord]
    @Environment(\.modelContext) private var modelContext

    @State private var filterType: RecordType?
    @State private var recordToDelete: PersonalRecord?

    private var groupedRecords: [(title: String, records: [PersonalRecord])] {
        let filtered = filterType == nil ? records : records.filter { $0.recordType == filterType }
        return groupRecordsByTimeframe(filtered)
    }

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
        .transparentNavigation()
        .alert("Delete Record?", isPresented: Binding(
            get: { recordToDelete != nil },
            set: { if !$0 { recordToDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) {
                recordToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let record = recordToDelete {
                    modelContext.delete(record)
                    recordToDelete = nil
                }
            }
        } message: {
            Text("This will permanently delete this personal record.")
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: RepsTheme.Spacing.lg) {
            Spacer()

            ZStack {
                Circle()
                    .fill(RepsTheme.Colors.warning.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: "trophy.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(RepsTheme.Colors.warning.opacity(0.5))
            }

            Text("No Records Yet")
                .font(RepsTheme.Typography.title)
                .foregroundStyle(RepsTheme.Colors.text)

            Text("Set your first PR by completing a workout")
                .font(RepsTheme.Typography.body)
                .foregroundStyle(RepsTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(RepsTheme.Spacing.xl)
    }

    // MARK: - Records List

    private var recordsList: some View {
        ScrollView {
            VStack(spacing: RepsTheme.Spacing.lg) {
                // Filter chips
                filterRow

                // Grouped records
                ForEach(groupedRecords, id: \.title) { group in
                    VStack(alignment: .leading, spacing: RepsTheme.Spacing.sm) {
                        // Section header
                        Text(group.title.uppercased())
                            .font(RepsTheme.Typography.label)
                            .foregroundStyle(RepsTheme.Colors.textSecondary)
                            .padding(.horizontal, RepsTheme.Spacing.xs)

                        // Records
                        VStack(spacing: RepsTheme.Spacing.xs) {
                            ForEach(group.records) { record in
                                PRActivityCard(record: record)
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            recordToDelete = record
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                    }
                }
            }
            .padding(RepsTheme.Spacing.md)
        }
    }

    // MARK: - Filter Row

    private var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: RepsTheme.Spacing.xs) {
                ADFilterChip(
                    label: "All",
                    isSelected: filterType == nil
                ) {
                    withAnimation(RepsTheme.Animations.segment) {
                        filterType = nil
                    }
                    HapticManager.filterSelected()
                }

                ForEach(RecordType.allCases, id: \.self) { type in
                    ADFilterChip(
                        label: type.shortName,
                        isSelected: filterType == type
                    ) {
                        withAnimation(RepsTheme.Animations.segment) {
                            filterType = type
                        }
                        HapticManager.filterSelected()
                    }
                }
            }
            .padding(.horizontal, RepsTheme.Spacing.xs)
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 5)
                .onChanged { _ in }
        )
    }

    // MARK: - Grouping

    private func groupRecordsByTimeframe(_ records: [PersonalRecord]) -> [(title: String, records: [PersonalRecord])] {
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)

        var groups: [String: [PersonalRecord]] = [:]
        let orderedTitles = ["Today", "Yesterday", "This Week", "This Month", "Earlier"]

        for title in orderedTitles {
            groups[title] = []
        }

        for record in records {
            let recordDate = calendar.startOfDay(for: record.achievedAt)

            if calendar.isDateInToday(record.achievedAt) {
                groups["Today"]?.append(record)
            } else if calendar.isDateInYesterday(record.achievedAt) {
                groups["Yesterday"]?.append(record)
            } else if let weekAgo = calendar.date(byAdding: .day, value: -7, to: today),
                      recordDate >= weekAgo {
                groups["This Week"]?.append(record)
            } else if let monthAgo = calendar.date(byAdding: .month, value: -1, to: today),
                      recordDate >= monthAgo {
                groups["This Month"]?.append(record)
            } else {
                groups["Earlier"]?.append(record)
            }
        }

        return orderedTitles.compactMap { title in
            guard let records = groups[title], !records.isEmpty else { return nil }
            return (title: title, records: records)
        }
    }
}

// MARK: - PR Activity Card

struct PRActivityCard: View {
    let record: PersonalRecord

    var body: some View {
        HStack(spacing: RepsTheme.Spacing.md) {
            // Trophy icon with color-coded background
            ZStack {
                RoundedRectangle(cornerRadius: RepsTheme.Radius.sm)
                    .fill(trophyColor.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: "trophy.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(trophyColor)
            }

            // Details
            VStack(alignment: .leading, spacing: 2) {
                Text(record.exercise?.name ?? "Unknown Exercise")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(RepsTheme.Colors.text)
                    .lineLimit(1)

                HStack(spacing: RepsTheme.Spacing.xs) {
                    Text(record.recordType.shortName)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(RepsTheme.Colors.accent)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(RepsTheme.Colors.accent.opacity(0.15))
                        )

                    Text(formatRelativeDate(record.achievedAt))
                        .font(.system(size: 12))
                        .foregroundStyle(RepsTheme.Colors.textTertiary)
                }
            }

            Spacer()

            // Value display
            VStack(alignment: .trailing, spacing: 0) {
                Text(formatValue(record))
                    .font(RepsTheme.Typography.metricMedium)
                    .foregroundStyle(RepsTheme.Colors.text)

                Text(record.recordType.unit)
                    .font(RepsTheme.Typography.label)
                    .foregroundStyle(RepsTheme.Colors.textSecondary)
            }
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
        case .maxWeight, .estimated1RM:
            return formatWeight(record.value)
        case .maxVolume:
            if record.value >= 1000 {
                return String(format: "%.1fK", record.value / 1000)
            }
            return "\(Int(record.value))"
        case .maxReps:
            return "\(Int(record.value))"
        case .maxDistance:
            return record.value >= 1000 ? String(format: "%.1f", record.value / 1000) : "\(Int(record.value))"
        case .fastestTime:
            let mins = Int(record.value) / 60
            let secs = Int(record.value) % 60
            return mins > 0 ? "\(mins):\(String(format: "%02d", secs))" : "\(secs)"
        }
    }

    private func formatWeight(_ weight: Double) -> String {
        if weight.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", weight)
        }
        return String(format: "%.1f", weight)
    }

    private func formatRelativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - RecordType Extension

extension RecordType {
    var shortName: String {
        switch self {
        case .maxWeight: return "Max"
        case .estimated1RM: return "1RM"
        case .maxVolume: return "Vol"
        case .maxReps: return "Reps"
        case .maxDistance: return "Dist"
        case .fastestTime: return "Time"
        }
    }

    var unit: String {
        switch self {
        case .maxWeight, .estimated1RM: return "lbs"
        case .maxVolume: return "lbs"
        case .maxReps: return "reps"
        case .maxDistance: return "mi"
        case .fastestTime: return "s"
        }
    }
}

// MARK: - Recent PRs Section (for Profile)

struct RecentPRsSection: View {
    @Query(sort: \PersonalRecord.achievedAt, order: .reverse) private var records: [PersonalRecord]

    var body: some View {
        VStack(alignment: .leading, spacing: RepsTheme.Spacing.sm) {
            HStack {
                Text("RECENT PRS")
                    .font(RepsTheme.Typography.label)
                    .foregroundStyle(RepsTheme.Colors.textSecondary)

                Spacer()

                NavigationLink {
                    PersonalRecordsView()
                } label: {
                    HStack(spacing: 4) {
                        Text("See All")
                            .font(.system(size: 12, weight: .medium))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(RepsTheme.Colors.accent)
                }
                .buttonStyle(ScalingPressButtonStyle())
            }
            .padding(.horizontal, RepsTheme.Spacing.xs)

            if records.isEmpty {
                HStack {
                    Spacer()
                    Text("Complete workouts to set PRs")
                        .font(RepsTheme.Typography.body)
                        .foregroundStyle(RepsTheme.Colors.textSecondary)
                    Spacer()
                }
                .padding(RepsTheme.Spacing.lg)
                .background(RepsTheme.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.md))
            } else {
                VStack(spacing: RepsTheme.Spacing.xs) {
                    ForEach(Array(records.prefix(3))) { record in
                        MiniPRCell(record: record)
                    }
                }
            }
        }
    }
}

// MARK: - Mini PR Cell

struct MiniPRCell: View {
    let record: PersonalRecord

    var body: some View {
        HStack(spacing: RepsTheme.Spacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(RepsTheme.Colors.warning.opacity(0.15))
                    .frame(width: 32, height: 32)

                Image(systemName: "trophy.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(RepsTheme.Colors.warning)
            }

            // Name
            Text(record.exercise?.name ?? "Unknown")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(RepsTheme.Colors.text)
                .lineLimit(1)

            Spacer()

            // Value
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(formatValue(record))
                    .font(RepsTheme.Typography.mono)
                    .foregroundStyle(RepsTheme.Colors.accent)

                Text(record.recordType.unit)
                    .font(.system(size: 10))
                    .foregroundStyle(RepsTheme.Colors.textSecondary)
            }
        }
        .padding(.horizontal, RepsTheme.Spacing.md)
        .padding(.vertical, RepsTheme.Spacing.sm)
        .background(RepsTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.sm))
    }

    private func formatValue(_ record: PersonalRecord) -> String {
        switch record.recordType {
        case .maxWeight, .estimated1RM, .maxVolume:
            return "\(Int(record.value))"
        case .maxReps:
            return "\(Int(record.value))"
        case .maxDistance:
            return record.value >= 1000 ? String(format: "%.1f", record.value / 1000) : "\(Int(record.value))"
        case .fastestTime:
            let mins = Int(record.value) / 60
            let secs = Int(record.value) % 60
            return mins > 0 ? "\(mins):\(String(format: "%02d", secs))" : "\(secs)"
        }
    }
}

