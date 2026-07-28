import Foundation

struct SkillsCommand: Equatable, Sendable {
    let arguments: [String]
    let currentDirectoryURL: URL

    var preview: String {
        (["npx"] + arguments).map(Self.shellQuote).joined(separator: " ")
    }

    private static func shellQuote(_ value: String) -> String {
        let safe = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-._/@"))
        if value.unicodeScalars.allSatisfy({ safe.contains($0) }) {
            return value
        }
        return "'\(value.replacingOccurrences(of: "'", with: "'\\''"))'"
    }
}

enum SkillsCLIError: LocalizedError {
    case npxNotFound
    case commandFailed(String)

    var errorDescription: String? {
        switch self {
        case .npxNotFound:
            "npx was not found. Install Node.js 22 or newer, then reopen Skill Sync."
        case let .commandFailed(message):
            message.isEmpty ? "The skills command failed." : message
        }
    }
}

actor SkillsCLI {
    static let pinnedVersion = "1.5.20"

    private let runner: ProcessRunner

    init(runner: ProcessRunner = ProcessRunner()) {
        self.runner = runner
    }

    static func installCommand(
        skill: CatalogSkill,
        target: SkillInstallationTarget
    ) -> SkillsCommand {
        var arguments = [
            "--yes",
            "skills@\(pinnedVersion)",
            "add",
            skill.source,
            "--skill",
            skill.skillID,
            "--agent",
            "codex",
            "claude-code",
            "--yes",
        ]
        if case .global = target {
            arguments.append("--global")
        }
        return SkillsCommand(arguments: arguments, currentDirectoryURL: target.workingDirectory)
    }

    static func updateCommand(target: SkillInstallationTarget) -> SkillsCommand {
        var arguments = ["--yes", "skills@\(pinnedVersion)", "update", "--yes"]
        if case .global = target {
            arguments.append("--global")
        } else {
            arguments.append("--project")
        }
        return SkillsCommand(arguments: arguments, currentDirectoryURL: target.workingDirectory)
    }

    func install(skill: CatalogSkill, target: SkillInstallationTarget) async throws -> String {
        try await execute(Self.installCommand(skill: skill, target: target))
    }

    func update(target: SkillInstallationTarget) async throws -> String {
        try await execute(Self.updateCommand(target: target))
    }

    private func execute(_ command: SkillsCommand) async throws -> String {
        guard let executableURL = ExecutableLocator.locate("npx") else {
            throw SkillsCLIError.npxNotFound
        }

        let result = try await runner.run(
            ProcessRequest(
                executableURL: executableURL,
                arguments: command.arguments,
                environment: [
                    "DISABLE_TELEMETRY": "1",
                    "DO_NOT_TRACK": "1",
                    "NO_COLOR": "1",
                ],
                currentDirectoryURL: command.currentDirectoryURL,
                timeout: 180,
                secretValues: []
            )
        )
        guard result.succeeded else {
            throw SkillsCLIError.commandFailed(
                result.standardError.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        }
        return result.standardOutput.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
