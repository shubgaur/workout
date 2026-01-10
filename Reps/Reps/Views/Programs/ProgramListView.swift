import SwiftUI
import SwiftData

struct ProgramListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Program.name) private var programs: [Program]

    @State private var showingCreateProgram = false
    @State private var showingImportProgram = false
    @State private var programToActivate: Program?
    @State private var programToPause: Program?
    @State private var showingDeleteConfirmation = false
    @State private var programToDelete: Program?

    var body: some View {
        NavigationStack {
            Group {
                if programs.isEmpty {
                    emptyState
                } else {
                    programsList
                }
            }
            .transparentNavigation()
            .safeAreaInset(edge: .top) {
                HStack {
                    GradientTitle(text: "Programs")
                    Spacer()
                    Menu {
                        Button {
                            showingCreateProgram = true
                        } label: {
                            Label("Create Program", systemImage: "plus")
                        }

                        Button {
                            showingImportProgram = true
                        } label: {
                            Label("Import", systemImage: "square.and.arrow.down")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(RepsTheme.Colors.accent)
                    }
                }
                .padding(.horizontal, RepsTheme.Spacing.md)
                .padding(.top, RepsTheme.Spacing.xl)
                .padding(.bottom, RepsTheme.Spacing.sm)
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingCreateProgram) {
                CreateProgramView()
            }
            .sheet(isPresented: $showingImportProgram) {
                ImportView()
            }
            .sheet(item: $programToActivate) { program in
                ProgramActivationSheet(program: program)
            }
            .sheet(item: $programToPause) { program in
                PauseProgramSheet(program: program)
            }
            .alert("Delete Program?", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let program = programToDelete {
                        modelContext.delete(program)
                    }
                }
            } message: {
                Text("This will permanently delete the program and all its data.")
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: RepsTheme.Spacing.lg) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 64))
                .foregroundStyle(RepsTheme.Colors.textTertiary)

            Text("No Programs")
                .font(RepsTheme.Typography.title3)
                .foregroundStyle(RepsTheme.Colors.text)

            Text("Create or import a workout program to get started with structured training")
                .font(RepsTheme.Typography.body)
                .foregroundStyle(RepsTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, RepsTheme.Spacing.xl)

            HStack(spacing: RepsTheme.Spacing.md) {
                Button {
                    showingCreateProgram = true
                } label: {
                    Label("Create", systemImage: "plus")
                }
                .buttonStyle(RepsButtonStyle(style: .primary))

                Button {
                    showingImportProgram = true
                } label: {
                    Label("Import", systemImage: "square.and.arrow.down")
                }
                .buttonStyle(RepsButtonStyle(style: .secondary))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
    }

    private var programsList: some View {
        ScrollView {
            LazyVStack(spacing: RepsTheme.Spacing.sm) {
                ForEach(programs) { program in
                    NavigationLink(destination: ProgramDetailView(program: program)) {
                        ProgramRow(program: program)
                            .padding(RepsTheme.Spacing.md)
                            .repsCard()
                    }
                    .buttonStyle(ScalingPressButtonStyle())
                    .contextMenu {
                        if !program.isActive {
                            Button {
                                programToActivate = program
                            } label: {
                                Label("Start Program", systemImage: "play.fill")
                            }
                        } else {
                            Button {
                                programToPause = program
                            } label: {
                                Label("Pause Program", systemImage: "pause.fill")
                            }

                            Button {
                                ScheduleService.deactivateProgram(program)
                            } label: {
                                Label("Stop Program", systemImage: "stop.fill")
                            }
                        }

                        Divider()

                        Button {
                            duplicateProgram(program)
                        } label: {
                            Label("Duplicate", systemImage: "doc.on.doc")
                        }

                        Divider()

                        Button(role: .destructive) {
                            programToDelete = program
                            showingDeleteConfirmation = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(.horizontal, RepsTheme.Spacing.md)
            .padding(.bottom, 70)
        }
        .scrollContentBackground(.hidden)
        .background(Color.clear)
    }

    private func duplicateProgram(_ program: Program) {
        let newProgram = Program(
            name: "\(program.name) (Copy)",
            programDescription: program.programDescription,
            isActive: false
        )
        modelContext.insert(newProgram)
        // Note: Deep copy of phases/weeks/days would require additional logic
    }

    private func deletePrograms(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(programs[index])
        }
    }
}

// MARK: - Program Row

struct ProgramRow: View {
    let program: Program

    private static let mediumDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    var body: some View {
        HStack(spacing: RepsTheme.Spacing.md) {
            // Program icon
            ZStack {
                RoundedRectangle(cornerRadius: RepsTheme.Radius.sm)
                    .fill(program.isActive ? RepsTheme.Colors.accent.opacity(0.2) : RepsTheme.Colors.surfaceElevated)
                    .frame(width: 48, height: 48)

                Image(systemName: "calendar")
                    .font(.system(size: 20))
                    .foregroundStyle(program.isActive ? RepsTheme.Colors.accent : RepsTheme.Colors.textSecondary)
            }

            VStack(alignment: .leading, spacing: RepsTheme.Spacing.xxs) {
                HStack {
                    Text(program.name)
                        .font(RepsTheme.Typography.headline)
                        .foregroundStyle(RepsTheme.Colors.text)

                    if program.isActive {
                        if program.isPaused {
                            Text("PAUSED")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundStyle(.orange)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.orange.opacity(0.2))
                                )
                        } else {
                            Text("ACTIVE")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundStyle(RepsTheme.Colors.accent)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(RepsTheme.Colors.accent.opacity(0.2))
                                )
                        }
                    }
                }

                if let description = program.programDescription, !description.isEmpty {
                    Text(description)
                        .font(RepsTheme.Typography.caption)
                        .foregroundStyle(RepsTheme.Colors.textSecondary)
                        .lineLimit(1)
                }

                // Phase/Week info or progress
                Text(programSummary)
                    .font(RepsTheme.Typography.caption)
                    .foregroundStyle(RepsTheme.Colors.textTertiary)

                // Show scheduled days if active
                if program.isActive && !program.scheduledDays.isEmpty {
                    Text(ScheduleService.formatScheduledDays(program.scheduledDays))
                        .font(RepsTheme.Typography.caption)
                        .foregroundStyle(RepsTheme.Colors.accent)
                }
            }

            Spacer()

            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(RepsTheme.Colors.textTertiary)
        }
    }

    private var programSummary: String {
        if program.isActive && !program.isPaused {
            return program.progressDescription
        } else if program.isPaused, let until = program.pausedUntil {
            return "Resumes \(Self.mediumDateFormatter.string(from: until))"
        } else {
            let phaseCount = program.phases.count
            let weekCount = program.phases.flatMap { $0.weeks }.count
            return "\(phaseCount) phase\(phaseCount == 1 ? "" : "s") • \(weekCount) week\(weekCount == 1 ? "" : "s")"
        }
    }
}

#Preview {
    ProgramListView()
        .modelContainer(for: Program.self, inMemory: true)
        .preferredColorScheme(.dark)
}
