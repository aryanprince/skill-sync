import Foundation

struct ClaudeMCPScanner: Sendable {
    func scan(location: MCPInstallLocation) throws -> [ConfiguredMCPServer] {
        let object: [String: Any]
        switch location {
        case .global:
            let url = FileManager.default.homeDirectoryForCurrentUser.appending(
                path: ".claude.json")
            guard let root = try readObject(at: url) else { return [] }
            object = root["mcpServers"] as? [String: Any] ?? [:]
        case let .project(projectURL):
            let url = projectURL.appending(path: ".mcp.json")
            guard let root = try readObject(at: url) else { return [] }
            object = root["mcpServers"] as? [String: Any] ?? [:]
        }

        return object.compactMap { name, rawDefinition in
            guard let definition = rawDefinition as? [String: Any] else { return nil }
            let url = definition["url"] as? String
            let command = definition["command"] as? String
            let arguments = definition["args"] as? [String] ?? []
            let declaredType = definition["type"] as? String
            let transport: MCPTransport =
                declaredType == "sse" ? .sse : (url == nil ? .stdio : .http)
            return ConfiguredMCPServer(
                name: name,
                agent: .claudeCode,
                location: location,
                transport: transport,
                endpointSummary: url
                    ?? ([command] + arguments).compactMap { $0 }.joined(separator: " "),
                isEnabled: true,
                authenticationStatus: nil
            )
        }
        .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    private func readObject(at url: URL) throws -> [String: Any]? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        let data = try Data(contentsOf: url)
        return try JSONSerialization.jsonObject(with: data) as? [String: Any]
    }
}
