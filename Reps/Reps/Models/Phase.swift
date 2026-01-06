import Foundation
import SwiftData

@Model
final class Phase {
    @Attribute(.unique) var id: UUID
    var name: String
    var order: Int
    var phaseDescription: String?

    @Relationship var program: Program?

    @Relationship(deleteRule: .cascade, inverse: \Week.phase)
    var weeks: [Week] = []

    init(
        id: UUID = UUID(),
        name: String,
        order: Int,
        phaseDescription: String? = nil
    ) {
        self.id = id
        self.name = name
        self.order = order
        self.phaseDescription = phaseDescription
    }

    var sortedWeeks: [Week] {
        weeks.sorted { $0.weekNumber < $1.weekNumber }
    }
}
