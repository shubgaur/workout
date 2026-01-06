import SwiftUI
import SwiftData
import UniformTypeIdentifiers

// MARK: - Import Type

enum ImportType: String, CaseIterable {
    case exercises
    case programs

    var title: String {
        switch self {
        case .exercises: return "Exercises"
        case .programs: return "Programs"
        }
    }

    var icon: String {
        switch self {
        case .exercises: return "dumbbell"
        case .programs: return "list.bullet.clipboard"
        }
    }

    var description: String {
        switch self {
        case .exercises:
            return "Import exercises to your library with muscle groups, equipment, and instructions."
        case .programs:
            return "Import complete workout programs with phases, weeks, days, and exercises."
        }
    }
}

// MARK: - Import View

struct ImportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedType: ImportType = .exercises
    @State private var inputMode: InputMode = .file
    @State private var textInput: String = ""
    @State private var isImporting = false
    @State private var importError: ImportError?
    @State private var showingError = false
    @State private var showingSuccess = false
    @State private var successMessage: String = ""
    @State private var showingTemplate = false

    enum InputMode: String, CaseIterable {
        case file
        case paste

        var title: String {
            switch self {
            case .file: return "File"
            case .paste: return "Paste"
            }
        }

        var icon: String {
            switch self {
            case .file: return "doc"
            case .paste: return "doc.on.clipboard"
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: RepsTheme.Spacing.lg) {
                    // Import type selector
                    importTypeSelector

                    // Input mode selector
                    inputModeSelector

                    // Template button
                    templateButton

                    // Input area
                    if inputMode == .paste {
                        textInputArea
                    } else {
                        fileInputArea
                    }

                    // Import button
                    importButton
                }
                .padding(RepsTheme.Spacing.md)
            }
            .background(RepsTheme.Colors.background)
            .navigationTitle("Import")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(RepsTheme.Colors.textSecondary)
                }
            }
            .fileImporter(
                isPresented: $isImporting,
                allowedContentTypes: [UTType.json],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result)
            }
            .sheet(isPresented: $showingTemplate) {
                TemplateSheet(importType: selectedType)
            }
            .alert("Import Error", isPresented: $showingError) {
                Button("OK") {}
            } message: {
                Text(importError?.localizedDescription ?? "Unknown error")
            }
            .alert("Import Successful", isPresented: $showingSuccess) {
                Button("Done") { dismiss() }
            } message: {
                Text(successMessage)
            }
        }
    }

    // MARK: - Import Type Selector

    private var importTypeSelector: some View {
        VStack(alignment: .leading, spacing: RepsTheme.Spacing.sm) {
            Text("IMPORT TYPE")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(RepsTheme.Colors.textSecondary)

            HStack(spacing: RepsTheme.Spacing.sm) {
                ForEach(ImportType.allCases, id: \.self) { type in
                    ImportTypeButton(
                        type: type,
                        isSelected: selectedType == type,
                        action: { selectedType = type }
                    )
                }
            }

            Text(selectedType.description)
                .font(RepsTheme.Typography.caption)
                .foregroundStyle(RepsTheme.Colors.textSecondary)
                .padding(.top, RepsTheme.Spacing.xxs)
        }
    }

    // MARK: - Input Mode Selector

    private var inputModeSelector: some View {
        VStack(alignment: .leading, spacing: RepsTheme.Spacing.sm) {
            Text("INPUT METHOD")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(RepsTheme.Colors.textSecondary)

            HStack(spacing: RepsTheme.Spacing.sm) {
                ForEach(InputMode.allCases, id: \.self) { mode in
                    Button {
                        inputMode = mode
                    } label: {
                        HStack(spacing: RepsTheme.Spacing.xs) {
                            Image(systemName: mode.icon)
                            Text(mode.title)
                        }
                        .font(RepsTheme.Typography.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, RepsTheme.Spacing.sm)
                        .background(inputMode == mode ? RepsTheme.Colors.accent.opacity(0.2) : RepsTheme.Colors.surface)
                        .foregroundStyle(inputMode == mode ? RepsTheme.Colors.accent : RepsTheme.Colors.textSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.sm))
                        .overlay(
                            RoundedRectangle(cornerRadius: RepsTheme.Radius.sm)
                                .stroke(inputMode == mode ? RepsTheme.Colors.accent : RepsTheme.Colors.border, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Template Button

    private var templateButton: some View {
        Button {
            showingTemplate = true
        } label: {
            HStack {
                Image(systemName: "doc.text")
                Text("View \(selectedType.title) Template")
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
            }
            .font(RepsTheme.Typography.subheadline)
            .foregroundStyle(RepsTheme.Colors.accent)
            .padding(RepsTheme.Spacing.md)
            .background(RepsTheme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.md))
            .overlay(
                RoundedRectangle(cornerRadius: RepsTheme.Radius.md)
                    .stroke(RepsTheme.Colors.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Text Input Area

    private var textInputArea: some View {
        VStack(alignment: .leading, spacing: RepsTheme.Spacing.sm) {
            Text("PASTE JSON")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(RepsTheme.Colors.textSecondary)

            TextEditor(text: $textInput)
                .font(.system(size: 13, design: .monospaced))
                .scrollContentBackground(.hidden)
                .padding(RepsTheme.Spacing.sm)
                .frame(minHeight: 200)
                .background(RepsTheme.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: RepsTheme.Radius.md)
                        .stroke(RepsTheme.Colors.border, lineWidth: 1)
                )
                .overlay(alignment: .topLeading) {
                    if textInput.isEmpty {
                        Text("Paste your JSON here...")
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundStyle(RepsTheme.Colors.textTertiary)
                            .padding(RepsTheme.Spacing.md)
                            .allowsHitTesting(false)
                    }
                }

            if !textInput.isEmpty {
                Button {
                    textInput = ""
                } label: {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                        Text("Clear")
                    }
                    .font(RepsTheme.Typography.caption)
                    .foregroundStyle(RepsTheme.Colors.textSecondary)
                }
            }
        }
    }

    // MARK: - File Input Area

    private var fileInputArea: some View {
        VStack(spacing: RepsTheme.Spacing.lg) {
            VStack(spacing: RepsTheme.Spacing.md) {
                Image(systemName: "doc.badge.plus")
                    .font(.system(size: 48))
                    .foregroundStyle(RepsTheme.Colors.accent)

                Text("Select a JSON file")
                    .font(RepsTheme.Typography.headline)
                    .foregroundStyle(RepsTheme.Colors.text)

                Text("Tap the button below to choose a file from your device")
                    .font(RepsTheme.Typography.caption)
                    .foregroundStyle(RepsTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(RepsTheme.Spacing.xl)
            .frame(maxWidth: .infinity)
            .background(RepsTheme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.md))
            .overlay(
                RoundedRectangle(cornerRadius: RepsTheme.Radius.md)
                    .stroke(RepsTheme.Colors.border, lineWidth: 1)
            )

            Button {
                isImporting = true
            } label: {
                HStack {
                    Image(systemName: "folder")
                    Text("Choose File")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(RepsButtonStyle(style: .secondary))
        }
    }

    // MARK: - Import Button

    private var importButton: some View {
        Button {
            performImport()
        } label: {
            HStack {
                Image(systemName: "square.and.arrow.down")
                Text("Import \(selectedType.title)")
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(RepsButtonStyle(style: .primary))
        .disabled(inputMode == .paste && textInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        .opacity(inputMode == .paste && textInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)
    }

    // MARK: - Actions

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            Task {
                await importFromFile(url)
            }
        case .failure(let error):
            importError = .fileAccessError(error.localizedDescription)
            showingError = true
        }
    }

    private func performImport() {
        guard inputMode == .paste else { return }

        let trimmed = textInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        Task {
            await importFromText(trimmed)
        }
    }

    @MainActor
    private func importFromFile(_ url: URL) async {
        guard url.startAccessingSecurityScopedResource() else {
            importError = .fileAccessError("Unable to access file")
            showingError = true
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }

        do {
            let data = try Data(contentsOf: url)
            try await processImport(data: data)
        } catch let error as ImportError {
            importError = error
            showingError = true
        } catch {
            importError = .parseError(error.localizedDescription)
            showingError = true
        }
    }

    @MainActor
    private func importFromText(_ text: String) async {
        guard let data = text.data(using: .utf8) else {
            importError = .parseError("Invalid text encoding")
            showingError = true
            return
        }

        do {
            try await processImport(data: data)
        } catch let error as ImportError {
            importError = error
            showingError = true
        } catch {
            importError = .parseError(error.localizedDescription)
            showingError = true
        }
    }

    @MainActor
    private func processImport(data: Data) async throws {
        let importService = ImportService(modelContext: modelContext)

        switch selectedType {
        case .exercises:
            let count = try await importService.importExercises(from: data)
            successMessage = "Successfully imported \(count) exercise\(count == 1 ? "" : "s")."
            showingSuccess = true

        case .programs:
            let program = try await importService.importProgram(from: data)
            successMessage = "Successfully imported '\(program.name)' with \(program.phases.count) phase\(program.phases.count == 1 ? "" : "s")."
            showingSuccess = true
        }
    }
}

// MARK: - Import Type Button

struct ImportTypeButton: View {
    let type: ImportType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: RepsTheme.Spacing.xs) {
                Image(systemName: type.icon)
                    .font(.system(size: 24))
                Text(type.title)
                    .font(RepsTheme.Typography.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, RepsTheme.Spacing.md)
            .background(isSelected ? RepsTheme.Colors.accent.opacity(0.2) : RepsTheme.Colors.surface)
            .foregroundStyle(isSelected ? RepsTheme.Colors.accent : RepsTheme.Colors.textSecondary)
            .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.md))
            .overlay(
                RoundedRectangle(cornerRadius: RepsTheme.Radius.md)
                    .stroke(isSelected ? RepsTheme.Colors.accent : RepsTheme.Colors.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Template Sheet

struct TemplateSheet: View {
    @Environment(\.dismiss) private var dismiss
    let importType: ImportType

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: RepsTheme.Spacing.lg) {
                    // Instructions
                    instructionsSection

                    // Template
                    templateSection

                    // Copy button
                    copyButton
                }
                .padding(RepsTheme.Spacing.md)
            }
            .background(RepsTheme.Colors.background)
            .navigationTitle("\(importType.title) Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: RepsTheme.Spacing.sm) {
            Text("INSTRUCTIONS")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(RepsTheme.Colors.textSecondary)

            Text(instructionsText)
                .font(RepsTheme.Typography.body)
                .foregroundStyle(RepsTheme.Colors.text)
                .padding(RepsTheme.Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RepsTheme.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.md))
        }
    }

    private var templateSection: some View {
        VStack(alignment: .leading, spacing: RepsTheme.Spacing.sm) {
            Text("JSON TEMPLATE")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(RepsTheme.Colors.textSecondary)

            ScrollView(.horizontal, showsIndicators: true) {
                Text(templateText)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(RepsTheme.Colors.text)
                    .padding(RepsTheme.Spacing.md)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RepsTheme.Colors.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.md))
            .overlay(
                RoundedRectangle(cornerRadius: RepsTheme.Radius.md)
                    .stroke(RepsTheme.Colors.border, lineWidth: 1)
            )
        }
    }

    private var copyButton: some View {
        Button {
            UIPasteboard.general.string = templateText
        } label: {
            HStack {
                Image(systemName: "doc.on.doc")
                Text("Copy Template")
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(RepsButtonStyle(style: .secondary))
    }

    private var instructionsText: String {
        switch importType {
        case .exercises:
            return """
            Create a JSON file with an "exercises" array containing exercise objects.

            Required fields:
            • name: Exercise name (string)

            Optional fields:
            • muscleGroups: Array of muscle names (chest, back, shoulders, biceps, triceps, forearms, quads, hamstrings, glutes, calves, abdominals, obliques, traps, lats, lowerBack, hipFlexors, adductors, abductors, neck, fullBody, cardio)
            • equipment: Array of equipment (barbell, dumbbell, kettlebell, cable, machine, bodyweight, bands, smith, ezBar, trapBar, pullupBar, dipStation, bench, box, medicineBall, treadmill, bike, rower, elliptical, stairmaster, none)
            • instructions: How to perform the exercise
            • videoURL: Link to a demo video
            """

        case .programs:
            return """
            Create a JSON file with program structure.

            Required fields:
            • name: Program name
            • phases: Array of phase objects

            Each phase contains:
            • name: Phase name
            • weeks: Array of week objects

            Each week contains:
            • weekNumber: Week number (1, 2, 3...)
            • days: Array of day objects

            Each day contains:
            • dayNumber: Day number (1, 2, 3...)
            • name: Day name (e.g., "Push A")
            • dayType: training, rest, activeRecovery, or deload
            • workout: Workout object with exerciseGroups
            """
        }
    }

    private var templateText: String {
        switch importType {
        case .exercises:
            return """
{
  "exercises": [
    {
      "name": "Barbell Bench Press",
      "muscleGroups": ["chest", "triceps", "shoulders"],
      "equipment": ["barbell", "bench"],
      "instructions": "Lie on a flat bench. Grip the bar slightly wider than shoulder-width. Lower the bar to your chest, then press up.",
      "videoURL": "https://example.com/bench-press.mp4"
    },
    {
      "name": "Pull-ups",
      "muscleGroups": ["back", "biceps", "forearms"],
      "equipment": ["pullupBar"],
      "instructions": "Hang from a pull-up bar with an overhand grip. Pull yourself up until your chin is over the bar."
    },
    {
      "name": "Barbell Squat",
      "muscleGroups": ["quads", "glutes", "hamstrings"],
      "equipment": ["barbell"],
      "instructions": "Place the bar on your upper back. Squat down until thighs are parallel to the floor, then stand up."
    }
  ]
}
"""

        case .programs:
            return """
{
  "name": "Push Pull Legs",
  "description": "6-day PPL program for hypertrophy",
  "phases": [
    {
      "name": "Phase 1 - Foundation",
      "description": "Building base strength",
      "weeks": [
        {
          "weekNumber": 1,
          "days": [
            {
              "dayNumber": 1,
              "name": "Push A",
              "dayType": "training",
              "workout": {
                "name": "Push A",
                "exerciseGroups": [
                  {
                    "type": "single",
                    "exercises": [
                      {
                        "exerciseRef": "Barbell Bench Press",
                        "restSeconds": 180,
                        "sets": [
                          { "setNumber": 1, "setType": "warmup", "targetReps": 10 },
                          { "setNumber": 2, "setType": "working", "targetReps": 8, "targetRPE": 7 },
                          { "setNumber": 3, "setType": "working", "targetReps": 8, "targetRPE": 8 },
                          { "setNumber": 4, "setType": "working", "targetReps": 8, "targetRPE": 9 }
                        ]
                      }
                    ]
                  },
                  {
                    "type": "superset",
                    "exercises": [
                      {
                        "exerciseRef": "Lateral Raises",
                        "restSeconds": 60,
                        "sets": [
                          { "setNumber": 1, "setType": "working", "targetReps": 15 },
                          { "setNumber": 2, "setType": "working", "targetReps": 15 },
                          { "setNumber": 3, "setType": "working", "targetReps": 15 }
                        ]
                      },
                      {
                        "exerciseRef": "Tricep Pushdowns",
                        "restSeconds": 60,
                        "sets": [
                          { "setNumber": 1, "setType": "working", "targetReps": 12 },
                          { "setNumber": 2, "setType": "working", "targetReps": 12 },
                          { "setNumber": 3, "setType": "working", "targetReps": 12 }
                        ]
                      }
                    ]
                  }
                ]
              }
            },
            {
              "dayNumber": 2,
              "name": "Pull A",
              "dayType": "training",
              "workout": {
                "name": "Pull A",
                "exerciseGroups": []
              }
            },
            {
              "dayNumber": 3,
              "name": "Rest",
              "dayType": "rest"
            }
          ]
        }
      ]
    }
  ]
}
"""
        }
    }
}

#Preview {
    ImportView()
        .modelContainer(for: [Exercise.self, Program.self], inMemory: true)
        .preferredColorScheme(.dark)
}
