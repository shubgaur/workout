import Foundation
import SwiftData

@Model
final class UserSettings {
    @Attribute(.unique) var id: UUID
    var weightUnit: WeightUnit
    var distanceUnit: DistanceUnit
    var defaultRestSeconds: Int
    var autoStartRest: Bool
    var soundEnabled: Bool
    var hapticEnabled: Bool
    var iCloudSyncEnabled: Bool

    // Optional to support migration from older versions
    private var _defaultSets: Int?
    private var _defaultReps: Int?

    var defaultSets: Int {
        get { _defaultSets ?? 3 }
        set { _defaultSets = newValue }
    }

    var defaultReps: Int {
        get { _defaultReps ?? 10 }
        set { _defaultReps = newValue }
    }

    init(
        id: UUID = UUID(),
        weightUnit: WeightUnit = .lbs,
        distanceUnit: DistanceUnit = .miles,
        defaultRestSeconds: Int = 90,
        autoStartRest: Bool = true,
        soundEnabled: Bool = true,
        hapticEnabled: Bool = true,
        iCloudSyncEnabled: Bool = true,
        defaultSets: Int = 3,
        defaultReps: Int = 10
    ) {
        self.id = id
        self.weightUnit = weightUnit
        self.distanceUnit = distanceUnit
        self.defaultRestSeconds = defaultRestSeconds
        self.autoStartRest = autoStartRest
        self.soundEnabled = soundEnabled
        self.hapticEnabled = hapticEnabled
        self.iCloudSyncEnabled = iCloudSyncEnabled
        self._defaultSets = defaultSets
        self._defaultReps = defaultReps
    }

    static var `default`: UserSettings {
        UserSettings()
    }
}
