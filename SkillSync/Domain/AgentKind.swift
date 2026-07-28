import Foundation

enum AgentKind: String, Codable, CaseIterable, Hashable, Identifiable, Sendable {
    case agentsStandard
    case claudeCode
    case codexLegacy

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .agentsStandard:
            ".agents"
        case .claudeCode:
            "Claude Code"
        case .codexLegacy:
            "Codex (legacy)"
        }
    }
}
