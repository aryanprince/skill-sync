import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Skill Sync")
                        .font(.headline)
                    Text(summary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                scanIndicator
            }
            .padding(12)

            Divider()

            if model.projectWorkspaces.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Add a projects folder to find agent skills and MCP configuration.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    DirectoryPickerButton {
                        Label("Add Projects Folder", systemImage: "folder.badge.plus")
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(12)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(model.workspaces.filter { $0.attentionCount > 0 }.prefix(4)) {
                        workspace in
                        Button {
                            model.selection = .workspace(workspace.id)
                            showManager()
                        } label: {
                            HStack {
                                Image(
                                    systemName: workspace.conflictCount > 0
                                        ? "exclamationmark.triangle" : "arrow.triangle.merge"
                                )
                                .foregroundStyle(workspace.conflictCount > 0 ? .red : .orange)
                                Text(
                                    workspace.rootURL == AppModel.homeURL
                                        ? "Global" : workspace.name)
                                Spacer()
                                Text("\(workspace.attentionCount)")
                                    .foregroundStyle(.secondary)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                    }

                    if model.attentionCount == 0 {
                        Label("Everything scanned is in sync", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .padding(12)
                    }
                }
                .padding(.vertical, 6)
            }

            Divider()

            Button("Open Skill Sync", systemImage: "macwindow") {
                showManager()
            }
            .keyboardShortcut("o")
            .padding(.horizontal, 12)
            .padding(.top, 9)

            Button("Scan Now", systemImage: "arrow.clockwise") {
                Task { await model.refresh() }
            }
            .keyboardShortcut("r")
            .disabled(model.scanState == .scanning)
            .padding(.horizontal, 12)
            .padding(.top, 5)

            SettingsLink {
                Label("Settings…", systemImage: "gearshape")
            }
            .padding(.horizontal, 12)
            .padding(.top, 5)

            Divider()
                .padding(.top, 9)

            Button("Quit Skill Sync") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
            .padding(12)
        }
        .frame(width: 300)
        .task { await model.bootstrap() }
    }

    private var summary: String {
        if model.attentionCount == 0 {
            "\(model.skillCount) skills checked"
        } else {
            "\(model.attentionCount) items need attention"
        }
    }

    @ViewBuilder private var scanIndicator: some View {
        if model.scanState == .scanning {
            ProgressView()
                .controlSize(.small)
        } else {
            Image(systemName: model.attentionCount == 0 ? "checkmark.circle.fill" : "circle.fill")
                .foregroundStyle(model.attentionCount == 0 ? .green : .orange)
        }
    }

    private func showManager() {
        openWindow(id: "manager")
        model.activateApp()
    }
}
