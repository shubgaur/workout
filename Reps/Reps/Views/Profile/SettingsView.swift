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
                .listRowBackground(RepsTheme.Colors.surface)

                Picker("Distance", selection: Binding(
                    get: { settings.distanceUnit },
                    set: { settings.distanceUnit = $0 }
                )) {
                    Text("Meters").tag(DistanceUnit.meters)
                    Text("Kilometers").tag(DistanceUnit.kilometers)
                    Text("Miles").tag(DistanceUnit.miles)
                }
                .listRowBackground(RepsTheme.Colors.surface)
            } header: {
                Text("Units")
                    .foregroundStyle(RepsTheme.Colors.textSecondary)
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
                .listRowBackground(RepsTheme.Colors.surface)

                Picker("Default Reps", selection: Binding(
                    get: { settings.defaultReps },
                    set: { settings.defaultReps = $0 }
                )) {
                    ForEach([5, 6, 8, 10, 12, 15, 20], id: \.self) { num in
                        Text("\(num)").tag(num)
                    }
                }
                .listRowBackground(RepsTheme.Colors.surface)

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
                .listRowBackground(RepsTheme.Colors.surface)

                Toggle("Auto-start Rest Timer", isOn: Binding(
                    get: { settings.autoStartRest },
                    set: { settings.autoStartRest = $0 }
                ))
                .tint(RepsTheme.Colors.accent)
                .listRowBackground(RepsTheme.Colors.surface)
            } header: {
                Text("Workout")
                    .foregroundStyle(RepsTheme.Colors.textSecondary)
            }

            // Feedback Section
            Section {
                Toggle("Sound Effects", isOn: Binding(
                    get: { settings.soundEnabled },
                    set: { settings.soundEnabled = $0 }
                ))
                .tint(RepsTheme.Colors.accent)
                .listRowBackground(RepsTheme.Colors.surface)

                Toggle("Haptic Feedback", isOn: Binding(
                    get: { settings.hapticEnabled },
                    set: { settings.hapticEnabled = $0 }
                ))
                .tint(RepsTheme.Colors.accent)
                .listRowBackground(RepsTheme.Colors.surface)
            } header: {
                Text("Feedback")
                    .foregroundStyle(RepsTheme.Colors.textSecondary)
            }

            // Appearance Section
            Section {
                NavigationLink {
                    ThemeSettingsView()
                } label: {
                    HStack {
                        Text("Theme")
                        Spacer()
                        Text(PaletteManager.shared.activePalette.name)
                            .foregroundStyle(RepsTheme.Colors.textSecondary)
                    }
                }
                .listRowBackground(RepsTheme.Colors.surface)
            } header: {
                Text("Appearance")
                    .foregroundStyle(RepsTheme.Colors.textSecondary)
            }

            // Sync Section
            Section {
                Toggle("iCloud Sync", isOn: Binding(
                    get: { settings.iCloudSyncEnabled },
                    set: { settings.iCloudSyncEnabled = $0 }
                ))
                .tint(RepsTheme.Colors.accent)
                .listRowBackground(RepsTheme.Colors.surface)
            } header: {
                Text("Sync")
                    .foregroundStyle(RepsTheme.Colors.textSecondary)
            } footer: {
                Text("Sync your workouts and programs across all your devices")
                    .foregroundStyle(RepsTheme.Colors.textSecondary)
            }

            // Support Section
            Section {
                NavigationLink {
                    HelpView()
                } label: {
                    Label("Help & Tips", systemImage: "questionmark.circle")
                }
                .listRowBackground(RepsTheme.Colors.surface)
            } header: {
                Text("Support")
                    .foregroundStyle(RepsTheme.Colors.textSecondary)
            }

            // About Section
            Section {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundStyle(RepsTheme.Colors.textSecondary)
                }
                .listRowBackground(RepsTheme.Colors.surface)

                NavigationLink {
                    AcknowledgementsView()
                } label: {
                    Text("Acknowledgements")
                }
                .listRowBackground(RepsTheme.Colors.surface)
            } header: {
                Text("About")
                    .foregroundStyle(RepsTheme.Colors.textSecondary)
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
                .listRowBackground(RepsTheme.Colors.surface)
            } header: {
                Text("Data")
                    .foregroundStyle(RepsTheme.Colors.textSecondary)
            } footer: {
                Text("This will permanently delete all your workouts, programs, and personal records")
                    .foregroundStyle(RepsTheme.Colors.textSecondary)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .transparentNavigation()
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
                .listRowBackground(RepsTheme.Colors.surface)
            } header: {
                Text("Data Sources")
                    .foregroundStyle(RepsTheme.Colors.textSecondary)
            }

            Section {
                AcknowledgementRow(
                    name: "SwiftUI",
                    description: "Apple's declarative UI framework",
                    url: nil
                )
                .listRowBackground(RepsTheme.Colors.surface)

                AcknowledgementRow(
                    name: "Swift Charts",
                    description: "Data visualization framework",
                    url: nil
                )
                .listRowBackground(RepsTheme.Colors.surface)

                AcknowledgementRow(
                    name: "SwiftData",
                    description: "Persistence framework",
                    url: nil
                )
                .listRowBackground(RepsTheme.Colors.surface)
            } header: {
                Text("Frameworks")
                    .foregroundStyle(RepsTheme.Colors.textSecondary)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .navigationTitle("Acknowledgements")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
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
