import Foundation

protocol AgentAdapter: Sendable {
    var kind: AgentKind { get }
    var projectSkillPath: String { get }
    var globalSkillPath: String { get }

    func projectSkillRoot(in projectURL: URL) -> URL
    func globalSkillRoot(homeURL: URL) -> URL
}

extension AgentAdapter {
    func projectSkillRoot(in projectURL: URL) -> URL {
        projectURL.appending(path: projectSkillPath, directoryHint: .isDirectory)
    }

    func globalSkillRoot(homeURL: URL) -> URL {
        homeURL.appending(path: globalSkillPath, directoryHint: .isDirectory)
    }
}
