// Licensed under the Reps Source License
//
//  CreateExerciseView.swift
//  Reps
//
//  Sheet for creating a new exercise

import SwiftUI
import SwiftData

struct CreateExerciseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var selectedMuscles: Set<MuscleGroup> = []
    @State private var selectedEquipment: Set<Equipment> = []
    @State private var instructions: String = ""
    @State private var imageURL: String = ""
    @State private var localImageFilename: String?
    @State private var showingImagePicker = false
    @State private var cachedLocalImage: UIImage?

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Exercise name", text: $name)
                }

                Section("Target Muscles") {
                    MuscleGroupPicker(selectedMuscles: $selectedMuscles)
                }

                Section("Equipment") {
                    EquipmentPicker(selectedEquipment: $selectedEquipment)
                }

                Section("Instructions") {
                    TextEditor(text: $instructions)
                        .frame(minHeight: 100)
                }

                Section("Image") {
                    // Show current image preview
                    if localImageFilename != nil {
                        HStack {
                            if let image = cachedLocalImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 80, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.sm))
                            } else {
                                ProgressView()
                                    .frame(width: 80, height: 80)
                            }

                            Spacer()

                            Button(role: .destructive) {
                                if let old = localImageFilename {
                                    VideoStorageService.deleteImage(filename: old)
                                }
                                localImageFilename = nil
                                cachedLocalImage = nil
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundStyle(RepsTheme.Colors.error)
                            }
                        }
                        .task(id: localImageFilename) {
                            await loadLocalImageAsync()
                        }
                    } else if !imageURL.isEmpty, let url = URL(string: imageURL) {
                        HStack {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                ProgressView()
                            }
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.sm))

                            Spacer()

                            Button(role: .destructive) {
                                imageURL = ""
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundStyle(RepsTheme.Colors.error)
                            }
                        }
                    }

                    // Upload button
                    Button {
                        showingImagePicker = true
                    } label: {
                        Label(localImageFilename != nil || !imageURL.isEmpty ? "Change Image" : "Choose Image", systemImage: "photo")
                    }

                    // URL fallback
                    TextField("Or paste image URL...", text: $imageURL)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .onChange(of: imageURL) { _, newValue in
                            if !newValue.isEmpty {
                                if let old = localImageFilename {
                                    VideoStorageService.deleteImage(filename: old)
                                }
                                localImageFilename = nil
                            }
                        }
                }
            }
            .navigationTitle("New Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        // Clean up any uploaded image if canceling
                        if let filename = localImageFilename {
                            VideoStorageService.deleteImage(filename: filename)
                        }
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createExercise()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(name.isEmpty)
                }
            }
            .fileImporter(
                isPresented: $showingImagePicker,
                allowedContentTypes: [.image],
                allowsMultipleSelection: false
            ) { result in
                handleImageSelection(result)
            }
        }
    }

    private func loadLocalImageAsync() async {
        guard let filename = localImageFilename else { return }
        let url = VideoStorageService.imageURL(for: filename)
        let image = await Task.detached(priority: .userInitiated) {
            guard let data = try? Data(contentsOf: url) else { return nil as UIImage? }
            return UIImage(data: data)
        }.value
        cachedLocalImage = image
    }

    private func handleImageSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let sourceURL = urls.first else { return }

            Task {
                do {
                    if let old = localImageFilename {
                        VideoStorageService.deleteImage(filename: old)
                    }

                    let filename = try await Task.detached(priority: .userInitiated) {
                        try VideoStorageService.saveImage(from: sourceURL)
                    }.value
                    localImageFilename = filename
                    imageURL = ""
                    await loadLocalImageAsync()
                } catch {
                    print("Failed to save image: \(error)")
                }
            }
        case .failure(let error):
            print("Image selection failed: \(error)")
        }
    }

    private func createExercise() {
        let exercise = Exercise(
            name: name,
            muscleGroups: Array(selectedMuscles),
            equipment: Array(selectedEquipment),
            instructions: instructions.isEmpty ? nil : instructions,
            videoURL: nil,
            localVideoFilename: nil,
            imageURL: imageURL.isEmpty ? nil : imageURL,
            isCustom: true
        )
        exercise.localImageFilename = localImageFilename
        modelContext.insert(exercise)
    }
}

#Preview {
    CreateExerciseView()
        .modelContainer(for: Exercise.self, inMemory: true)
        .preferredColorScheme(.dark)
}
