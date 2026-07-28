import Foundation
import Testing

@testable import SkillSync

@Suite("Reconciliation")
struct ReconciliationTests {
    @Test("Claude-only skill moves to .agents and can be undone")
    func migrateAndUndo() async throws {
        let directory = try TestDirectory()
        let original = try directory.makeSkill(at: ".claude/skills", name: "example")
        let fileSystem = SkillFileSystem()
        let scanner = WorkspaceScanner(fileSystem: fileSystem)
        let workspace = try await scanner.scanProject(at: directory.url)
        let backupRoot = directory.url.appending(path: "backups", directoryHint: .isDirectory)
        let plan = ReconciliationPlanner().plan(for: workspace, backupRoot: backupRoot)
        let executor = ReconciliationExecutor(fileSystem: fileSystem)

        #expect(plan.affectedSkillNames == ["example"])
        #expect(plan.operations.count == 3)

        let receipt = try await executor.apply(plan)
        let canonical = directory.url.appending(path: ".agents/skills/example")
        #expect(FileManager.default.fileExists(atPath: canonical.path))
        #expect(original.resolvingSymlinksInPath() == canonical.standardizedFileURL)

        try await executor.undo(receipt)
        #expect(FileManager.default.fileExists(atPath: original.appending(path: "SKILL.md").path))
        #expect(!FileManager.default.fileExists(atPath: canonical.path))
    }

    @Test("Conflicts never produce filesystem operations")
    func conflictIsSkipped() async throws {
        let directory = try TestDirectory()
        _ = try directory.makeSkill(at: ".agents/skills", name: "example", body: "Agents")
        _ = try directory.makeSkill(at: ".claude/skills", name: "example", body: "Claude")
        let scanner = WorkspaceScanner(fileSystem: SkillFileSystem())
        let workspace = try await scanner.scanProject(at: directory.url)

        let plan = ReconciliationPlanner().plan(for: workspace)

        #expect(plan.operations.isEmpty)
        #expect(plan.skippedConflictNames == ["example"])
    }
}
