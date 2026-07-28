import Foundation
import Testing

@testable import SkillSync

@Suite("Skill filesystem")
struct SkillFileSystemTests {
    @Test("Relative links point from agent folders to the canonical skill")
    func relativeLinkPath() {
        let project = URL(filePath: "/tmp/project", directoryHint: .isDirectory)
        let sourceDirectory = project.appending(path: ".claude/skills", directoryHint: .isDirectory)
        let destination = project.appending(
            path: ".agents/skills/find-docs",
            directoryHint: .isDirectory
        )

        #expect(
            SkillFileSystem.relativePath(from: sourceDirectory, to: destination)
                == "../../.agents/skills/find-docs"
        )
    }

    @Test("Fingerprint changes when skill content changes")
    func fingerprintTracksContent() async throws {
        let directory = try TestDirectory()
        let skillURL = try directory.makeSkill(at: ".agents/skills", name: "example")
        let fileSystem = SkillFileSystem()

        let original = try await fileSystem.fingerprintDirectory(at: skillURL)
        try Data("Changed".utf8).write(
            to: skillURL.appending(path: "notes.txt"),
            options: .atomic
        )
        let changed = try await fileSystem.fingerprintDirectory(at: skillURL)

        #expect(original != changed)
    }

    @Test("Created links are relative and resolve to the destination")
    func createsRelativeLink() async throws {
        let directory = try TestDirectory()
        let destination = try directory.makeSkill(at: ".agents/skills", name: "example")
        let link = directory.url.appending(
            path: ".claude/skills/example",
            directoryHint: .isDirectory
        )
        let fileSystem = SkillFileSystem()

        try await fileSystem.createRelativeSymbolicLink(at: link, destination: destination)

        let storedPath = try FileManager.default.destinationOfSymbolicLink(atPath: link.path)
        #expect(storedPath == "../../.agents/skills/example")
        #expect(
            link.resolvingSymlinksInPath().standardizedFileURL.path
                == destination.resolvingSymlinksInPath().standardizedFileURL.path
        )
    }
}
