import Foundation
import SwiftData

@Model
final class PersonalRecord {
    @Attribute(.unique) var id: UUID
    var recordType: RecordType
    var value: Double
    var achievedAt: Date

    @Relationship var exercise: Exercise?
    @Relationship var loggedSet: LoggedSet?

    init(
        id: UUID = UUID(),
        recordType: RecordType,
        value: Double,
        exercise: Exercise? = nil,
        loggedSet: LoggedSet? = nil
    ) {
        self.id = id
        self.recordType = recordType
        self.value = value
        self.achievedAt = Date()
        self.exercise = exercise
        self.loggedSet = loggedSet
    }

    var formattedValue: String {
        switch recordType {
        case .maxWeight, .estimated1RM:
            return "\(Int(value)) kg"
        case .maxReps:
            return "\(Int(value)) reps"
        case .maxVolume:
            return "\(Int(value)) kg"
        case .maxDistance:
            if value >= 1000 {
                return String(format: "%.1f km", value / 1000)
            }
            return "\(Int(value)) m"
        case .fastestTime:
            let seconds = Int(value)
            let mins = seconds / 60
            let secs = seconds % 60
            if mins > 0 {
                return "\(mins):\(String(format: "%02d", secs))"
            }
            return "\(secs)s"
        }
    }
}
