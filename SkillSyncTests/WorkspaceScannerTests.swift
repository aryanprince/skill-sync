import Foundation
import Testing

@testable import SkillSync

@Suite("Workspace scanner")
struct WorkspaceScannerTests {
    @Test("Claude-only skills are ready to migrate")
    func findsClaudeOnlySkill() async throws {
        let directory = try TestDirectory()
        _ = try directory.makeSkill(at: ".claude/skills", name: "example")

        let workspace = try await makeScanner().scanProject(at: directory.url)

        #expect(workspace.skills.count == 1)
        #expect(workspace.skills.first?.status == .needsMigration)
    }

    @Test("Identical physical copies are classified as safe duplicates")
    func findsIdenticalDuplicate() async throws {
        let directory = try TestDirectory()
        _ = try directory.makeSkill(at: ".agents/skills", name: "example")
        _ = try directory.makeSkill(at: ".claude/skills", name: "example")

        let workspace = try await makeScanner().scanProject(at: directory.url)

        #expect(workspace.skills.first?.status == .identicalDuplicate)
    }

    @Test("Different same-name skills are conflicts")
    func findsConflict() async throws {
        let directory = try TestDirectory()
        _ = try directory.makeSkill(at: ".agents/skills", name: "example", body: "Agents")
        _ = try directory.makeSkill(at: ".claude/skills", name: "example", body: "Claude")

        let workspace = try await makeScanner().scanProject(at: directory.url)

        #expect(workspace.skills.first?.status == .conflict)
        #expect(workspace.conflictCount == 1)
    }

    @Test("Claude links to .agents are healthy")
    func findsHealthyLink() async throws {
        let directory = try TestDirectory()
        let destination = try directory.makeSkill(at: ".agents/skills", name: "example")
        let link = directory.url.appending(path: ".claude/skills/example")
        try FileManager.default.createDirectory(
            at: link.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try FileManager.default.createSymbolicLink(
            atPath: link.path,
            withDestinationPath: "../../.agents/skills/example"
        )

        let workspace = try await makeScanner().scanProject(at: directory.url)

        #expect(workspace.skills.first?.status == .linked)
        #expect(link.resolvingSymlinksInPath() == destination.standardizedFileURL)
    }

    private func makeScanner() -> WorkspaceScanner {
        WorkspaceScanner(fileSystem: SkillFileSystem())
    }
}
