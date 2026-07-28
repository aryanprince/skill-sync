import Foundation

actor CodexMCPAdapter {
    private struct ListedServer: Decodable {
        struct Transport: Decodable {
            let type: String
            let command: String?
            let args: [String]?
            let url: String?
        }

        let name: String
        let enabled: Bool
        let authStatus: String?
        let transport: Transport

        private enum CodingKeys: String, CodingKey {
            case name
            case enabled
            case authStatus = "auth_status"
            case transport
        }
    }

    private let runner: ProcessRunner
    private let fileManager: FileManager

    init(runner: ProcessRunner = ProcessRunner(), fileManager: FileManager = .default) {
        self.runner = runner
        self.fileManager = fileManager
    }

    static func addCommand(for request: MCPInstallationRequest) throws -> MCPCommand {
        let definition = request.definition
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
            arguments.append(definition.name)
            arguments.append("--")
            arguments.append(contentsOf: definition.command)
        case .http, .sse:
            guard let url = definition.url else {
                throw MCPAdapterError.invalidDefinition("Enter a URL for the remote server.")
            }
            arguments.append(contentsOf: [definition.name, "--url", url.absoluteString])
            if let variable = request.bearerTokenEnvironmentVariable,
                !variable.trimmingCharacters(in: .whitespaces).isEmpty
            {
                arguments.append(contentsOf: ["--bearer-token-env-var", variable])
            }
        }

        return MCPCommand(
            executableName: "codex",
            arguments: arguments,
            environment: environment(for: request.location),
            currentDirectoryURL: request.location.projectURL,
            secretValues: secrets
        )
    }

    static func removeCommand(name: String, location: MCPInstallLocation) -> MCPCommand {
        MCPCommand(
            executableName: "codex",
            arguments: ["mcp", "remove", name],
            environment: environment(for: location),
            currentDirectoryURL: location.projectURL,
            secretValues: []
        )
    }

    func list(location: MCPInstallLocation) async throws -> [ConfiguredMCPServer] {
        if case let .project(url) = location {
            let config = url.appending(path: ".codex/config.toml")
            guard fileManager.fileExists(atPath: config.path) else { return [] }
        }

        let result = try await execute(
            MCPCommand(
                executableName: "codex",
                arguments: ["mcp", "list", "--json"],
                environment: Self.environment(for: location),
                currentDirectoryURL: location.projectURL,
                secretValues: []
            )
        )
        do {
            return try JSONDecoder().decode([ListedServer].self, from: Data(result.utf8)).map {
                server in
                let transport: MCPTransport =
                    server.transport.type == "stdio" ? .stdio : .http
                let endpoint =
                    server.transport.url
                    ?? ([server.transport.command] + (server.transport.args ?? []))
                    .compactMap { $0 }
                    .joined(separator: " ")
                return ConfiguredMCPServer(
                    name: server.name,
                    agent: .codex,
                    location: location,
                    transport: transport,
                    endpointSummary: endpoint,
                    isEnabled: server.enabled,
                    authenticationStatus: server.authStatus
                )
            }
        } catch {
            throw MCPAdapterError.unreadableResponse("Codex returned unreadable MCP data.")
        }
    }

    func add(_ request: MCPInstallationRequest) async throws {
        if case let .project(url) = request.location {
            try fileManager.createDirectory(
                at: url.appending(path: ".codex", directoryHint: .isDirectory),
                withIntermediateDirectories: true
            )
        }
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

    private static func environment(for location: MCPInstallLocation) -> [String: String] {
        guard case let .project(projectURL) = location else { return [:] }
        return ["CODEX_HOME": projectURL.appending(path: ".codex").path]
    }
}
