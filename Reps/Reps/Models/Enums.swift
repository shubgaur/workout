import Foundation

// MARK: - Muscle Groups

enum MuscleGroup: String, Codable, CaseIterable, Identifiable {
    case chest, back, shoulders, biceps, triceps, forearms
    case quads, hamstrings, glutes, calves, abdominals, obliques
    case traps, lats, lowerBack, hipFlexors, adductors, abductors
    case neck, fullBody, cardio

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .lowerBack: return "Lower Back"
        case .hipFlexors: return "Hip Flexors"
        case .fullBody: return "Full Body"
        default: return rawValue.capitalized
        }
    }
}

// MARK: - Equipment

enum Equipment: String, Codable, CaseIterable, Identifiable {
    case barbell, dumbbell, kettlebell, cable, machine
    case bodyweight, bands, smith, ezBar, trapBar
    case pullupBar, dipStation, bench, box, medicineBall
    case treadmill, bike, rower, elliptical, stairmaster
    case none

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .ezBar: return "EZ Bar"
        case .trapBar: return "Trap Bar"
        case .pullupBar: return "Pull-up Bar"
        case .dipStation: return "Dip Station"
        case .medicineBall: return "Medicine Ball"
        default: return rawValue.capitalized
        }
    }
}

// MARK: - Exercise Group Types

enum ExerciseGroupType: String, Codable, CaseIterable {
    case single      // Single exercise
    case superset    // 2 exercises alternating
    case triset      // 3 exercises alternating
    case circuit     // Multiple exercises, one set each in sequence
    case zone        // Named zone (e.g., "Zone 5 Cardio")

    var displayName: String {
        rawValue.capitalized
    }
}

// MARK: - Set Types

enum SetType: String, Codable, CaseIterable {
    case warmup
    case working
    case dropset
    case failure
    case amrap
    case restPause

    var displayName: String {
        switch self {
        case .warmup: return "Warm-up"
        case .working: return "Working"
        case .dropset: return "Drop Set"
        case .failure: return "To Failure"
        case .amrap: return "AMRAP"
        case .restPause: return "Rest-Pause"
        }
    }

    var shortName: String {
        switch self {
        case .warmup: return "W"
        case .working: return ""
        case .dropset: return "D"
        case .failure: return "F"
        case .amrap: return "A"
        case .restPause: return "RP"
        }
    }
}

// MARK: - Day Types

enum DayType: String, Codable, CaseIterable {
    case training
    case rest
    case activeRecovery
    case deload

    var displayName: String {
        switch self {
        case .training: return "Training"
        case .rest: return "Rest"
        case .activeRecovery: return "Active Recovery"
        case .deload: return "Deload"
        }
    }
}

// MARK: - Workout Status

enum WorkoutStatus: String, Codable {
    case inProgress
    case completed
    case cancelled
}

// MARK: - Record Types

enum RecordType: String, Codable, CaseIterable {
    case maxWeight      // Heaviest weight lifted
    case maxReps        // Most reps at any weight
    case maxVolume      // Highest single-set volume (weight x reps)
    case estimated1RM   // Calculated 1RM
    case maxDistance    // Longest distance
    case fastestTime    // Fastest time for distance

    var displayName: String {
        switch self {
        case .maxWeight: return "Max Weight"
        case .maxReps: return "Max Reps"
        case .maxVolume: return "Max Volume"
        case .estimated1RM: return "Estimated 1RM"
        case .maxDistance: return "Max Distance"
        case .fastestTime: return "Fastest Time"
        }
    }
}

// MARK: - Set Side (for per-side exercises)

enum SetSide: String, Codable, CaseIterable {
    case left
    case right

    var displayName: String {
        switch self {
        case .left: return "L"
        case .right: return "R"
        }
    }
}

// MARK: - Units

enum WeightUnit: String, Codable, CaseIterable {
    case kg, lbs

    var displayName: String {
        rawValue
    }
}

enum DistanceUnit: String, Codable, CaseIterable {
    case meters, miles, kilometers

    var displayName: String {
        switch self {
        case .meters: return "m"
        case .miles: return "mi"
        case .kilometers: return "km"
        }
    }
}
