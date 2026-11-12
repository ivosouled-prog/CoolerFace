import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var model = ContentModel()

    var body: some View {
        TabView {
            NavigationStack {
                if !model.hasBackup {
                    BackupView(model: model)
                } else {
                    featureList
                }
            }
            NavigationStack {
                BackupTabView(model: model)
            }
        }
        .tabViewStyle(.verticalPage)
        .onChange(of: scenePhase, initial: true) { _, phase in
            if phase == .active {
                model.autoBackupIfNeeded()
                model.refreshCapabilityStates()
            }
        }
        .confirmationDialog("Restore this backup?", isPresented: $model.showRestoreConfirmation) {
            Button("Restore MG", role: .destructive) { model.perform(.restoreBackup(model.selectedBackupID)) }
        } message: {
            Text("The current MG will be backed up automatically first. Restart the watch after restoring.")
        }
        .alert("MobileGestalt Access Failed", isPresented: $model.showAccessAlert) {
            rollbackButton
            Button("OK", role: .cancel) { }
        } message: {
            Text("An App Group ID may be missing, or this watchOS version may be incompatible. Check the app's App Group configuration and watchOS version.\n\n\(rollbackHint)")
        }
        .alert("Could Not Change Setting", isPresented: Binding(
            get: { model.toggleError != nil },
            set: { if !$0 { model.toggleError = nil } }
        ), presenting: model.toggleError) { _ in
            rollbackButton
            Button("OK", role: .cancel) { }
        } message: { error in
            Text("\(error.message)\n\n\(rollbackHint)")
        }
    }

    private var featureList: some View {
        List {
            if !model.support.isSupported {
                Section {
                    Label("watchOS \(model.support.version) (\(model.support.build)) is not supported. Changes are disabled.",
                          systemImage: "xmark.octagon.fill")
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
            Section("Features") {
                NavigationLink { WatchFacesView(model: model) } label: {
                    Label("Watch Faces", systemImage: "clock")
                }
                NavigationLink { DisplayAndControlsView(model: model) } label: {
                    Label("Display & Controls", systemImage: "switch.2")
                }
                NavigationLink { SensorsAndWorkoutsView(model: model) } label: {
                    Label("Sensors & Workouts", systemImage: "heart")
                }
                NavigationLink { IntelligenceView(model: model) } label: {
                    Label("Siri & Intelligence", systemImage: "sparkles")
                }
            }
            .disabled(!model.support.isSupported)
            Section("Utilities") {
                NavigationLink { BackupView(model: model) } label: {
                    Label("MG Backups", systemImage: "archivebox")
                }
            }
            Section("Status") {
                Text(LocalizedStringKey(model.message))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                if model.hasUnrevertedChanges {
                    Label("Changes applied. Roll back on the Backup tab before deleting CoolerFace.",
                          systemImage: "exclamationmark.triangle.fill")
                        .font(.footnote)
                        .foregroundStyle(.orange)
                }
            }
        }
        .navigationTitle("CoolerFace")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    model.message = "Starting respring. View the app log if nothing happens."
                    BQRespring()
                } label: {
                    Image(systemName: "checkmark")
                }
                .accessibilityLabel("Restart Carousel")
            }
        }
    }

    /// Shown in every error alert: offers the rollback right there when possible.
    @ViewBuilder private var rollbackButton: some View {
        if model.canRollBack {
            Button("Roll Back", role: .destructive) { model.rollBack() }
        }
    }

    private var rollbackHint: String {
        model.canRollBack
            ? String(localized: "Roll back to the original backup before trying again or deleting CoolerFace.")
            : String(localized: "Do not delete CoolerFace until you can roll back to the original backup.")
    }
}
