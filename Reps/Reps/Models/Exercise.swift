import Foundation
import SwiftData

@Model
final class Exercise {
    @Attribute(.unique) var id: UUID
    var name: String
    var muscleGroups: [MuscleGroup]
    var equipment: [Equipment]
    var instructions: String?
    var videoURL: String?
    var localVideoFilename: String? // Stored in app's documents/videos directory
    var imageURL: String?
    var localImageFilename: String? // Stored in app's documents/images directory
    var isCustom: Bool
    var createdAt: Date

    @Relationship(inverse: \WorkoutExercise.exercise)
    var workoutExercises: [WorkoutExercise] = []

    @Relationship(inverse: \PersonalRecord.exercise)
    var personalRecords: [PersonalRecord] = []

    init(
        id: UUID = UUID(),
        name: String,
        muscleGroups: [MuscleGroup] = [],
        equipment: [Equipment] = [],
        instructions: String? = nil,
        videoURL: String? = nil,
        localVideoFilename: String? = nil,
        imageURL: String? = nil,
        localImageFilename: String? = nil,
        isCustom: Bool = false
    ) {
        self.id = id
        self.name = name
        self.muscleGroups = muscleGroups
        self.equipment = equipment
        self.instructions = instructions
        self.videoURL = videoURL
        self.localVideoFilename = localVideoFilename
        self.imageURL = imageURL
        self.localImageFilename = localImageFilename
        self.isCustom = isCustom
        self.createdAt = Date()
    }

    /// Primary equipment for display
    var primaryEquipment: Equipment? {
        equipment.first
    }

    var primaryMuscle: MuscleGroup? {
        muscleGroups.first
    }

    var displayMuscle: String {
        primaryMuscle?.displayName ?? "General"
    }

    /// Returns true if the exercise has any video (URL or local)
    var hasVideo: Bool {
        videoURL != nil || localVideoFilename != nil
    }

    /// Returns the local video URL if it exists
    var localVideoURL: URL? {
        guard let filename = localVideoFilename else { return nil }
        return VideoStorageService.videosDirectory.appendingPathComponent(filename)
    }

    /// Returns true if the exercise has any image (URL or local)
    var hasImage: Bool {
        imageURL != nil || localImageFilename != nil
    }

    /// Returns the local image URL if it exists
    var localImageURL: URL? {
        guard let filename = localImageFilename else { return nil }
        return VideoStorageService.imagesDirectory.appendingPathComponent(filename)
    }
}
