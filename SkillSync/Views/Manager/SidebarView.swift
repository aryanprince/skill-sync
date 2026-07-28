import SwiftUI

struct SidebarView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        List(selection: $model.selection) {
            NavigationLink(value: AppDestination.overview) {
                Label("Overview", systemImage: "square.grid.2x2")
            }

            Section("Workspaces") {
                if let global = model.globalWorkspace {
                    NavigationLink(value: AppDestination.workspace(global.id)) {
                        workspaceLabel(title: "Global", workspace: global, icon: "globe")
                    }
                }

                ForEach(model.projectWorkspaces) { workspace in
                    NavigationLink(value: AppDestination.workspace(workspace.id)) {
                        workspaceLabel(title: workspace.name, workspace: workspace, icon: "folder")
                    }
                }

                DirectoryPickerButton {
                    Label("Add Folder…", systemImage: "plus")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }

            Section("Integrations") {
                NavigationLink(value: AppDestination.catalog) {
                    Label("Skills Catalog", systemImage: "sparkle.magnifyingglass")
                }
                NavigationLink(value: AppDestination.mcpServers) {
                    Label("MCP Servers", systemImage: "server.rack")
                }
            }
        }
        .listStyle(.sidebar)
        .navigationSplitViewColumnWidth(
            min: AppStyle.sidebarWidth,
            ideal: AppStyle.sidebarWidth,
            max: 270
        )
    }

    private func workspaceLabel(title: String, workspace: Workspace, icon: String) -> some View {
        Label {
            HStack {
                Text(title)
                    .lineLimit(1)
                Spacer()
                if workspace.attentionCount > 0 {
                    Text("\(workspace.attentionCount)")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            workspace.conflictCount > 0 ? Color.red : Color.orange, in: Capsule())
                }
            }
        } icon: {
            Image(systemName: icon)
        }
    }
}
