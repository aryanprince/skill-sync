import Foundation

struct CatalogSkill: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let skillID: String
    let name: String
    let installs: Int
    let source: String

    private enum CodingKeys: String, CodingKey {
        case id
        case skillID = "skillId"
        case name
        case installs
        case source
    }

    var displayName: String {
        name.split(separator: " ").map { word in
            word.prefix(1).uppercased() + word.dropFirst()
        }.joined(separator: " ")
    }
}

enum SkillInstallationTarget: Hashable, Identifiable, Sendable {
    case global
    case project(URL)

    var id: String {
        switch self {
        case .global: "global"
        case let .project(url): "project:\(url.standardizedFileURL.path)"
        }
    }

    var workingDirectory: URL {
        switch self {
        case .global: FileManager.default.homeDirectoryForCurrentUser.standardizedFileURL
        case let .project(url): url
        }
    }

    var displayName: String {
        switch self {
        case .global: "Global"
        case let .project(url): url.lastPathComponent
        }
    }
}
