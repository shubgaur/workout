import Foundation
import SwiftData

@Model
final class WorkoutTemplate {
    @Attribute(.unique) var id: UUID
    var name: String
    var templateDescription: String?
    var estimatedDuration: Int? // minutes
    var createdAt: Date

    @Relationship var programDay: ProgramDay?

    @Relationship(deleteRule: .cascade, inverse: \ExerciseGroup.workoutTemplate)
    var exerciseGroups: [ExerciseGroup] = []

    init(
        id: UUID = UUID(),
        name: String,
        templateDescription: String? = nil,
        estimatedDuration: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.templateDescription = templateDescription
        self.estimatedDuration = estimatedDuration
        self.createdAt = Date()
    }

    var sortedExerciseGroups: [ExerciseGroup] {
        exerciseGroups.sorted { $0.order < $1.order }
    }

    var totalExercises: Int {
        exerciseGroups.reduce(0) { $0 + $1.exercises.count }
    }

    var totalSets: Int {
        exerciseGroups
            .flatMap { $0.exercises }
            .reduce(0) { $0 + $1.setTemplates.count }
    }
}
