import SwiftUI
import SwiftData

struct WorkoutEditSheet: View {
    @Bindable var workout: WorkoutSession
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var notes: String
    @State private var rating: Int?

    init(workout: WorkoutSession) {
        self.workout = workout
        _name = State(initialValue: workout.name ?? "")
        _notes = State(initialValue: workout.notes ?? "")
        _rating = State(initialValue: workout.rating)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Workout Info") {
                    TextField("Name (optional)", text: $name)
                }
                .listRowBackground(RepsTheme.Colors.surface)

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                        .font(RepsTheme.Typography.body)
                }
                .listRowBackground(RepsTheme.Colors.surface)

                Section("Difficulty Rating") {
                    Picker("Rating", selection: $rating) {
                        Text("None").tag(nil as Int?)
                        ForEach(1...10, id: \.self) { value in
                            Text("\(value)").tag(value as Int?)
                        }
                    }
                }
                .listRowBackground(RepsTheme.Colors.surface)
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .navigationTitle("Edit Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveChanges() }
                }
            }
        }
    }

    private func saveChanges() {
        workout.name = name.isEmpty ? nil : name
        workout.notes = notes.isEmpty ? nil : notes
        workout.rating = rating
        dismiss()
    }
}
