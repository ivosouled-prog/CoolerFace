import SwiftUI

/// CoolerFace's own "Backup" tab: watchOS support status, the date of the latest
/// MobileGestalt backup, a one-tap rollback to the original, and a reminder
/// to roll back before deleting the app.
struct BackupTabView: View {
    let model: ContentModel
    @State private var showRollbackConfirmation = false

    var body: some View {
        List {
            Section("watchOS") {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("watchOS \(model.support.version)")
                        Text(model.support.build)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: model.support.isSupported ? "checkmark.seal.fill" : "xmark.octagon.fill")
                        .foregroundStyle(model.support.isSupported ? .green : .red)
                }
                if !model.support.isSupported {
                    Text("This watchOS version is not supported. CoolerFace will not change anything on it.")
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }

            Section("Last Backup") {
                if let date = model.lastBackupDate {
                    Text(date.formatted(date: .abbreviated, time: .shortened))
                } else {
                    Text("No backup yet.")
                        .foregroundStyle(.secondary)
                    Button("Back Up Now") { model.perform(.backup) }
                }
                Text("MobileGestalt is backed up automatically on first launch and before every change.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section {
                Button(role: .destructive) {
                    showRollbackConfirmation = true
                } label: {
                    Label("Roll Back", systemImage: "arrow.uturn.backward")
                }
                .disabled(!model.canRollBack)
            } footer: {
                Text("Restores the original MobileGestalt from your first backup. Restart the watch afterwards.")
            }

            Section("Before Deleting CoolerFace") {
                Label {
                    Text("Roll back first, then delete the app. Deleting it with changes still applied removes the backups and leaves MobileGestalt modified.")
                        .font(.footnote)
                } icon: {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(model.hasUnrevertedChanges ? .orange : .secondary)
                }
                if model.hasUnrevertedChanges {
                    Text("Changes are currently applied.")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.orange)
                }
            }

            Section {
                NavigationLink { BackupView(model: model) } label: {
                    Label("All Backups", systemImage: "archivebox")
                }
            }
        }
        .navigationTitle("Backup")
        .onAppear { model.refreshBackups() }
        .confirmationDialog("Roll back to the original MobileGestalt?", isPresented: $showRollbackConfirmation) {
            Button("Roll Back", role: .destructive) { model.rollBack() }
        } message: {
            Text("The current MG will be backed up automatically first. Restart the watch after rolling back.")
        }
    }
}
