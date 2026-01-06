import SwiftUI
import SwiftData

struct WorkoutSummaryView: View {
    let session: WorkoutSession
    var onDismiss: () -> Void

    @State private var rating: Int = 0
    @State private var notes = ""
    @State private var showingConfetti = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: RepsTheme.Spacing.xl) {
                    // Workout complete header
                    completionHeader

                    // Stats summary
                    statsSection

                    // Exercise summary
                    exerciseSummary

                    // Rating
                    ratingSection

                    // Notes
                    notesSection
                }
                .padding(RepsTheme.Spacing.md)
            }
            .background(RepsTheme.Colors.background)
            .navigationTitle("Workout Complete")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        saveAndDismiss()
                    }
                    .foregroundStyle(RepsTheme.Colors.accent)
                    .fontWeight(.semibold)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            showingConfetti = true
            triggerHaptic()
        }
        .overlay {
            if showingConfetti {
                ConfettiView()
                    .allowsHitTesting(false)
            }
        }
    }

    // MARK: - Completion Header

    private var completionHeader: some View {
        VStack(spacing: RepsTheme.Spacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(RepsTheme.Colors.success)

            Text("Great Work!")
                .font(RepsTheme.Typography.title)
                .foregroundStyle(RepsTheme.Colors.text)

            Text(session.template?.name ?? "Quick Workout")
                .font(RepsTheme.Typography.body)
                .foregroundStyle(RepsTheme.Colors.textSecondary)
        }
        .padding(.top, RepsTheme.Spacing.lg)
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        HStack(spacing: RepsTheme.Spacing.md) {
            StatBox(
                icon: "clock.fill",
                value: session.formattedDuration,
                label: "Duration"
            )

            StatBox(
                icon: "flame.fill",
                value: "\(Int(session.totalVolume))",
                label: "Volume (kg)"
            )

            StatBox(
                icon: "checkmark.circle.fill",
                value: "\(session.completedSets)",
                label: "Sets"
            )
        }
    }

    // MARK: - Exercise Summary

    private var exerciseSummary: some View {
        VStack(alignment: .leading, spacing: RepsTheme.Spacing.md) {
            Text("EXERCISES")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(RepsTheme.Colors.textSecondary)

            ForEach(session.sortedExerciseGroups) { group in
                ForEach(group.sortedExercises) { exercise in
                    ExerciseSummaryRow(exercise: exercise)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(RepsTheme.Spacing.md)
        .background(RepsTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.md))
    }

    // MARK: - Rating Section

    private var ratingSection: some View {
        VStack(alignment: .leading, spacing: RepsTheme.Spacing.sm) {
            Text("HOW WAS YOUR WORKOUT?")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(RepsTheme.Colors.textSecondary)

            HStack(spacing: RepsTheme.Spacing.md) {
                ForEach(1...5, id: \.self) { star in
                    Button {
                        rating = star
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                    } label: {
                        Image(systemName: star <= rating ? "star.fill" : "star")
                            .font(.system(size: 32))
                            .foregroundStyle(star <= rating ? RepsTheme.Colors.warning : RepsTheme.Colors.textTertiary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(RepsTheme.Spacing.md)
            .background(RepsTheme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.md))
        }
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: RepsTheme.Spacing.sm) {
            Text("NOTES")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(RepsTheme.Colors.textSecondary)

            TextField("How did the workout feel?", text: $notes, axis: .vertical)
                .font(RepsTheme.Typography.body)
                .foregroundStyle(RepsTheme.Colors.text)
                .lineLimit(3...6)
                .padding(RepsTheme.Spacing.md)
                .background(RepsTheme.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.md))
        }
    }

    // MARK: - Actions

    private func saveAndDismiss() {
        session.rating = rating > 0 ? rating : nil
        session.notes = notes.isEmpty ? nil : notes
        onDismiss()
    }

    private func triggerHaptic() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

// MARK: - Stat Box

struct StatBox: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: RepsTheme.Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(RepsTheme.Colors.accent)

            Text(value)
                .font(RepsTheme.Typography.headline)
                .foregroundStyle(RepsTheme.Colors.text)

            Text(label)
                .font(RepsTheme.Typography.caption)
                .foregroundStyle(RepsTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(RepsTheme.Spacing.md)
        .background(RepsTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.md))
    }
}

// MARK: - Exercise Summary Row

struct ExerciseSummaryRow: View {
    let exercise: WorkoutExercise

    var body: some View {
        HStack(spacing: RepsTheme.Spacing.sm) {
            VStack(alignment: .leading, spacing: RepsTheme.Spacing.xxs) {
                Text(exercise.exercise?.name ?? "Unknown")
                    .font(RepsTheme.Typography.body)
                    .foregroundStyle(RepsTheme.Colors.text)

                let completedSets = exercise.loggedSets.filter { $0.isCompleted }.count
                let totalSets = exercise.loggedSets.count
                Text("\(completedSets)/\(totalSets) sets completed")
                    .font(RepsTheme.Typography.caption)
                    .foregroundStyle(RepsTheme.Colors.textSecondary)
            }

            Spacer()

            // Best set
            if let bestSet = exercise.loggedSets.filter({ $0.isCompleted }).max(by: {
                ($0.weight ?? 0) * Double($0.reps ?? 0) < ($1.weight ?? 0) * Double($1.reps ?? 0)
            }) {
                if let weight = bestSet.weight, let reps = bestSet.reps {
                    Text("\(Int(weight))kg x \(reps)")
                        .font(RepsTheme.Typography.mono)
                        .foregroundStyle(RepsTheme.Colors.accent)
                }
            }
        }
        .padding(.vertical, RepsTheme.Spacing.xs)
    }
}

// MARK: - Confetti View

struct ConfettiView: View {
    @State private var confetti: [ConfettiPiece] = []

    var body: some View {
        GeometryReader { geometry in
            ForEach(confetti) { piece in
                ConfettiPieceView(piece: piece)
            }
        }
        .onAppear {
            createConfetti()
        }
    }

    private func createConfetti() {
        for _ in 0..<50 {
            confetti.append(ConfettiPiece())
        }
    }
}

struct ConfettiPiece: Identifiable {
    let id = UUID()
    let color: Color
    let startX: CGFloat
    let rotation: Double
    let scale: CGFloat
    let duration: Double

    init() {
        let colors: [Color] = [
            RepsTheme.Colors.accent,
            RepsTheme.Colors.success,
            RepsTheme.Colors.warning,
            .blue,
            .purple
        ]
        color = colors.randomElement() ?? .orange
        startX = CGFloat.random(in: 0...UIScreen.main.bounds.width)
        rotation = Double.random(in: 0...360)
        scale = CGFloat.random(in: 0.5...1.0)
        duration = Double.random(in: 2...4)
    }
}

struct ConfettiPieceView: View {
    let piece: ConfettiPiece
    @State private var yOffset: CGFloat = -50
    @State private var opacity: Double = 1

    var body: some View {
        Rectangle()
            .fill(piece.color)
            .frame(width: 8, height: 12)
            .scaleEffect(piece.scale)
            .rotationEffect(.degrees(piece.rotation))
            .offset(x: piece.startX, y: yOffset)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeIn(duration: piece.duration)) {
                    yOffset = UIScreen.main.bounds.height + 100
                }
                withAnimation(.easeIn(duration: piece.duration).delay(piece.duration - 0.5)) {
                    opacity = 0
                }
            }
    }
}
