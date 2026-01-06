import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ImportProgramView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var isImporting = false
    @State private var importError: ImportError?
    @State private var showingError = false
    @State private var importedProgram: Program?
    @State private var showingSuccess = false

    var body: some View {
        NavigationStack {
            VStack(spacing: RepsTheme.Spacing.xl) {
                // Info header
                VStack(spacing: RepsTheme.Spacing.md) {
                    Image(systemName: "doc.badge.plus")
                        .font(.system(size: 64))
                        .foregroundStyle(RepsTheme.Colors.accent)

                    Text("Import Program")
                        .font(RepsTheme.Typography.title2)
                        .foregroundStyle(RepsTheme.Colors.text)

                    Text("Import a workout program from a JSON file. The file should contain program structure with phases, weeks, days, and exercises.")
                        .font(RepsTheme.Typography.body)
                        .foregroundStyle(RepsTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, RepsTheme.Spacing.lg)
                }
                .padding(.top, RepsTheme.Spacing.xl)

                Spacer()

                // Supported formats
                VStack(alignment: .leading, spacing: RepsTheme.Spacing.sm) {
                    Text("SUPPORTED FORMATS")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(RepsTheme.Colors.textSecondary)

                    FormatRow(format: ".json", description: "JSON program file")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(RepsTheme.Spacing.md)
                .background(RepsTheme.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.md))

                Spacer()

                // Import button
                Button {
                    isImporting = true
                } label: {
                    HStack {
                        Image(systemName: "folder")
                        Text("Choose File")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(RepsButtonStyle(style: .primary))
                .padding(.horizontal, RepsTheme.Spacing.lg)
                .padding(.bottom, RepsTheme.Spacing.xl)
            }
            .background(RepsTheme.Colors.background)
            .navigationTitle("Import")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(RepsTheme.Colors.textSecondary)
                }
            }
            .fileImporter(
                isPresented: $isImporting,
                allowedContentTypes: [UTType.json],
                allowsMultipleSelection: false
            ) { result in
                handleImport(result)
            }
            .alert("Import Error", isPresented: $showingError) {
                Button("OK") {}
            } message: {
                Text(importError?.localizedDescription ?? "Unknown error")
            }
            .alert("Import Successful", isPresented: $showingSuccess) {
                Button("View Program") {
                    dismiss()
                }
            } message: {
                if let program = importedProgram {
                    Text("Successfully imported '\(program.name)' with \(program.phases.count) phases.")
                }
            }
        }
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }

            Task {
                await importProgram(from: url)
            }

        case .failure(let error):
            importError = .fileAccessError(error.localizedDescription)
            showingError = true
        }
    }

    @MainActor
    private func importProgram(from url: URL) async {
        let importService = ImportService(modelContext: modelContext)

        do {
            // Ensure we can access the file
            guard url.startAccessingSecurityScopedResource() else {
                throw ImportError.fileAccessError("Unable to access file")
            }
            defer { url.stopAccessingSecurityScopedResource() }

            let program = try await importService.importProgram(from: url)
            importedProgram = program
            showingSuccess = true
        } catch let error as ImportError {
            importError = error
            showingError = true
        } catch {
            importError = .parseError(error.localizedDescription)
            showingError = true
        }
    }
}

// MARK: - Format Row

struct FormatRow: View {
    let format: String
    let description: String

    var body: some View {
        HStack(spacing: RepsTheme.Spacing.sm) {
            Text(format)
                .font(RepsTheme.Typography.mono)
                .foregroundStyle(RepsTheme.Colors.accent)
                .padding(.horizontal, RepsTheme.Spacing.sm)
                .padding(.vertical, RepsTheme.Spacing.xxs)
                .background(RepsTheme.Colors.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: RepsTheme.Radius.xs))

            Text(description)
                .font(RepsTheme.Typography.body)
                .foregroundStyle(RepsTheme.Colors.text)
        }
    }
}

// MARK: - Import Error

enum ImportError: LocalizedError {
    case fileAccessError(String)
    case parseError(String)
    case invalidFormat(String)
    case exerciseNotFound(String)

    var errorDescription: String? {
        switch self {
        case .fileAccessError(let message):
            return "File access error: \(message)"
        case .parseError(let message):
            return "Parse error: \(message)"
        case .invalidFormat(let message):
            return "Invalid format: \(message)"
        case .exerciseNotFound(let name):
            return "Exercise not found: \(name)"
        }
    }
}

#Preview {
    ImportProgramView()
        .modelContainer(for: Program.self, inMemory: true)
        .preferredColorScheme(.dark)
}
