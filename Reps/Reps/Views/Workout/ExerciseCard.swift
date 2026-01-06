import SwiftUI
import SwiftData

struct ExerciseCard: View {
    @Bindable var exercise: WorkoutExercise
    var onSetCompleted: (LoggedSet) -> Void

    @State private var exerciseNotes = ""
    @State private var showingNotes = false

    var body: some View {
        VStack(spacing: 0) {
            // Exercise header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: RepsTheme.Spacing.xxs) {
                    Text(exercise.exercise?.name ?? "Unknown Exercise")
                        .font(RepsTheme.Typography.headline)
                        .foregroundStyle(RepsTheme.Colors.text)

                    if let muscleGroups = exercise.exercise?.muscleGroups, !muscleGroups.isEmpty {
                        Text(muscleGroups.map { $0.displayName }.joined(separator: ", "))
                            .font(RepsTheme.Typography.caption)
                            .foregroundStyle(RepsTheme.Colors.textSecondary)
                    }
                }

                Spacer()

                Menu {
                    Button {
                        showingNotes.toggle()
                    } label: {
                        Label("Notes", systemImage: "note.text")
                    }

                    Button(role: .destructive) {
                        // TODO: Remove exercise
                    } label: {
                        Label("Remove", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 18))
                        .foregroundStyle(RepsTheme.Colors.textSecondary)
                        .frame(width: 44, height: 44)
                }
            }
            .padding(.horizontal, RepsTheme.Spacing.md)
            .padding(.top, RepsTheme.Spacing.md)

            // Notes field (expandable)
            if showingNotes || !exerciseNotes.isEmpty {
                TextField("Add notes...", text: $exerciseNotes, axis: .vertical)
                    .font(RepsTheme.Typography.body)
                    .foregroundStyle(RepsTheme.Colors.text)
                    .padding(RepsTheme.Spacing.sm)
                    .background(RepsTheme.Colors.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.sm))
                    .padding(.horizontal, RepsTheme.Spacing.md)
                    .padding(.top, RepsTheme.Spacing.sm)
                    .onChange(of: exerciseNotes) { _, newValue in
                        exercise.notes = newValue.isEmpty ? nil : newValue
                    }
            }

            // Set table header
            HStack(spacing: 0) {
                Text("SET")
                    .frame(width: Constants.Layout.setColumnWidth, alignment: .leading)
                Text("PREVIOUS")
                    .frame(width: Constants.Layout.previousColumnWidth, alignment: .center)
                Text("KG")
                    .frame(maxWidth: .infinity)
                Text("REPS")
                    .frame(maxWidth: .infinity)
                Text("")
                    .frame(width: Constants.Layout.checkButtonSize)
            }
            .font(.system(size: 11, weight: .bold, design: .monospaced))
            .foregroundStyle(RepsTheme.Colors.textTertiary)
            .padding(.horizontal, RepsTheme.Spacing.md)
            .padding(.top, RepsTheme.Spacing.md)
            .padding(.bottom, RepsTheme.Spacing.xs)

            // Set rows
            ForEach(exercise.sortedLoggedSets) { loggedSet in
                SetRowView(
                    loggedSet: loggedSet,
                    allSets: exercise.sortedLoggedSets,
                    onCompleted: {
                        onSetCompleted(loggedSet)
                    }
                )
            }

            // Add set button
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                addSet()
            } label: {
                HStack {
                    Image(systemName: "plus")
                    Text("Add Set")
                }
                .font(RepsTheme.Typography.subheadline)
                .foregroundStyle(RepsTheme.Colors.accent)
            }
            .buttonStyle(CardButtonStyle())
            .padding(RepsTheme.Spacing.md)
        }
        .background(RepsTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.md))
        .padding(.horizontal, RepsTheme.Spacing.md)
        .padding(.vertical, RepsTheme.Spacing.xs)
        .onAppear {
            exerciseNotes = exercise.notes ?? ""
        }
    }

    private func addSet() {
        let newSetNumber = (exercise.loggedSets.map { $0.setNumber }.max() ?? 0) + 1
        let set = LoggedSet(setNumber: newSetNumber)
        set.workoutExercise = exercise
        exercise.loggedSets.append(set)
    }
}

// MARK: - Set Row View

struct SetRowView: View {
    @Bindable var loggedSet: LoggedSet
    var allSets: [LoggedSet]
    var onCompleted: () -> Void

    @FocusState private var weightFocused: Bool
    @FocusState private var repsFocused: Bool

    @State private var weightText = ""
    @State private var repsText = ""
    @State private var showingPropagateAlert = false
    @State private var pendingPropagation: PropagationType?

    private enum PropagationType {
        case weight(Double)
        case reps(Int)
    }

    private var isFirstSet: Bool {
        loggedSet.setNumber == 1
    }

    private var remainingSets: [LoggedSet] {
        allSets.filter { $0.setNumber > loggedSet.setNumber && !$0.isCompleted }
    }

    var body: some View {
        HStack(spacing: 0) {
            // Set indicator
            setIndicator
                .frame(width: Constants.Layout.setColumnWidth, alignment: .leading)

            // Previous (from last workout)
            Text(previousText)
                .font(RepsTheme.Typography.mono)
                .foregroundStyle(RepsTheme.Colors.textTertiary)
                .frame(width: Constants.Layout.previousColumnWidth, alignment: .center)

            // Weight input
            TextField("—", text: $weightText)
                .keyboardType(.decimalPad)
                .font(RepsTheme.Typography.mono)
                .foregroundStyle(RepsTheme.Colors.text)
                .multilineTextAlignment(.center)
                .padding(RepsTheme.Spacing.sm)
                .background(RepsTheme.Colors.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.sm))
                .focused($weightFocused)
                .frame(maxWidth: .infinity)
                .onChange(of: weightText) { _, newValue in
                    if let weight = Double(newValue) {
                        loggedSet.weight = weight
                        if isFirstSet && !remainingSets.isEmpty {
                            pendingPropagation = .weight(weight)
                            showingPropagateAlert = true
                        }
                    } else {
                        loggedSet.weight = nil
                    }
                }

            Spacer().frame(width: RepsTheme.Spacing.xs)

            // Reps input
            TextField("—", text: $repsText)
                .keyboardType(.numberPad)
                .font(RepsTheme.Typography.mono)
                .foregroundStyle(RepsTheme.Colors.text)
                .multilineTextAlignment(.center)
                .padding(RepsTheme.Spacing.sm)
                .background(RepsTheme.Colors.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.sm))
                .focused($repsFocused)
                .frame(maxWidth: .infinity)
                .onChange(of: repsText) { _, newValue in
                    if let reps = Int(newValue) {
                        loggedSet.reps = reps
                        if isFirstSet && !remainingSets.isEmpty {
                            pendingPropagation = .reps(reps)
                            showingPropagateAlert = true
                        }
                    } else {
                        loggedSet.reps = nil
                    }
                }

            // Complete button
            Button {
                toggleCompleted()
            } label: {
                Image(systemName: loggedSet.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 28))
                    .foregroundStyle(loggedSet.isCompleted ? RepsTheme.Colors.success : RepsTheme.Colors.textTertiary)
            }
            .frame(width: Constants.Layout.checkButtonSize)
        }
        .padding(.horizontal, RepsTheme.Spacing.md)
        .padding(.vertical, RepsTheme.Spacing.xs)
        .background(loggedSet.isCompleted ? RepsTheme.Colors.success.opacity(0.1) : Color.clear)
        .onAppear {
            if let weight = loggedSet.weight {
                weightText = weight.formatted(.number.precision(.fractionLength(0...1)))
            }
            if let reps = loggedSet.reps {
                repsText = "\(reps)"
            }
        }
        .alert("Apply to All Sets?", isPresented: $showingPropagateAlert) {
            Button("Just This Set", role: .cancel) {
                pendingPropagation = nil
            }
            Button("Apply to All") {
                propagateValues()
            }
        } message: {
            Text("Apply this value to remaining sets?")
        }
    }

    private func propagateValues() {
        guard let propagation = pendingPropagation else { return }

        switch propagation {
        case .weight(let weight):
            for otherSet in remainingSets {
                otherSet.weight = weight
            }
        case .reps(let reps):
            for otherSet in remainingSets {
                otherSet.reps = reps
            }
        }

        pendingPropagation = nil
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    private var setIndicator: some View {
        Group {
            switch loggedSet.setType {
            case .warmup:
                Text("W")
                    .font(RepsTheme.Typography.mono)
                    .foregroundStyle(RepsTheme.Colors.warning)
            case .working:
                Text("\(loggedSet.setNumber)")
                    .font(RepsTheme.Typography.mono)
                    .foregroundStyle(RepsTheme.Colors.text)
            case .dropset:
                Text("D")
                    .font(RepsTheme.Typography.mono)
                    .foregroundStyle(RepsTheme.Colors.error)
            case .failure:
                Text("F")
                    .font(RepsTheme.Typography.mono)
                    .foregroundStyle(RepsTheme.Colors.error)
            case .amrap:
                Text("A")
                    .font(RepsTheme.Typography.mono)
                    .foregroundStyle(RepsTheme.Colors.accent)
            case .restPause:
                Text("R")
                    .font(RepsTheme.Typography.mono)
                    .foregroundStyle(RepsTheme.Colors.accent)
            }
        }
    }

    private var previousText: String {
        if let prevReps = loggedSet.previousReps, let prevWeight = loggedSet.previousWeight {
            return "\(Int(prevWeight))x\(prevReps)"
        }
        return "—"
    }

    private func toggleCompleted() {
        loggedSet.isCompleted.toggle()
        if loggedSet.isCompleted {
            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred()
            onCompleted()
        } else {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
}

// MARK: - Card Button Style

struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
