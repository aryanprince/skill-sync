import SwiftUI

struct WorkspaceDetailView: View {
    @EnvironmentObject private var model: AppModel
    let workspace: Workspace

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    SyncRailView(workspace: workspace)
                    skillList
                }
                .padding(AppStyle.contentInset)
                .frame(maxWidth: 980, alignment: .leading)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(workspace.rootURL == AppModel.homeURL ? "Global Skills" : workspace.name)
                        .font(.system(size: 26, weight: .semibold))
                    Button(workspace.rootURL.path) {
                        model.reveal(workspace.rootURL)
                    }
                    .buttonStyle(.plain)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                }
                Spacer()
                if workspace.attentionCount > 0 {
                    Button("Review Cleanup", systemImage: "arrow.triangle.merge") {
                        model.prepareCleanup(for: workspace)
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Label("In sync", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }

            if workspace.conflictCount > 0 {
                Label(
                    "\(workspace.conflictCount) conflict(s) require a manual choice and will be skipped.",
                    systemImage: "exclamationmark.triangle.fill"
                )
                .font(.callout)
                .foregroundStyle(.red)
            }
        }
    }

    private var skillList: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Skill")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Installations")
                    .frame(width: 180, alignment: .leading)
                Text("Status")
                    .frame(width: 120, alignment: .leading)
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color.appSecondaryCanvas)

            if workspace.skills.isEmpty {
                Text("No skills found in this workspace.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                ForEach(workspace.skills) { skill in
                    SkillRow(skill: skill)
                    Divider()
                }
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.appSeparator.opacity(0.7))
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct SkillRow: View {
    let skill: SkillRecord

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(skill.name)
                    .fontWeight(.medium)
                Text(skill.attentionSummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 6) {
                ForEach(skill.installations) { installation in
                    Image(systemName: installation.kind == .directory ? "folder" : "link")
                        .foregroundStyle(
                            installation.kind == .brokenSymbolicLink ? .red : .secondary
                        )
                        .help("\(installation.agent.displayName): \(installation.url.path)")
                }
            }
            .frame(width: 180, alignment: .leading)

            StatusBadge(status: skill.status)
                .frame(width: 120, alignment: .leading)
        }
        .padding(.horizontal, 10)
        .frame(minHeight: AppStyle.rowHeight)
    }
}
