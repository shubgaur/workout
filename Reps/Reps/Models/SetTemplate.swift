import Foundation
import SwiftData

@Model
final class SetTemplate {
    @Attribute(.unique) var id: UUID
    var setNumber: Int
    var setType: SetType
    var targetReps: Int?
    var targetWeight: Double?
    var targetDistance: Double? // meters
    var targetTime: Int? // seconds
    var targetRPE: Int? // 1-10
    var side: SetSide? // nil = both/bilateral, .left, .right
    var notes: String?

    @Relationship var workoutExercise: WorkoutExercise?

    init(
        id: UUID = UUID(),
        setNumber: Int,
        setType: SetType = .working,
        targetReps: Int? = nil,
        targetWeight: Double? = nil,
        targetDistance: Double? = nil,
        targetTime: Int? = nil,
        targetRPE: Int? = nil,
        side: SetSide? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.setNumber = setNumber
        self.setType = setType
        self.targetReps = targetReps
        self.targetWeight = targetWeight
        self.targetDistance = targetDistance
        self.targetTime = targetTime
        self.targetRPE = targetRPE
        self.side = side
        self.notes = notes
    }

    var displaySetNumber: String {
        let prefix = setType.shortName
        if prefix.isEmpty {
            return "\(setNumber)"
        }
        return prefix
    }

    var targetDescription: String {
        var parts: [String] = []
        if let reps = targetReps {
            parts.append("\(reps) reps")
        }
        if let weight = targetWeight {
            parts.append("\(Int(weight)) kg")
        }
        if let time = targetTime {
            parts.append(formatTime(time))
        }
        if let distance = targetDistance {
            parts.append("\(Int(distance))m")
        }
        return parts.joined(separator: " × ")
    }

    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        if mins > 0 {
            return "\(mins):\(String(format: "%02d", secs))"
        }
        return "\(secs)s"
    }
}
