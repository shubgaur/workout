import Foundation
import SwiftData

@Model
final class WorkoutSession {
    @Attribute(.unique) var id: UUID
    var name: String?  // User-defined workout name
    var startTime: Date
    var endTime: Date?
    var status: WorkoutStatus
    var notes: String?
    var rating: Int?  // 1-10 perceived difficulty
    var wasSkipped: Bool = false  // True if workout was skipped (not completed)

    @Relationship var template: WorkoutTemplate?
    @Relationship var programDay: ProgramDay?

    @Relationship(deleteRule: .cascade, inverse: \ExerciseGroup.workoutSession)
    var exerciseGroups: [ExerciseGroup] = []

    init(
        id: UUID = UUID(),
        template: WorkoutTemplate? = nil,
        programDay: ProgramDay? = nil
    ) {
        self.id = id
        self.startTime = Date()
        self.status = .inProgress
        self.template = template
        self.programDay = programDay
    }

    var duration: TimeInterval {
        let end = endTime ?? Date()
        return end.timeIntervalSince(startTime)
    }

    var formattedDuration: String {
        TimeFormatter.formatDuration(duration)
    }

    var displayName: String {
        if let name = name, !name.isEmpty { return name }

        // Build from program context: "Program · W1D3"
        if let day = programDay,
           let week = day.week,
           let phase = week.phase,
           let program = phase.program {
            return "\(program.name) · W\(week.weekNumber)D\(day.dayNumber)"
        }

        return template?.name ?? "Quick Workout"
    }

    var totalVolume: Double {
        exerciseGroups
            .flatMap { $0.exercises }
            .flatMap { $0.loggedSets }
            .filter { $0.isCompleted }
            .reduce(0) { total, set in
                let weight = set.weight ?? 0
                let reps = Double(set.reps ?? 0)
                return total + (weight * reps)
            }
    }

    var completedExercises: Int {
        exerciseGroups
            .flatMap { $0.exercises }
            .filter { $0.isFullyCompleted }
            .count
    }

    var totalExercises: Int {
        exerciseGroups.reduce(0) { $0 + $1.exercises.count }
    }

    var completedSets: Int {
        exerciseGroups
            .flatMap { $0.exercises }
            .flatMap { $0.loggedSets }
            .filter { $0.isCompleted }
            .count
    }

    var sortedExerciseGroups: [ExerciseGroup] {
        exerciseGroups.sorted { $0.order < $1.order }
    }

    func finish() {
        endTime = Date()
        status = .completed
    }

    func cancel() {
        endTime = Date()
        status = .cancelled
    }
}
