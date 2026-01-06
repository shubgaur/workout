import Foundation
import SwiftData

@Model
final class ExerciseGroup {
    @Attribute(.unique) var id: UUID
    var groupType: ExerciseGroupType
    var order: Int
    var name: String? // e.g., "Zone 5 Cardio"
    var notes: String?

    @Relationship var workoutTemplate: WorkoutTemplate?
    @Relationship var workoutSession: WorkoutSession?

    @Relationship(deleteRule: .cascade, inverse: \WorkoutExercise.exerciseGroup)
    var exercises: [WorkoutExercise] = []

    init(
        id: UUID = UUID(),
        groupType: ExerciseGroupType = .single,
        order: Int,
        name: String? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.groupType = groupType
        self.order = order
        self.name = name
        self.notes = notes
    }

    var sortedExercises: [WorkoutExercise] {
        exercises.sorted { $0.order < $1.order }
    }

    var isSuperset: Bool {
        groupType == .superset || groupType == .triset || groupType == .circuit
    }

    var displayName: String {
        if let name = name {
            return name
        }
        switch groupType {
        case .superset: return "Superset"
        case .triset: return "Tri-set"
        case .circuit: return "Circuit"
        case .zone: return "Zone"
        case .single: return ""
        }
    }
}
