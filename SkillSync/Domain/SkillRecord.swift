import Foundation

enum SkillInstallationKind: String, Codable, Hashable, Sendable {
    case directory
    case symbolicLink
    case brokenSymbolicLink
}

struct SkillInstallation: Codable, Hashable, Identifiable, Sendable {
    let agent: AgentKind
    let url: URL
    let kind: SkillInstallationKind
    let fingerprint: String?
    let symbolicLinkDestination: URL?

    var id: String { "\(agent.rawValue):\(url.path)" }
}

enum SkillStatus: String, Codable, CaseIterable, Hashable, Sendable {
    case canonical
    case linked
    case needsMigration
    case identicalDuplicate
    case conflict
    case brokenLink
    case unmanaged

    var requiresAttention: Bool {
        switch self {
        case .needsMigration, .identicalDuplicate, .conflict, .brokenLink:
            true
        case .canonical, .linked, .unmanaged:
            false
        }
    }
}

struct SkillRecord: Codable, Hashable, Identifiable, Sendable {
    let name: String
    let status: SkillStatus
    let installations: [SkillInstallation]

    var id: String { name }

    var canonicalInstallation: SkillInstallation? {
        installations.first { $0.agent == .agentsStandard }
    }

    var attentionSummary: String {
        switch status {
        case .canonical:
            "Canonical"
        case .linked:
            "In sync"
        case .needsMigration:
            "Ready to consolidate"
        case .identicalDuplicate:
            "Safe duplicate"
        case .conflict:
            "Contents differ"
        case .brokenLink:
            "Broken link"
        case .unmanaged:
            "Unmanaged"
        }
    }
}
