import SwiftUI

struct OverviewView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                header
                metrics

                if model.projectWorkspaces.isEmpty {
                    emptyState
                } else {
                    workspaceList
                }
            }
            .padding(AppStyle.contentInset)
            .frame(maxWidth: 980, alignment: .leading)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Skills, without the sprawl.")
                .font(.system(size: 28, weight: .semibold))
            Text("Keep one canonical copy in .agents and link compatible coding agents back to it.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }

    private var metrics: some View {
        HStack(spacing: 0) {
            metric(value: "\(model.skillCount)", label: "Skills indexed")
            Divider().frame(height: 42)
            metric(value: "\(model.projectWorkspaces.count)", label: "Projects")
            Divider().frame(height: 42)
            metric(value: "\(model.attentionCount)", label: "Need attention")
            Divider().frame(height: 42)
            metric(value: "\(model.conflictCount)", label: "Conflicts")
        }
        .padding(.vertical, 14)
        .background(Color.appSecondaryCanvas)
        .overlay(alignment: .top) { Divider() }
        .overlay(alignment: .bottom) { Divider() }
    }

    private func metric(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value)
                .font(.title2.monospacedDigit().weight(.semibold))
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("Choose Where Your Projects Live", systemImage: "folder.badge.plus")
        } description: {
            Text(
                "Skill Sync will look for .agents, .claude, .codex, and MCP configuration without modifying anything."
            )
        } actions: {
            DirectoryPickerButton {
                Text("Add Projects Folder")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, minHeight: 280)
    }

    private var workspaceList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Workspaces")
                .font(.headline)

            ForEach(model.workspaces) { workspace in
                Button {
                    model.selection = .workspace(workspace.id)
                } label: {
                    HStack(spacing: 12) {
                        Image(
                            systemName: workspace.rootURL == AppModel.homeURL ? "globe" : "folder"
                        )
                        .foregroundStyle(.secondary)
                        .frame(width: 20)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(workspace.rootURL == AppModel.homeURL ? "Global" : workspace.name)
                                .fontWeight(.medium)
                            Text(workspace.rootURL.path)
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        Spacer()
                        Text("\(workspace.skills.count) skills")
                            .foregroundStyle(.secondary)
                        if workspace.attentionCount > 0 {
                            Text("\(workspace.attentionCount) to review")
                                .foregroundStyle(workspace.conflictCount > 0 ? .red : .orange)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                Divider()
            }
        }
    }
}
