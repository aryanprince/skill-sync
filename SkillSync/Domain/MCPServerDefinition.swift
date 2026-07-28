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
    var key: String
    var value: String
    var isSecret: Bool

    var id: String { key }
}

struct MCPHeader: Codable, Hashable, Identifiable, Sendable {
    var name: String
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

enum MCPAgent: String, Codable, CaseIterable, Hashable, Identifiable, Sendable {
    case codex
    case claudeCode

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .codex: "Codex"
        case .claudeCode: "Claude Code"
        }
    }
}

enum MCPInstallLocation: Hashable, Identifiable, Sendable {
    case global
    case project(URL)

    var id: String {
        switch self {
        case .global: "global"
        case let .project(url): "project:\(url.standardizedFileURL.path)"
        }
    }

    var displayName: String {
        switch self {
        case .global: "Global"
        case let .project(url): url.lastPathComponent
        }
    }

    var projectURL: URL? {
        guard case let .project(url) = self else { return nil }
        return url
    }
}

struct MCPInstallationRequest: Hashable, Sendable {
    var definition: MCPServerDefinition
    var location: MCPInstallLocation
    var agents: Set<MCPAgent>
    var bearerTokenEnvironmentVariable: String?
}

struct ConfiguredMCPServer: Hashable, Identifiable, Sendable {
    let name: String
    let agent: MCPAgent
    let location: MCPInstallLocation
    let transport: MCPTransport
    let endpointSummary: String
    let isEnabled: Bool
    let authenticationStatus: String?

    var id: String { "\(agent.rawValue):\(location.id):\(name)" }
}

struct RegistryMCPServer: Codable, Hashable, Identifiable, Sendable {
    struct Repository: Codable, Hashable, Sendable {
        let url: URL?
        let source: String?
    }

    struct EnvironmentVariable: Codable, Hashable, Identifiable, Sendable {
        let name: String
        let description: String?
        let isRequired: Bool?
        let isSecret: Bool?
        let `default`: String?

        var id: String { name }
    }

    struct Package: Codable, Hashable, Sendable {
        struct Transport: Codable, Hashable, Sendable {
            let type: String
        }

        let registryType: String
        let identifier: String
        let version: String?
        let runtimeHint: String?
        let transport: Transport?
        let environmentVariables: [EnvironmentVariable]?
    }

    struct Remote: Codable, Hashable, Sendable {
        let type: String
        let url: URL
    }

    let name: String
    let description: String?
    let version: String
    let repository: Repository?
    let packages: [Package]?
    let remotes: [Remote]?

    var id: String { "\(name):\(version)" }

    var displayName: String {
        name.split(separator: "/").last.map(String.init) ?? name
    }

    var preferredPackage: Package? {
        packages?.first { $0.registryType == "npm" } ?? packages?.first
    }
}
