import Foundation
import SwiftData

@Model
final class WorkoutExercise {
    @Attribute(.unique) var id: UUID
    var order: Int
    var isOptional: Bool
    var notes: String?
    var restSeconds: Int?

    @Relationship var exercise: Exercise?
    @Relationship var exerciseGroup: ExerciseGroup?

    @Relationship(deleteRule: .cascade, inverse: \SetTemplate.workoutExercise)
    var setTemplates: [SetTemplate] = []

    @Relationship(deleteRule: .cascade, inverse: \LoggedSet.workoutExercise)
    var loggedSets: [LoggedSet] = []

    init(
        id: UUID = UUID(),
        order: Int,
        isOptional: Bool = false,
        notes: String? = nil,
        restSeconds: Int? = 90
    ) {
        self.id = id
        self.order = order
        self.isOptional = isOptional
        self.notes = notes
        self.restSeconds = restSeconds
    }

    var sortedSetTemplates: [SetTemplate] {
        setTemplates.sorted { $0.setNumber < $1.setNumber }
    }

    var sortedLoggedSets: [LoggedSet] {
        loggedSets.sorted { $0.setNumber < $1.setNumber }
    }

    var completedSets: Int {
        loggedSets.filter { $0.isCompleted }.count
    }

    var totalSets: Int {
        max(setTemplates.count, loggedSets.count)
    }

    var isFullyCompleted: Bool {
        !loggedSets.isEmpty && loggedSets.allSatisfy { $0.isCompleted }
    }
}
