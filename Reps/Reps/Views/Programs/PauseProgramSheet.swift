import SwiftUI
import SwiftData

/// Sheet for pausing a program with return date and resume mode selection
struct PauseProgramSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let program: Program

    @State private var returnDate: Date = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @State private var resumeMode: PauseResumeMode = .continueWhereLeft

    private var minDate: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    }

    private var maxDate: Date {
        Calendar.current.date(byAdding: .day, value: 60, to: Date()) ?? Date()
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker(
                        "Return date",
                        selection: $returnDate,
                        in: minDate...maxDate,
                        displayedComponents: .date
                    )
                } header: {
                    Text("When will you resume?")
                } footer: {
                    Text("Your streak will be preserved during the pause.")
                }

                Section {
                    ForEach(PauseResumeMode.allCases, id: \.self) { mode in
                        ResumeModeRow(
                            mode: mode,
                            isSelected: resumeMode == mode,
                            program: program
                        )
                        .onTapGesture {
                            resumeMode = mode
                        }
                    }
                } header: {
                    Text("When you return")
                }
            }
            .navigationTitle("Pause \(program.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Pause") {
                        pauseProgram()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func pauseProgram() {
        ScheduleService.pauseProgram(program, until: returnDate, resumeMode: resumeMode)

        // Freeze streak if UserStats exists
        let descriptor = FetchDescriptor<UserStats>()
        if let stats = try? modelContext.fetch(descriptor).first {
            stats.freezeStreak()
        }

        dismiss()
    }
}

// MARK: - Resume Mode Row

private struct ResumeModeRow: View {
    let mode: PauseResumeMode
    let isSelected: Bool
    let program: Program

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(mode.title)
                    .font(.subheadline)

                Text(mode.description(for: program))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundStyle(.accent)
            }
        }
        .contentShape(Rectangle())
    }
}

// MARK: - PauseResumeMode Extensions

extension PauseResumeMode {
    var title: String {
        switch self {
        case .continueWhereLeft:
            return "Continue where I left off"
        case .restartCurrentWeek:
            return "Start current week over"
        case .goBackOneWeek:
            return "Go back one week"
        }
    }

    func description(for program: Program) -> String {
        switch self {
        case .continueWhereLeft:
            if let day = program.currentDay?.workoutTemplate?.name {
                return "Resume with \(day)"
            }
            return "Resume from current position"
        case .restartCurrentWeek:
            return "Week \(program.currentWeekIndex + 1), Day 1"
        case .goBackOneWeek:
            let targetWeek = max(1, program.currentWeekIndex)
            return "Week \(targetWeek), Day 1"
        }
    }
}

#Preview {
    Text("Preview")
        .sheet(isPresented: .constant(true)) {
            PauseProgramSheet(program: Program(name: "Push Pull Legs"))
        }
}
