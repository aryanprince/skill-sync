import Foundation

enum PlannedOperation: Codable, Hashable, Identifiable, Sendable {
    case createDirectory(URL)
    case move(source: URL, destination: URL)
    case backup(source: URL, destination: URL)
    case createSymbolicLink(link: URL, destination: URL)

    var id: String {
        switch self {
        case let .createDirectory(url):
            "mkdir:\(url.path)"
        case let .move(source, destination):
            "move:\(source.path):\(destination.path)"
        case let .backup(source, destination):
            "backup:\(source.path):\(destination.path)"
        case let .createSymbolicLink(link, destination):
            "link:\(link.path):\(destination.path)"
        }
    }

    var summary: String {
        switch self {
        case let .createDirectory(url):
            "Create \(url.path)"
        case let .move(source, destination):
            "Move \(source.lastPathComponent) to \(destination.deletingLastPathComponent().path)"
        case let .backup(source, destination):
            "Back up \(source.lastPathComponent) to \(destination.path)"
        case let .createSymbolicLink(link, destination):
            "Link \(link.path) to \(destination.path)"
        }
    }
}

struct ReconciliationPlan: Codable, Hashable, Identifiable, Sendable {
    let id: UUID
    let workspaceURL: URL
    let createdAt: Date
    let operations: [PlannedOperation]
    let affectedSkillNames: [String]
    let skippedConflictNames: [String]

    var isEmpty: Bool { operations.isEmpty }
}

struct OperationReceipt: Codable, Hashable, Identifiable, Sendable {
    let id: UUID
    let planID: UUID
    let completedAt: Date
    let appliedOperations: [PlannedOperation]
    let reversalOperations: [PlannedOperation]
}
