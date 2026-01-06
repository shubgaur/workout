import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var allSettings: [UserSettings]
    @Environment(\.modelContext) private var modelContext

    private var settings: UserSettings {
        if let existing = allSettings.first {
            return existing
        }
        let newSettings = UserSettings()
        modelContext.insert(newSettings)
        return newSettings
    }

    var body: some View {
        List {
            // Units Section
            Section {
                Picker("Weight", selection: Binding(
                    get: { settings.weightUnit },
                    set: { settings.weightUnit = $0 }
                )) {
                    Text("kg").tag(WeightUnit.kg)
                    Text("lbs").tag(WeightUnit.lbs)
                }

                Picker("Distance", selection: Binding(
                    get: { settings.distanceUnit },
                    set: { settings.distanceUnit = $0 }
                )) {
                    Text("Meters").tag(DistanceUnit.meters)
                    Text("Kilometers").tag(DistanceUnit.kilometers)
                    Text("Miles").tag(DistanceUnit.miles)
                }
            } header: {
                Text("Units")
            }

            // Workout Defaults Section
            Section {
                Picker("Default Sets", selection: Binding(
                    get: { settings.defaultSets },
                    set: { settings.defaultSets = $0 }
                )) {
                    ForEach(1...10, id: \.self) { num in
                        Text("\(num)").tag(num)
                    }
                }

                Picker("Default Reps", selection: Binding(
                    get: { settings.defaultReps },
                    set: { settings.defaultReps = $0 }
                )) {
                    ForEach([5, 6, 8, 10, 12, 15, 20], id: \.self) { num in
                        Text("\(num)").tag(num)
                    }
                }

                Picker("Default Rest", selection: Binding(
                    get: { settings.defaultRestSeconds },
                    set: { settings.defaultRestSeconds = $0 }
                )) {
                    Text("30s").tag(30)
                    Text("60s").tag(60)
                    Text("90s").tag(90)
                    Text("2min").tag(120)
                    Text("3min").tag(180)
                    Text("5min").tag(300)
                }

                Toggle("Auto-start Rest Timer", isOn: Binding(
                    get: { settings.autoStartRest },
                    set: { settings.autoStartRest = $0 }
                ))
            } header: {
                Text("Workout")
            }

            // Feedback Section
            Section {
                Toggle("Sound Effects", isOn: Binding(
                    get: { settings.soundEnabled },
                    set: { settings.soundEnabled = $0 }
                ))

                Toggle("Haptic Feedback", isOn: Binding(
                    get: { settings.hapticEnabled },
                    set: { settings.hapticEnabled = $0 }
                ))
            } header: {
                Text("Feedback")
            }

            // Sync Section
            Section {
                Toggle("iCloud Sync", isOn: Binding(
                    get: { settings.iCloudSyncEnabled },
                    set: { settings.iCloudSyncEnabled = $0 }
                ))
            } header: {
                Text("Sync")
            } footer: {
                Text("Sync your workouts and programs across all your devices")
            }

            // About Section
            Section {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundStyle(RepsTheme.Colors.textSecondary)
                }

                NavigationLink {
                    AcknowledgementsView()
                } label: {
                    Text("Acknowledgements")
                }
            } header: {
                Text("About")
            }

            // Danger Zone
            Section {
                Button(role: .destructive) {
                    // TODO: Implement data reset
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text("Reset All Data")
                    }
                }
            } header: {
                Text("Data")
            } footer: {
                Text("This will permanently delete all your workouts, programs, and personal records")
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Acknowledgements View

struct AcknowledgementsView: View {
    var body: some View {
        List {
            Section {
                AcknowledgementRow(
                    name: "ExerciseDB",
                    description: "Exercise database with animations",
                    url: "https://exercisedb.io"
                )
            } header: {
                Text("Data Sources")
            }

            Section {
                AcknowledgementRow(
                    name: "SwiftUI",
                    description: "Apple's declarative UI framework",
                    url: nil
                )

                AcknowledgementRow(
                    name: "Swift Charts",
                    description: "Data visualization framework",
                    url: nil
                )

                AcknowledgementRow(
                    name: "SwiftData",
                    description: "Persistence framework",
                    url: nil
                )
            } header: {
                Text("Frameworks")
            }
        }
        .navigationTitle("Acknowledgements")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AcknowledgementRow: View {
    let name: String
    let description: String
    let url: String?

    var body: some View {
        VStack(alignment: .leading, spacing: RepsTheme.Spacing.xxs) {
            Text(name)
                .font(RepsTheme.Typography.body)
                .foregroundStyle(RepsTheme.Colors.text)

            Text(description)
                .font(RepsTheme.Typography.caption)
                .foregroundStyle(RepsTheme.Colors.textSecondary)
        }
        .padding(.vertical, RepsTheme.Spacing.xxs)
    }
}
