import SwiftUI

struct SkillInstallView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss
    let skill: CatalogSkill

    @State private var targetID = SkillInstallationTarget.global.id

    private var targets: [SkillInstallationTarget] {
        [.global] + model.projectWorkspaces.map { .project($0.rootURL) }
    }

    private var selectedTarget: SkillInstallationTarget {
        targets.first { $0.id == targetID } ?? .global
    }

    private var command: SkillsCommand {
        SkillsCLI.installCommand(skill: skill, target: selectedTarget)
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Install \(skill.displayName)")
                    .font(.title2.weight(.semibold))
                Text("from \(skill.source)")
                    .font(.callout.monospaced())
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)

            Divider()

            Form {
                Picker("Install to", selection: $targetID) {
                    ForEach(targets) { target in
                        Text(target.displayName).tag(target.id)
                    }
                }

                LabeledContent("Canonical copy") {
                    Text(canonicalPath)
                        .font(.callout.monospaced())
                        .textSelection(.enabled)
                }
                LabeledContent("Codex") {
                    Label("Reads canonical copy", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
                LabeledContent("Claude Code") {
                    Label("Relative symlink", systemImage: "link")
                        .foregroundStyle(.green)
                }

                Section("Command preview") {
                    Text(command.preview)
                        .font(.caption.monospaced())
                        .textSelection(.enabled)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.appSecondaryCanvas, in: RoundedRectangle(cornerRadius: 6))
                    Text(
                        "Uses skills@\(SkillsCLI.pinnedVersion). Anonymous CLI telemetry is disabled."
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)

            Divider()

            HStack {
                Button("Cancel", role: .cancel) { dismiss() }
                Spacer()
                if model.isRunningSkillsCommand {
                    ProgressView()
                        .controlSize(.small)
                }
                Button("Install") {
                    Task {
                        if await model.installCatalogSkill(skill, target: selectedTarget) {
                            dismiss()
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(model.isRunningSkillsCommand)
            }
            .padding(16)
        }
        .frame(width: 620, height: 520)
    }

    private var canonicalPath: String {
        selectedTarget.workingDirectory
            .appending(path: ".agents/skills/\(skill.skillID)")
            .path
    }
}
