import Foundation
import SwiftData

@Model
final class Week {
    @Attribute(.unique) var id: UUID
    var weekNumber: Int
    var notes: String?

    @Relationship var phase: Phase?

    @Relationship(deleteRule: .cascade, inverse: \ProgramDay.week)
    var days: [ProgramDay] = []

    init(
        id: UUID = UUID(),
        weekNumber: Int,
        notes: String? = nil
    ) {
        self.id = id
        self.weekNumber = weekNumber
        self.notes = notes
    }

    var sortedDays: [ProgramDay] {
        days.sorted { $0.dayNumber < $1.dayNumber }
    }

    var trainingDays: [ProgramDay] {
        sortedDays.filter { $0.dayType == .training }
    }
}
