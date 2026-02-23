import SwiftUI
import SwiftData
import AVFoundation

struct ExerciseCard: View {
    @Bindable var exercise: WorkoutExercise
    var onSetCompleted: (LoggedSet) -> Void

    @Query private var allSettings: [UserSettings]
    @State private var exerciseNotes = ""
    @State private var showingNotes = false

    private var weightLabel: String {
        allSettings.first?.weightUnit.displayName.uppercased() ?? "LBS"
    }

    // Flexible column detection
    private var hasTimeColumn: Bool {
        exercise.sortedLoggedSets.contains { $0.time != nil }
    }

    private var hasWeightColumn: Bool {
        exercise.sortedLoggedSets.contains { $0.weight != nil } ||
        !exercise.sortedLoggedSets.contains { $0.time != nil }
    }

    private var hasRepsColumn: Bool {
        exercise.sortedLoggedSets.contains { $0.reps != nil } ||
        !exercise.sortedLoggedSets.contains { $0.time != nil }
    }

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

            // Inline video player
            if let videoURL = exercise.exercise?.effectiveVideoURL {
                InlineVideoPlayer(url: videoURL)
                    .frame(height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.sm))
                    .padding(.horizontal, RepsTheme.Spacing.md)
                    .padding(.top, RepsTheme.Spacing.sm)
            }

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

            // Set table header - flexible columns
            HStack(spacing: 0) {
                Text("SET")
                    .frame(width: Constants.Layout.setColumnWidth, alignment: .leading)
                Text("PREVIOUS")
                    .frame(width: Constants.Layout.previousColumnWidth, alignment: .center)
                if hasTimeColumn {
                    Text("TIME")
                        .frame(maxWidth: .infinity)
                }
                if hasWeightColumn {
                    Text(weightLabel)
                        .frame(maxWidth: .infinity)
                }
                if hasRepsColumn {
                    Text("REPS")
                        .frame(maxWidth: .infinity)
                }
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
                    hasTimeColumn: hasTimeColumn,
                    hasWeightColumn: hasWeightColumn,
                    hasRepsColumn: hasRepsColumn,
                    weightLabel: weightLabel,
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
        let lastSet = exercise.sortedLoggedSets.last
        let hasSides = exercise.loggedSets.contains { $0.side != nil }

        if hasSides {
            // Add L/R pair
            let leftSet = LoggedSet(setNumber: newSetNumber)
            leftSet.side = .left
            leftSet.reps = lastSet?.reps
            leftSet.weight = lastSet?.weight
            leftSet.time = lastSet?.time
            leftSet.workoutExercise = exercise
            exercise.loggedSets.append(leftSet)

            let rightSet = LoggedSet(setNumber: newSetNumber)
            rightSet.side = .right
            rightSet.reps = lastSet?.reps
            rightSet.weight = lastSet?.weight
            rightSet.time = lastSet?.time
            rightSet.workoutExercise = exercise
            exercise.loggedSets.append(rightSet)
        } else {
            let set = LoggedSet(setNumber: newSetNumber)
            if let lastSet = lastSet {
                set.reps = lastSet.reps
                set.weight = lastSet.weight
                set.time = lastSet.time
            }
            set.workoutExercise = exercise
            exercise.loggedSets.append(set)
        }
    }
}

// MARK: - Set Row View

struct SetRowView: View {
    @Bindable var loggedSet: LoggedSet
    var allSets: [LoggedSet]
    var hasTimeColumn: Bool
    var hasWeightColumn: Bool
    var hasRepsColumn: Bool
    var weightLabel: String
    var onCompleted: () -> Void

    @FocusState private var weightFocused: Bool
    @FocusState private var repsFocused: Bool

    @State private var weightText = ""
    @State private var repsText = ""
    @State private var showingTimePicker = false
    @State private var showingPropagateAlert = false
    @State private var pendingPropagation: PropagationType?
    @State private var hasAppeared = false

    // Timer state
    @State private var timerActive = false
    @State private var timerRemaining: Int = 0
    @State private var countdownTimer: Timer?

    private enum PropagationType {
        case weight(Double)
        case reps(Int)
        case time(Int)
    }

    private var isFirstSet: Bool {
        loggedSet.setNumber == 1 && loggedSet.side != .right
    }

    private var remainingSets: [LoggedSet] {
        allSets.filter { $0.setNumber > loggedSet.setNumber && !$0.isCompleted }
    }

    var body: some View {
        HStack(spacing: 0) {
            // Set indicator with side
            setIndicator
                .frame(width: Constants.Layout.setColumnWidth, alignment: .leading)

            // Previous (from last workout)
            Text(previousText)
                .font(RepsTheme.Typography.mono)
                .foregroundStyle(RepsTheme.Colors.textTertiary)
                .frame(width: Constants.Layout.previousColumnWidth, alignment: .center)

            if hasTimeColumn {
                timeCell
            }

            if hasWeightColumn {
                weightCell
            }

            if hasRepsColumn {
                repsCell
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
            DispatchQueue.main.async {
                hasAppeared = true
            }
        }
        .onDisappear {
            stopCountdownTimer()
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
        .sheet(isPresented: $showingTimePicker) {
            TimePickerSheet(seconds: Binding(
                get: { loggedSet.time ?? 0 },
                set: { newValue in
                    loggedSet.time = newValue > 0 ? newValue : nil
                    if hasAppeared && isFirstSet && !remainingSets.isEmpty && newValue > 0 {
                        pendingPropagation = .time(newValue)
                        showingPropagateAlert = true
                    }
                }
            ))
            .presentationDetents([.height(280)])
        }
    }

    // MARK: - Time Cell with Countdown Timer

    private var timeCell: some View {
        HStack(spacing: 2) {
            // Time display - tappable to set time
            Button { showingTimePicker = true } label: {
                Text(timerActive ? formatTime(timerRemaining) : (loggedSet.time.map { formatTime($0) } ?? "---"))
                    .font(RepsTheme.Typography.mono)
                    .foregroundStyle(
                        timerActive ? RepsTheme.Colors.accent :
                        (loggedSet.time != nil ? RepsTheme.Colors.text : RepsTheme.Colors.textTertiary)
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, RepsTheme.Spacing.sm)
                    .background(RepsTheme.Colors.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.sm))
            }
            .buttonStyle(.plain)

            // Timer play/pause button
            if loggedSet.time != nil {
                Button {
                    toggleCountdownTimer()
                } label: {
                    Image(systemName: timerActive ? "pause.fill" : "play.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(timerActive ? RepsTheme.Colors.warning : RepsTheme.Colors.accent)
                        .frame(width: 28, height: 28)
                        .background(
                            (timerActive ? RepsTheme.Colors.warning : RepsTheme.Colors.accent).opacity(0.15)
                        )
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Weight Cell with +/- Steppers

    private var weightCell: some View {
        HStack(spacing: 2) {
            // Minus button
            Button {
                adjustWeight(by: -5)
            } label: {
                Image(systemName: "minus")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(RepsTheme.Colors.textSecondary)
                    .frame(width: 24, height: 28)
                    .background(RepsTheme.Colors.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.xs))
            }
            .buttonStyle(.plain)

            // Weight input
            TextField("---", text: $weightText)
                .keyboardType(.decimalPad)
                .font(RepsTheme.Typography.mono)
                .foregroundStyle(RepsTheme.Colors.text)
                .multilineTextAlignment(.center)
                .padding(.vertical, RepsTheme.Spacing.sm)
                .background(RepsTheme.Colors.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.sm))
                .focused($weightFocused)
                .onChange(of: weightText) { _, newValue in
                    if let weight = Double(newValue) {
                        loggedSet.weight = weight
                        if hasAppeared && isFirstSet && !remainingSets.isEmpty {
                            pendingPropagation = .weight(weight)
                            showingPropagateAlert = true
                        }
                    } else {
                        loggedSet.weight = nil
                    }
                }

            // Plus button
            Button {
                adjustWeight(by: 5)
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(RepsTheme.Colors.textSecondary)
                    .frame(width: 24, height: 28)
                    .background(RepsTheme.Colors.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.xs))
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Reps Cell with +/- Steppers

    private var repsCell: some View {
        HStack(spacing: 2) {
            // Minus button
            Button {
                adjustReps(by: -1)
            } label: {
                Image(systemName: "minus")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(RepsTheme.Colors.textSecondary)
                    .frame(width: 24, height: 28)
                    .background(RepsTheme.Colors.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.xs))
            }
            .buttonStyle(.plain)

            // Reps input
            TextField("---", text: $repsText)
                .keyboardType(.numberPad)
                .font(RepsTheme.Typography.mono)
                .foregroundStyle(RepsTheme.Colors.text)
                .multilineTextAlignment(.center)
                .padding(.vertical, RepsTheme.Spacing.sm)
                .background(RepsTheme.Colors.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.sm))
                .focused($repsFocused)
                .onChange(of: repsText) { _, newValue in
                    if let reps = Int(newValue) {
                        loggedSet.reps = reps
                        if hasAppeared && isFirstSet && !remainingSets.isEmpty {
                            pendingPropagation = .reps(reps)
                            showingPropagateAlert = true
                        }
                    } else {
                        loggedSet.reps = nil
                    }
                }

            // Plus button
            Button {
                adjustReps(by: 1)
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(RepsTheme.Colors.textSecondary)
                    .frame(width: 24, height: 28)
                    .background(RepsTheme.Colors.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.xs))
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Propagation

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
        case .time(let time):
            for otherSet in remainingSets {
                otherSet.time = time
            }
        }

        pendingPropagation = nil
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    // MARK: - Set Indicator

    private var setIndicator: some View {
        Group {
            let sideLabel = loggedSet.side?.displayName ?? ""
            switch loggedSet.setType {
            case .warmup:
                Text("W\(sideLabel)")
                    .font(RepsTheme.Typography.mono)
                    .foregroundStyle(RepsTheme.Colors.warning)
            case .working:
                Text("\(loggedSet.setNumber)\(sideLabel)")
                    .font(RepsTheme.Typography.mono)
                    .foregroundStyle(loggedSet.side != nil ? sideColor : RepsTheme.Colors.text)
            case .dropset:
                Text("D\(sideLabel)")
                    .font(RepsTheme.Typography.mono)
                    .foregroundStyle(RepsTheme.Colors.error)
            case .failure:
                Text("F\(sideLabel)")
                    .font(RepsTheme.Typography.mono)
                    .foregroundStyle(RepsTheme.Colors.error)
            case .amrap:
                Text("A\(sideLabel)")
                    .font(RepsTheme.Typography.mono)
                    .foregroundStyle(RepsTheme.Colors.accent)
            case .restPause:
                Text("R\(sideLabel)")
                    .font(RepsTheme.Typography.mono)
                    .foregroundStyle(RepsTheme.Colors.accent)
            }
        }
    }

    private var sideColor: Color {
        switch loggedSet.side {
        case .left: return RepsTheme.Colors.accent
        case .right: return RepsTheme.Colors.warning
        case nil: return RepsTheme.Colors.text
        }
    }

    private var previousText: String {
        if let prevWeight = loggedSet.previousWeight, let prevReps = loggedSet.previousReps {
            return "\(Int(prevWeight))x\(prevReps)"
        }
        return "---"
    }

    // MARK: - Actions

    private func toggleCompleted() {
        loggedSet.isCompleted.toggle()
        if loggedSet.isCompleted {
            stopCountdownTimer()
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            onCompleted()
        } else {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    private func adjustWeight(by amount: Double) {
        let current = loggedSet.weight ?? 0
        let newValue = max(0, current + amount)
        loggedSet.weight = newValue
        weightText = newValue.formatted(.number.precision(.fractionLength(0...1)))
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func adjustReps(by amount: Int) {
        let current = loggedSet.reps ?? 0
        let newValue = max(0, current + amount)
        loggedSet.reps = newValue
        repsText = "\(newValue)"
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    // MARK: - Countdown Timer

    private func toggleCountdownTimer() {
        if timerActive {
            stopCountdownTimer()
        } else {
            startCountdownTimer()
        }
    }

    private func startCountdownTimer() {
        guard let time = loggedSet.time, time > 0 else { return }
        timerRemaining = time
        timerActive = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            DispatchQueue.main.async {
                if timerRemaining > 0 {
                    timerRemaining -= 1
                    if timerRemaining == 0 {
                        timerFinished()
                    }
                }
            }
        }
    }

    private func stopCountdownTimer() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        timerActive = false
        timerRemaining = 0
    }

    private func timerFinished() {
        stopCountdownTimer()

        // Haptic buzz
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        // Auto-complete the set
        if !loggedSet.isCompleted {
            loggedSet.isCompleted = true
            onCompleted()
        }

        // Play system sound
        AudioServicesPlaySystemSound(1007) // tri-tone
    }

    // MARK: - Time Formatting

    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        if mins > 0 {
            return "\(mins):\(String(format: "%02d", secs))"
        }
        return "\(secs)s"
    }
}

// MARK: - Time Picker Sheet

struct TimePickerSheet: View {
    @Binding var seconds: Int
    @Environment(\.dismiss) private var dismiss

    @State private var selectedMinutes: Int = 0
    @State private var selectedSeconds: Int = 0

    var body: some View {
        VStack(spacing: RepsTheme.Spacing.md) {
            HStack {
                Button("Cancel") { dismiss() }
                    .foregroundStyle(RepsTheme.Colors.textSecondary)
                Spacer()
                Text("Set Time")
                    .font(RepsTheme.Typography.headline)
                    .foregroundStyle(RepsTheme.Colors.text)
                Spacer()
                Button("Done") {
                    seconds = selectedMinutes * 60 + selectedSeconds
                    dismiss()
                }
                .foregroundStyle(RepsTheme.Colors.accent)
                .fontWeight(.semibold)
            }
            .padding(.horizontal, RepsTheme.Spacing.md)
            .padding(.top, RepsTheme.Spacing.md)

            HStack(spacing: 0) {
                Picker("Minutes", selection: $selectedMinutes) {
                    ForEach(0..<60) { min in
                        Text("\(min) min").tag(min)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)

                Picker("Seconds", selection: $selectedSeconds) {
                    ForEach(0..<60) { sec in
                        Text("\(sec) sec").tag(sec)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
            }
            .frame(height: 160)
        }
        .background(RepsTheme.Colors.surface)
        .onAppear {
            selectedMinutes = seconds / 60
            selectedSeconds = seconds % 60
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
