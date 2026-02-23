import SwiftUI
import SwiftData

struct ProgramEditSheet: View {
    @Bindable var program: Program
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var description: String
    @State private var programDetails: String

    init(program: Program) {
        self.program = program
        _name = State(initialValue: program.name)
        _description = State(initialValue: program.programDescription ?? "")
        _programDetails = State(initialValue: program.programDetails ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Program Info") {
                    TextField("Program Name", text: $name)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                .listRowBackground(RepsTheme.Colors.surface)

                Section("Program Details") {
                    TextEditor(text: $programDetails)
                        .frame(minHeight: 200)
                        .font(RepsTheme.Typography.body)
                }
                .listRowBackground(RepsTheme.Colors.surface)
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .navigationTitle("Edit Program")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveChanges() }
                        .disabled(name.isEmpty)
                }
            }
        }
    }

    private func saveChanges() {
        program.name = name
        program.programDescription = description.isEmpty ? nil : description
        program.programDetails = programDetails.isEmpty ? nil : programDetails
        program.updatedAt = Date()
        dismiss()
    }
}
