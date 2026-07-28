import Foundation

actor MCPService {
    private let codex: CodexMCPAdapter
    private let claude: ClaudeMCPAdapter

    init(
        codex: CodexMCPAdapter = CodexMCPAdapter(),
        claude: ClaudeMCPAdapter = ClaudeMCPAdapter()
    ) {
        self.codex = codex
        self.claude = claude
    }

    func list(locations: [MCPInstallLocation]) async -> [ConfiguredMCPServer] {
        var result: [ConfiguredMCPServer] = []
        for location in locations {
            if let servers = try? await codex.list(location: location) {
                result.append(contentsOf: servers)
            }
            if let servers = try? await claude.list(location: location) {
                result.append(contentsOf: servers)
            }
        }
        return result.sorted {
            if $0.name == $1.name { return $0.agent.rawValue < $1.agent.rawValue }
            return $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
    }

    func add(_ request: MCPInstallationRequest) async throws {
        if request.agents.contains(.codex) {
            try await codex.add(request)
        }
        if request.agents.contains(.claudeCode) {
            try await claude.add(request)
        }
    }

    func remove(_ server: ConfiguredMCPServer) async throws {
        switch server.agent {
        case .codex:
            try await codex.remove(name: server.name, location: server.location)
        case .claudeCode:
            try await claude.remove(name: server.name, location: server.location)
        }
    }
}
