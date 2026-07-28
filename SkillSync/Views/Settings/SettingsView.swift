import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        Form {
            Section("Watched folders") {
                if model.watchedRoots.isEmpty {
                    Text("No project folders added yet.")
                        .foregroundStyle(.secondary)
                }

                ForEach(model.watchedRoots, id: \.self) { root in
                    HStack {
                        Image(systemName: "folder")
                            .foregroundStyle(.secondary)
                        Text(root.path)
                            .font(.callout.monospaced())
                            .lineLimit(1)
                        Spacer()
                        Button("Remove", systemImage: "minus.circle", role: .destructive) {
                            Task { await model.removeWatchedRoot(root) }
                        }
                        .labelStyle(.iconOnly)
                        .buttonStyle(.plain)
                    }
                }

                DirectoryPickerButton {
                    Label("Add Folder…", systemImage: "plus")
                }
            }

            Section("Safety") {
                LabeledContent("Canonical directory", value: ".agents/skills")
                LabeledContent("Duplicate handling", value: "Back up, then symlink")
                LabeledContent("Conflicts", value: "Never modify automatically")
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(width: 560, height: 380)
    }
}
