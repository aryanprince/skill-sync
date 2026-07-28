import Foundation
import Testing

@testable import SkillSync

@Suite("MCP integrations")
struct MCPIntegrationTests {
    @Test("Codex project commands isolate configuration in .codex")
    func codexProjectCommand() throws {
        let project = URL(filePath: "/tmp/project", directoryHint: .isDirectory)
        let request = MCPInstallationRequest(
            definition: MCPServerDefinition(
                name: "example",
                transport: .stdio,
                command: ["npx", "-y", "example-mcp"],
                url: nil,
                environment: [MCPEnvironmentEntry(key: "API_KEY", value: "secret", isSecret: true)],
                headers: [],
                scope: .project,
                sourceURL: nil
            ),
            location: .project(project),
            agents: [.codex],
            bearerTokenEnvironmentVariable: nil
        )

        let command = try CodexMCPAdapter.addCommand(for: request)

        #expect(command.environment["CODEX_HOME"] == "/tmp/project/.codex")
        #expect(command.arguments.contains("API_KEY=secret"))
        #expect(command.secretValues == ["secret"])
        #expect(command.arguments.suffix(3) == ["npx", "-y", "example-mcp"])
    }

    @Test("Claude project commands use project scope and redact headers")
    func claudeProjectCommand() throws {
        let request = MCPInstallationRequest(
            definition: MCPServerDefinition(
                name: "remote",
                transport: .http,
                command: [],
                url: URL(string: "https://example.com/mcp"),
                environment: [],
                headers: [MCPHeader(name: "Authorization", value: "Bearer token", isSecret: true)],
                scope: .project,
                sourceURL: nil
            ),
            location: .project(URL(filePath: "/tmp/project")),
            agents: [.claudeCode],
            bearerTokenEnvironmentVariable: nil
        )

        let command = try ClaudeMCPAdapter.addCommand(for: request)

        #expect(command.arguments.contains("project"))
        #expect(command.arguments.contains("Authorization: Bearer token"))
        #expect(command.secretValues == ["Bearer token"])
    }

    @Test("Command parser preserves quoted arguments")
    func commandParser() {
        #expect(
            CommandLineParser.parse(#"npx -y "package name" --flag='two words'"#)
                == ["npx", "-y", "package name", "--flag=two words"]
        )
    }

    @Test("Decodes an official registry server envelope")
    func registryServerDecoding() throws {
        let json = #"""
            {
              "name": "io.example/files",
              "description": "Files",
              "version": "1.0.0",
              "packages": [{
                "registryType": "npm",
                "identifier": "example-mcp",
                "version": "1.0.0",
                "transport": {"type": "stdio"},
                "environmentVariables": [{
                  "name": "API_KEY",
                  "isRequired": true,
                  "isSecret": true
                }]
              }]
            }
            """#
        let data = Data(json.utf8)

        let server = try JSONDecoder().decode(RegistryMCPServer.self, from: data)

        #expect(server.preferredPackage?.identifier == "example-mcp")
        #expect(server.preferredPackage?.environmentVariables?.first?.isSecret == true)
    }
}
