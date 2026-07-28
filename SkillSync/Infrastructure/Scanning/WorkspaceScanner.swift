import Foundation

actor WorkspaceScanner {
    private let fileSystem: SkillFileSystem
    private let adapters: [any AgentAdapter]
    private let fileManager: FileManager

    init(
        fileSystem: SkillFileSystem,
        adapters: [any AgentAdapter] = [
            AgentsStandardAdapter(),
            ClaudeCodeAdapter(),
            CodexLegacyAdapter(),
        ],
        fileManager: FileManager = .default
    ) {
        self.fileSystem = fileSystem
        self.adapters = adapters
        self.fileManager = fileManager
    }

    func discoverProjects(in watchedRoot: URL, maximumDepth: Int = 4) async throws -> [URL] {
        var projects: Set<URL> = []
        var pending: [(URL, Int)] = [(watchedRoot.standardizedFileURL, 0)]
        let skippedNames: Set<String> = [
            ".build", ".git", ".swiftpm", "DerivedData", "Pods", "node_modules", "vendor",
        ]

        while let (directory, depth) = pending.popLast() {
            if isProject(at: directory) {
                projects.insert(directory)
            }
            guard depth < maximumDepth else { continue }
            let children = try fileManager.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.isDirectoryKey, .isSymbolicLinkKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            )
            for child in children where !skippedNames.contains(child.lastPathComponent) {
                let values = try child.resourceValues(forKeys: [
                    .isDirectoryKey, .isSymbolicLinkKey,
                ])
                guard values.isDirectory == true, values.isSymbolicLink != true else { continue }
                pending.append((child, depth + 1))
            }
        }
        return projects.sorted { $0.path.localizedStandardCompare($1.path) == .orderedAscending }
    }

    func scanProject(at projectURL: URL) async throws -> Workspace {
        var grouped: [String: [SkillInstallation]] = [:]
        for adapter in adapters {
            let root = adapter.projectSkillRoot(in: projectURL)
            let directories = try await fileSystem.skillDirectories(at: root)
            for directory in directories {
                let installation = try await fileSystem.installation(
                    at: directory,
                    agent: adapter.kind
                )
                grouped[directory.lastPathComponent, default: []].append(installation)
            }
        }

        let skills = grouped.map { name, installations in
            SkillRecord(
                name: name,
                status: classify(installations),
                installations: installations.sorted { $0.agent.rawValue < $1.agent.rawValue }
            )
        }
        .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }

        return Workspace(rootURL: projectURL, skills: skills, scannedAt: .now)
    }

    private func isProject(at url: URL) -> Bool {
        let markers = [".git", ".agents", ".claude", ".codex", ".mcp.json"]
        return markers.contains { fileManager.fileExists(atPath: url.appending(path: $0).path) }
    }

    private func classify(_ installations: [SkillInstallation]) -> SkillStatus {
        if installations.contains(where: { $0.kind == .brokenSymbolicLink }) {
            return .brokenLink
        }
        let canonical = installations.first { $0.agent == .agentsStandard }
        guard let canonical else {
            return installations.contains(where: { $0.kind == .directory })
                ? .needsMigration
                : .unmanaged
        }
        let otherInstallations = installations.filter { $0.agent != .agentsStandard }
        guard !otherInstallations.isEmpty else { return .canonical }
        if otherInstallations.allSatisfy({ installation in
            installation.kind == .symbolicLink
                && installation.symbolicLinkDestination?
                    .resolvingSymlinksInPath().standardizedFileURL.path
                    == canonical.url.resolvingSymlinksInPath().standardizedFileURL.path
        }) {
            return .linked
        }
        let physicalCopies = otherInstallations.filter { $0.kind == .directory }
        guard !physicalCopies.isEmpty else { return .unmanaged }
        return physicalCopies.allSatisfy { $0.fingerprint == canonical.fingerprint }
            ? .identicalDuplicate
            : .conflict
    }
}
