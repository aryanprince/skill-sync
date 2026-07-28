import SwiftUI

struct CleanupReviewView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss
    let plan: ReconciliationPlan

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Review Cleanup")
                    .font(.title2.weight(.semibold))
                Text(
                    "Skill Sync verifies each move, uses relative links, and rolls back if an operation fails."
                )
                .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if plan.isEmpty {
                        ContentUnavailableView(
                            "No Safe Changes",
                            systemImage: "checkmark.shield",
                            description: Text(
                                "Conflicts and broken links are never changed automatically.")
                        )
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(
                                "\(plan.affectedSkillNames.count) skills · \(plan.operations.count) operations"
                            )
                            .font(.headline)
                            Text(plan.affectedSkillNames.joined(separator: ", "))
                                .foregroundStyle(.secondary)
                        }

                        ForEach(plan.operations) { operation in
                            Label {
                                Text(operation.summary)
                                    .font(.callout.monospaced())
                                    .textSelection(.enabled)
                            } icon: {
                                Image(systemName: icon(for: operation))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    if !plan.skippedConflictNames.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Label(
                                "Skipped for manual review",
                                systemImage: "exclamationmark.triangle.fill"
                            )
                            .fontWeight(.medium)
                            .foregroundStyle(.red)
                            Text(plan.skippedConflictNames.joined(separator: ", "))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(20)
            }

            Divider()

            HStack {
                Button("Cancel", role: .cancel) {
                    model.pendingPlan = nil
                    dismiss()
                }
                Spacer()
                Button("Apply Safe Changes") {
                    Task { await model.applyPendingPlan() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(plan.isEmpty)
            }
            .padding(16)
        }
        .frame(width: 620, height: 520)
    }

    private func icon(for operation: PlannedOperation) -> String {
        switch operation {
        case .createDirectory: "folder.badge.plus"
        case .move: "arrow.right"
        case .backup: "archivebox"
        case .createSymbolicLink: "link.badge.plus"
        }
    }
}
