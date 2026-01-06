import Foundation
import SwiftData

@Model
final class ProgramDay {
    @Attribute(.unique) var id: UUID
    var dayNumber: Int
    var name: String
    var dayType: DayType
    var notes: String?

    @Relationship var week: Week?

    @Relationship(deleteRule: .cascade, inverse: \WorkoutTemplate.programDay)
    var workoutTemplate: WorkoutTemplate?

    @Relationship(inverse: \WorkoutSession.programDay)
    var workoutSessions: [WorkoutSession] = []

    init(
        id: UUID = UUID(),
        dayNumber: Int,
        name: String,
        dayType: DayType = .training,
        notes: String? = nil
    ) {
        self.id = id
        self.dayNumber = dayNumber
        self.name = name
        self.dayType = dayType
        self.notes = notes
    }

    var isCompleted: Bool {
        workoutSessions.contains { $0.status == .completed }
    }

    var lastCompletedDate: Date? {
        workoutSessions
            .filter { $0.status == .completed }
            .compactMap { $0.endTime }
            .max()
    }
}
