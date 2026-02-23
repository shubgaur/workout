import SwiftUI
import SwiftData

struct ProgramDetailView: View {
    @Bindable var program: Program
    @Environment(\.modelContext) private var modelContext

    @State private var showingEditProgram = false
    @State private var showingActivationSheet = false
    @State private var activeWorkoutSession: WorkoutSession?
    @State private var showingProgramDetails = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: RepsTheme.Spacing.lg) {
                // Header
                headerSection

                // Program Details (if available)
                if let details = program.programDetails, !details.isEmpty {
                    programDetailsSection(details)
                }

                // Start Program Button
                startProgramButton

                // Phases with inline weeks/days
                if program.sortedPhases.isEmpty {
                    emptyPhasesState
                } else {
                    phasesWithWeeksSection
                }
            }
            .padding(RepsTheme.Spacing.md)
        }
        .navigationTitle(program.name)
        .navigationBarTitleDisplayMode(.large)
        .transparentNavigation()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        toggleActive()
                    } label: {
                        Label(
                            program.isActive ? "Deactivate" : "Set Active",
                            systemImage: program.isActive ? "star.slash" : "star"
                        )
                    }

                    Button {
                        showingEditProgram = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(RepsTheme.Colors.accent)
                }
            }
        }
        .sheet(isPresented: $showingEditProgram) {
            ProgramEditSheet(program: program)
        }
        .sheet(isPresented: $showingActivationSheet) {
            ProgramActivationSheet(program: program)
        }
        .fullScreenCover(item: $activeWorkoutSession) { session in
            ActiveWorkoutView(session: session) {
                activeWorkoutSession = nil
            }
        }
    }

    private var startProgramButton: some View {
        Button {
            showingActivationSheet = true
        } label: {
            HStack {
                Image(systemName: program.isActive ? "arrow.clockwise" : "play.fill")
                Text(program.isActive ? "Change Schedule" : "Start Program")
                    .font(RepsTheme.Typography.subheadline.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(RepsButtonStyle(style: .primary))
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: RepsTheme.Spacing.sm) {
            if program.isActive {
                HStack(spacing: RepsTheme.Spacing.xs) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(RepsTheme.Colors.accent)
                    Text("Active Program")
                        .font(RepsTheme.Typography.caption)
                        .foregroundStyle(RepsTheme.Colors.accent)
                }
            }

            if let description = program.programDescription, !description.isEmpty {
                Text(description)
                    .font(RepsTheme.Typography.body)
                    .foregroundStyle(RepsTheme.Colors.textSecondary)
            }

            // Stats
            HStack(spacing: RepsTheme.Spacing.lg) {
                StatBadge(value: "\(program.phases.count)", label: "Phases")
                StatBadge(value: "\(totalWeeks)", label: "Weeks")
                StatBadge(value: "\(totalWorkouts)", label: "Workouts")
            }
            .padding(.top, RepsTheme.Spacing.xs)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(RepsTheme.Spacing.md)
        .background(RepsTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: RepsTheme.Radius.md)
                .stroke(RepsTheme.Colors.border, lineWidth: 1)
        )
    }

    // MARK: - Program Details

    private func programDetailsSection(_ details: String) -> some View {
        VStack(alignment: .leading, spacing: RepsTheme.Spacing.sm) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showingProgramDetails.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "book.closed")
                        .foregroundStyle(RepsTheme.Colors.accent)
                    Text("Program Details")
                        .font(RepsTheme.Typography.headline)
                        .foregroundStyle(RepsTheme.Colors.text)
                    Spacer()
                    Image(systemName: showingProgramDetails ? "chevron.up" : "chevron.down")
                        .foregroundStyle(RepsTheme.Colors.textTertiary)
                        .font(.system(size: 12))
                }
            }
            .buttonStyle(.plain)

            if showingProgramDetails {
                MarkdownText(details)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(RepsTheme.Spacing.md)
        .background(RepsTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: RepsTheme.Radius.md)
                .stroke(RepsTheme.Colors.border, lineWidth: 1)
        )
    }

    private var phasesSection: some View {
        VStack(alignment: .leading, spacing: RepsTheme.Spacing.sm) {
            Text("PHASES")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(RepsTheme.Colors.textSecondary)
                .padding(.leading, RepsTheme.Spacing.xs)

            ForEach(program.sortedPhases) { phase in
                NavigationLink(destination: PhaseDetailView(phase: phase)) {
                    PhaseRow(phase: phase)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Phases with Inline Weeks/Days

    private var phasesWithWeeksSection: some View {
        VStack(alignment: .leading, spacing: RepsTheme.Spacing.lg) {
            ForEach(program.sortedPhases) { phase in
                phaseSection(phase)
            }
        }
    }

    private func phaseSection(_ phase: Phase) -> some View {
        VStack(alignment: .leading, spacing: RepsTheme.Spacing.sm) {
            // Phase header
            HStack {
                Text(phase.name.uppercased())
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(RepsTheme.Colors.textSecondary)

                Spacer()

                NavigationLink(destination: PhaseDetailView(phase: phase)) {
                    Text("View Phase")
                        .font(RepsTheme.Typography.caption)
                        .foregroundStyle(RepsTheme.Colors.accent)
                }
            }
            .padding(.horizontal, RepsTheme.Spacing.xs)

            // Weeks list
            ForEach(phase.sortedWeeks) { week in
                WeekRowWithDays(week: week, phaseOrder: phase.order)
            }
        }
    }

    private var emptyPhasesState: some View {
        VStack(spacing: RepsTheme.Spacing.md) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 32))
                .foregroundStyle(RepsTheme.Colors.textTertiary)

            Text("No phases yet")
                .font(RepsTheme.Typography.body)
                .foregroundStyle(RepsTheme.Colors.textSecondary)

            Button("Add Phase") {
                addPhase()
            }
            .font(RepsTheme.Typography.caption)
            .foregroundStyle(RepsTheme.Colors.accent)
        }
        .frame(maxWidth: .infinity)
        .padding(RepsTheme.Spacing.xl)
        .background(RepsTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.md))
    }

    private var totalWeeks: Int {
        program.phases.flatMap { $0.weeks }.count
    }

    private var totalWorkouts: Int {
        program.phases
            .flatMap { $0.weeks }
            .flatMap { $0.days }
            .filter { $0.workoutTemplate != nil }
            .count
    }

    private func toggleActive() {
        program.isActive.toggle()
    }

    private func addPhase() {
        let phase = Phase(
            name: "Phase \(program.phases.count + 1)",
            order: program.phases.count
        )
        phase.program = program
        program.phases.append(phase)
    }
}

// MARK: - Stat Badge

struct StatBadge: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: RepsTheme.Spacing.xxs) {
            Text(value)
                .font(RepsTheme.Typography.monoLarge)
                .foregroundStyle(RepsTheme.Colors.accent)
            Text(label)
                .font(RepsTheme.Typography.caption)
                .foregroundStyle(RepsTheme.Colors.textSecondary)
        }
    }
}

// MARK: - Phase Row

struct PhaseRow: View {
    let phase: Phase

    var body: some View {
        HStack(spacing: RepsTheme.Spacing.md) {
            // Phase number
            ZStack {
                Circle()
                    .fill(RepsTheme.Colors.accent.opacity(0.2))
                    .frame(width: 40, height: 40)

                Text("\(phase.order + 1)")
                    .font(RepsTheme.Typography.mono)
                    .foregroundStyle(RepsTheme.Colors.accent)
            }

            VStack(alignment: .leading, spacing: RepsTheme.Spacing.xxs) {
                Text(phase.name)
                    .font(RepsTheme.Typography.headline)
                    .foregroundStyle(RepsTheme.Colors.text)

                Text("\(phase.weeks.count) week\(phase.weeks.count == 1 ? "" : "s")")
                    .font(RepsTheme.Typography.caption)
                    .foregroundStyle(RepsTheme.Colors.textSecondary)

                if let description = phase.phaseDescription, !description.isEmpty {
                    Text(description)
                        .font(RepsTheme.Typography.caption)
                        .foregroundStyle(RepsTheme.Colors.textTertiary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(RepsTheme.Colors.textTertiary)
        }
        .padding(RepsTheme.Spacing.md)
        .background(RepsTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: RepsTheme.Radius.md)
                .stroke(RepsTheme.Colors.border, lineWidth: 1)
        )
    }
}

// MARK: - Week Row with Inline Days

struct WeekRowWithDays: View {
    let week: Week
    let phaseOrder: Int

    var body: some View {
        VStack(alignment: .leading, spacing: RepsTheme.Spacing.sm) {
            // Week header with nav link
            NavigationLink(destination: WeekDetailView(week: week)) {
                HStack {
                    Text("Week \(week.weekNumber)")
                        .font(RepsTheme.Typography.headline)
                        .foregroundStyle(RepsTheme.Colors.text)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundStyle(RepsTheme.Colors.textTertiary)
                }
            }
            .buttonStyle(.plain)

            // Inline day buttons
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: RepsTheme.Spacing.xs) {
                    ForEach(Array(week.sortedDays.enumerated()), id: \.element.id) { index, day in
                        NavigationLink(destination: DayDetailView(day: day)) {
                            DayPill(dayNumber: index + 1, day: day)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(RepsTheme.Spacing.md)
        .background(RepsTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: RepsTheme.Radius.md)
                .stroke(RepsTheme.Colors.border, lineWidth: 1)
        )
    }
}

// MARK: - Day Pill

struct DayPill: View {
    let dayNumber: Int
    let day: ProgramDay

    private var isRestDay: Bool {
        day.dayType == .rest || day.workoutTemplate == nil
    }

    private var displayName: String {
        if isRestDay {
            return "Rest"
        }
        // Prefer day name (e.g. "Day 1") over template name
        let dayName = day.name
        if !dayName.isEmpty && dayName != "Daily Routine" {
            return dayName
        }
        return day.workoutTemplate?.name ?? "Day \(dayNumber)"
    }

    var body: some View {
        VStack(spacing: 2) {
            Text("D\(dayNumber)")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(isRestDay ? RepsTheme.Colors.textTertiary : RepsTheme.Colors.accent)

            Text(displayName)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(isRestDay ? RepsTheme.Colors.textSecondary : RepsTheme.Colors.text)
                .lineLimit(1)
        }
        .padding(.horizontal, RepsTheme.Spacing.sm)
        .padding(.vertical, RepsTheme.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: RepsTheme.Radius.sm)
                .fill(isRestDay ? RepsTheme.Colors.surface : RepsTheme.Colors.accent.opacity(0.15))
        )
        .overlay(
            RoundedRectangle(cornerRadius: RepsTheme.Radius.sm)
                .stroke(isRestDay ? RepsTheme.Colors.border : RepsTheme.Colors.accent.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    NavigationStack {
        ProgramDetailView(program: Program(
            name: "Fat Don't Fly",
            programDescription: "12-week strength and conditioning program"
        ))
    }
    .preferredColorScheme(.dark)
}
