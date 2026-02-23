import Foundation
import SwiftData

@Model
final class LoggedSet {
    @Attribute(.unique) var id: UUID
    var setNumber: Int
    var setType: SetType
    var completedAt: Date?
    var isCompleted: Bool

    // Performance metrics
    var reps: Int?
    var weight: Double? // kg
    var distance: Double? // meters
    var time: Int? // seconds
    var rpe: Int? // 1-10
    var side: SetSide? // nil = both/bilateral, .left, .right

    // Reference to previous (for "PREVIOUS" column display)
    var previousReps: Int?
    var previousWeight: Double?

    var notes: String?

    @Relationship var workoutExercise: WorkoutExercise?

    @Relationship(inverse: \PersonalRecord.loggedSet)
    var personalRecords: [PersonalRecord] = []

    init(
        id: UUID = UUID(),
        setNumber: Int,
        setType: SetType = .working,
        previousReps: Int? = nil,
        previousWeight: Double? = nil
    ) {
        self.id = id
        self.setNumber = setNumber
        self.setType = setType
        self.isCompleted = false
        self.previousReps = previousReps
        self.previousWeight = previousWeight
    }

    var displaySetNumber: String {
        let prefix = setType.shortName
        if prefix.isEmpty {
            return "\(setNumber)"
        }
        return prefix
    }

    var previousDisplay: String {
        guard let prevWeight = previousWeight, let prevReps = previousReps else {
            return "-"
        }
        return "\(Int(prevWeight)) × \(prevReps)"
    }

    var volume: Double {
        guard let w = weight, let r = reps else { return 0 }
        return w * Double(r)
    }

    func complete() {
        isCompleted = true
        completedAt = Date()
    }

    func uncomplete() {
        isCompleted = false
        completedAt = nil
    }

    // Epley formula for 1RM estimation
    var estimated1RM: Double? {
        guard let weight = weight, let reps = reps, reps > 0 else { return nil }
        if reps == 1 { return weight }
        return weight * (1 + Double(reps) / 30.0)
    }
}
