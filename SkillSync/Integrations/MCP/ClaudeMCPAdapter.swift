import Foundation

actor ClaudeMCPAdapter {
    private let runner: ProcessRunner
    private let scanner: ClaudeMCPScanner

    init(runner: ProcessRunner = ProcessRunner(), scanner: ClaudeMCPScanner = ClaudeMCPScanner()) {
        self.runner = runner
        self.scanner = scanner
    }

    static func addCommand(for request: MCPInstallationRequest) throws -> MCPCommand {
        let definition = request.definition
        let scope = request.location.projectURL == nil ? "user" : "project"
        var arguments = ["mcp", "add"]
        var secrets = Set<String>()

        switch definition.transport {
        case .stdio:
            guard !definition.command.isEmpty else {
                throw MCPAdapterError.invalidDefinition("Enter a command for the stdio server.")
            }
            for entry in definition.environment where !entry.key.isEmpty {
                arguments.append(contentsOf: ["--env", "\(entry.key)=\(entry.value)"])
                if entry.isSecret { secrets.insert(entry.value) }
            }
            arguments.append(contentsOf: ["--transport", "stdio", "--scope", scope])
            arguments.append(definition.name)
            arguments.append("--")
            arguments.append(contentsOf: definition.command)
        case .http, .sse:
            guard let url = definition.url else {
                throw MCPAdapterError.invalidDefinition("Enter a URL for the remote server.")
            }
            for header in definition.headers where !header.name.isEmpty {
                arguments.append(contentsOf: ["--header", "\(header.name): \(header.value)"])
                if header.isSecret { secrets.insert(header.value) }
            }
            arguments.append(
                contentsOf: [
                    "--transport", definition.transport.rawValue,
                    "--scope", scope,
                    definition.name,
                    url.absoluteString,
                ]
            )
        }

        return MCPCommand(
            executableName: "claude",
            arguments: arguments,
            environment: [:],
            currentDirectoryURL: request.location.projectURL,
            secretValues: secrets
        )
    }

    static func removeCommand(name: String, location: MCPInstallLocation) -> MCPCommand {
        MCPCommand(
            executableName: "claude",
            arguments: [
                "mcp", "remove", name, "--scope",
                location.projectURL == nil ? "user" : "project",
            ],
            environment: [:],
            currentDirectoryURL: location.projectURL,
            secretValues: []
        )
    }

    func list(location: MCPInstallLocation) async throws -> [ConfiguredMCPServer] {
        try scanner.scan(location: location)
    }

    func add(_ request: MCPInstallationRequest) async throws {
        _ = try await execute(Self.addCommand(for: request))
    }

    func remove(name: String, location: MCPInstallLocation) async throws {
        _ = try await execute(Self.removeCommand(name: name, location: location))
    }

    private func execute(_ command: MCPCommand) async throws -> String {
        guard let executableURL = ExecutableLocator.locate(command.executableName) else {
            throw MCPAdapterError.executableNotFound(command.executableName)
        }
        let result = try await runner.run(
            ProcessRequest(
                executableURL: executableURL,
                arguments: command.arguments,
                environment: command.environment,
                currentDirectoryURL: command.currentDirectoryURL,
                timeout: 45,
                secretValues: command.secretValues
            )
        )
        guard result.succeeded else {
            throw MCPAdapterError.commandFailed(
                result.standardError.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        }
        return result.standardOutput
    }
}
