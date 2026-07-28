import Foundation
import Testing

@testable import SkillSync

@Suite("Skills catalog")
struct SkillsCatalogTests {
    @Test("Decodes the live skills.sh field names")
    func decodesSearchResult() throws {
        let data = Data(
            #"{"id":"example/skills/review","skillId":"review","name":"code review","installs":42,"source":"example/skills"}"#
                .utf8
        )

        let skill = try JSONDecoder().decode(CatalogSkill.self, from: data)

        #expect(skill.skillID == "review")
        #expect(skill.displayName == "Code Review")
    }

    @Test("Builds a pinned project install with Codex and Claude Code")
    func projectInstallCommand() {
        let skill = CatalogSkill(
            id: "example/skills/review",
            skillID: "review",
            name: "review",
            installs: 42,
            source: "example/skills"
        )
        let project = URL(filePath: "/tmp/project", directoryHint: .isDirectory)

        let command = SkillsCLI.installCommand(skill: skill, target: .project(project))

        #expect(command.arguments.contains("skills@\(SkillsCLI.pinnedVersion)"))
        #expect(command.arguments.contains("codex"))
        #expect(command.arguments.contains("claude-code"))
        #expect(!command.arguments.contains("--global"))
        #expect(command.currentDirectoryURL == project)
    }

    @Test("Global installs are explicit and telemetry settings are not command arguments")
    func globalInstallCommand() {
        let skill = CatalogSkill(
            id: "example/skills/review",
            skillID: "review",
            name: "review",
            installs: 42,
            source: "example/skills"
        )

        let command = SkillsCLI.installCommand(skill: skill, target: .global)

        #expect(command.arguments.contains("--global"))
        #expect(command.preview.hasPrefix("npx --yes skills@"))
        #expect(!command.preview.contains("DISABLE_TELEMETRY"))
    }
}
