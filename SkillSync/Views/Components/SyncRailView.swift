import SwiftUI

struct SyncRailView: View {
    let workspace: Workspace

    private struct RailItem {
        let title: String
        let detail: String
        let tint: Color
    }

    private var agents: [RailItem] {
        let hasCanonical = workspace.skills.contains { $0.canonicalInstallation != nil }
        let claudeInstallations = workspace.skills.flatMap(\.installations).filter {
            $0.agent == .claudeCode
        }
        let claudeIsLinked =
            !claudeInstallations.isEmpty
            && claudeInstallations.allSatisfy { $0.kind == .symbolicLink }

        return [
            RailItem(
                title: ".agents",
                detail: "Canonical",
                tint: hasCanonical ? .green : .secondary.opacity(0.35)
            ),
            RailItem(
                title: "Codex",
                detail: hasCanonical ? "Reads .agents" : "Not configured",
                tint: hasCanonical ? .green : .secondary.opacity(0.35)
            ),
            RailItem(
                title: "Claude Code",
                detail: claudeIsLinked ? "Linked" : "Separate copies",
                tint: claudeIsLinked ? .green : .orange
            ),
        ]
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(agents.enumerated()), id: \.offset) { index, agent in
                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(agent.tint)
                                .frame(width: 7, height: 7)
                            Text(agent.title)
                                .font(.system(.body, design: index == 0 ? .monospaced : .default))
                                .fontWeight(index == 0 ? .semibold : .regular)
                        }
                        Text(agent.detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    if index < agents.count - 1 {
                        Image(systemName: "arrow.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .padding(.horizontal, 16)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.appSecondaryCanvas, in: RoundedRectangle(cornerRadius: 10))
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.appSeparator.opacity(0.65))
        }
    }
}
