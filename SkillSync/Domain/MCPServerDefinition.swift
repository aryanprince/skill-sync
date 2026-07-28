import Foundation

enum MCPTransport: String, Codable, CaseIterable, Hashable, Sendable {
    case stdio
    case http
    case sse
}

enum MCPConfigurationScope: String, Codable, CaseIterable, Hashable, Sendable {
    case local
    case project
    case user
}

struct MCPEnvironmentEntry: Codable, Hashable, Identifiable, Sendable {
    let key: String
    var value: String
    var isSecret: Bool

    var id: String { key }
}

struct MCPHeader: Codable, Hashable, Identifiable, Sendable {
    let name: String
    var value: String
    var isSecret: Bool

    var id: String { name }
}

struct MCPServerDefinition: Codable, Hashable, Identifiable, Sendable {
    var name: String
    var transport: MCPTransport
    var command: [String]
    var url: URL?
    var environment: [MCPEnvironmentEntry]
    var headers: [MCPHeader]
    var scope: MCPConfigurationScope
    var sourceURL: URL?

    var id: String { name }
}
