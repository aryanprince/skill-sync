import Foundation

struct Workspace: Codable, Hashable, Identifiable, Sendable {
    let rootURL: URL
    let skills: [SkillRecord]
    let scannedAt: Date

    var id: String { rootURL.standardizedFileURL.path }
    var name: String { rootURL.lastPathComponent }

    var attentionCount: Int {
        skills.count { $0.status.requiresAttention }
    }

    var conflictCount: Int {
        skills.count { $0.status == .conflict }
    }

    var isClean: Bool { attentionCount == 0 }
}
