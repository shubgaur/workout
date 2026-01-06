import SwiftUI
import SwiftData

struct CreateProgramView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var description = ""
    @State private var numberOfPhases = 1
    @State private var weeksPerPhase = 4
    @State private var daysPerWeek = 5

    var body: some View {
        NavigationStack {
            Form {
                // Basic Info
                Section {
                    TextField("Program Name", text: $name)
                        .font(RepsTheme.Typography.body)

                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .font(RepsTheme.Typography.body)
                        .lineLimit(3...5)
                } header: {
                    Text("Basic Info")
                }

                // Structure
                Section {
                    Stepper("Phases: \(numberOfPhases)", value: $numberOfPhases, in: 1...12)
                    Stepper("Weeks per Phase: \(weeksPerPhase)", value: $weeksPerPhase, in: 1...12)
                    Stepper("Days per Week: \(daysPerWeek)", value: $daysPerWeek, in: 1...7)
                } header: {
                    Text("Structure")
                } footer: {
                    Text("Total: \(numberOfPhases * weeksPerPhase) weeks, \(numberOfPhases * weeksPerPhase * daysPerWeek) workout days")
                        .font(RepsTheme.Typography.caption)
                }

                // Preview
                Section {
                    VStack(alignment: .leading, spacing: RepsTheme.Spacing.sm) {
                        ForEach(1...min(numberOfPhases, 3), id: \.self) { phaseNum in
                            HStack {
                                Circle()
                                    .fill(RepsTheme.Colors.accent)
                                    .frame(width: 8, height: 8)
                                Text("Phase \(phaseNum)")
                                    .font(RepsTheme.Typography.body)
                                Spacer()
                                Text("\(weeksPerPhase) weeks")
                                    .font(RepsTheme.Typography.caption)
                                    .foregroundStyle(RepsTheme.Colors.textSecondary)
                            }
                        }
                        if numberOfPhases > 3 {
                            Text("+ \(numberOfPhases - 3) more phases...")
                                .font(RepsTheme.Typography.caption)
                                .foregroundStyle(RepsTheme.Colors.textTertiary)
                        }
                    }
                } header: {
                    Text("Preview")
                }
            }
            .scrollContentBackground(.hidden)
            .background(RepsTheme.Colors.background)
            .navigationTitle("Create Program")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(RepsTheme.Colors.textSecondary)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Create") {
                        createProgram()
                    }
                    .disabled(name.isEmpty)
                    .foregroundStyle(name.isEmpty ? RepsTheme.Colors.textTertiary : RepsTheme.Colors.accent)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func createProgram() {
        let program = Program(
            name: name,
            programDescription: description.isEmpty ? nil : description
        )
        modelContext.insert(program)

        // Create phases
        for phaseNum in 0..<numberOfPhases {
            let phase = Phase(
                name: "Phase \(phaseNum + 1)",
                order: phaseNum
            )
            phase.program = program

            // Create weeks
            for weekNum in 1...weeksPerPhase {
                let week = Week(weekNumber: weekNum)
                week.phase = phase

                // Create days
                for dayNum in 1...daysPerWeek {
                    let day = ProgramDay(
                        dayNumber: dayNum,
                        name: "Day \(dayNum)",
                        dayType: .training
                    )
                    day.week = week
                    week.days.append(day)
                }

                phase.weeks.append(week)
            }

            program.phases.append(phase)
        }

        dismiss()
    }
}

#Preview {
    CreateProgramView()
        .modelContainer(for: Program.self, inMemory: true)
        .preferredColorScheme(.dark)
}
