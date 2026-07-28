import Foundation

struct ReconciliationPlanner {
    func plan(for workspace: Workspace, backupRoot: URL = ApplicationPaths.backups)
        -> ReconciliationPlan
    {
        let planID = UUID()
        var operations: [PlannedOperation] = []
        var affectedNames: [String] = []
        var conflictNames: [String] = []
        let canonicalRoot = workspace.rootURL.appending(
            path: ".agents/skills",
            directoryHint: .isDirectory
        )

        for skill in workspace.skills {
            switch skill.status {
            case .needsMigration:
                guard let source = preferredPhysicalSource(for: skill) else { continue }
                let destination = canonicalRoot.appending(
                    path: skill.name,
                    directoryHint: .isDirectory
                )
                operations.append(.createDirectory(canonicalRoot))
                operations.append(.move(source: source.url, destination: destination))
                operations.append(.createSymbolicLink(link: source.url, destination: destination))
                affectedNames.append(skill.name)
            case .identicalDuplicate:
                guard let canonical = skill.canonicalInstallation else { continue }
                for duplicate in skill.installations
                where duplicate.agent != .agentsStandard && duplicate.kind == .directory {
                    let backup =
                        backupRoot
                        .appending(path: planID.uuidString, directoryHint: .isDirectory)
                        .appending(path: duplicate.agent.rawValue, directoryHint: .isDirectory)
                        .appending(path: skill.name, directoryHint: .isDirectory)
                    operations.append(.backup(source: duplicate.url, destination: backup))
                    operations.append(
                        .createSymbolicLink(link: duplicate.url, destination: canonical.url)
                    )
                }
                affectedNames.append(skill.name)
            case .conflict, .brokenLink:
                conflictNames.append(skill.name)
            case .canonical, .linked, .unmanaged:
                continue
            }
        }

        return ReconciliationPlan(
            id: planID,
            workspaceURL: workspace.rootURL,
            createdAt: .now,
            operations: operations,
            affectedSkillNames: affectedNames,
            skippedConflictNames: conflictNames
        )
    }

    private func preferredPhysicalSource(for skill: SkillRecord) -> SkillInstallation? {
        skill.installations.first { installation in
            installation.kind == .directory && installation.agent == .claudeCode
        } ?? skill.installations.first { $0.kind == .directory }
    }
}
