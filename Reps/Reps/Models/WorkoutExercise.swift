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
        setTemplates.sorted {
            if $0.setNumber != $1.setNumber { return $0.setNumber < $1.setNumber }
            // Left before right, nil last
            let sideOrder: (SetSide?) -> Int = { side in
                switch side {
                case .left: return 0
                case .right: return 1
                case nil: return 2
                }
            }
            return sideOrder($0.side) < sideOrder($1.side)
        }
    }

    var sortedLoggedSets: [LoggedSet] {
        loggedSets.sorted {
            if $0.setNumber != $1.setNumber { return $0.setNumber < $1.setNumber }
            let sideOrder: (SetSide?) -> Int = { side in
                switch side {
                case .left: return 0
                case .right: return 1
                case nil: return 2
                }
            }
            return sideOrder($0.side) < sideOrder($1.side)
        }
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
