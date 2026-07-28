import Foundation

struct MCPCommand: Equatable, Sendable {
    let executableName: String
    let arguments: [String]
    let environment: [String: String]
    let currentDirectoryURL: URL?
    let secretValues: Set<String>

    var preview: String {
        ([executableName] + arguments).map(Self.shellQuote).joined(separator: " ")
    }

    private static func shellQuote(_ value: String) -> String {
        let safe = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-._/@"))
        if value.unicodeScalars.allSatisfy({ safe.contains($0) }) {
            return value
        }
        return "'\(value.replacingOccurrences(of: "'", with: "'\\''"))'"
    }
}

enum MCPAdapterError: LocalizedError {
    case executableNotFound(String)
    case invalidDefinition(String)
    case commandFailed(String)
    case unreadableResponse(String)

    var errorDescription: String? {
        switch self {
        case let .executableNotFound(name):
            "\(name) was not found. Install it and reopen Skill Sync."
        case let .invalidDefinition(message), let .commandFailed(message),
            let .unreadableResponse(message):
            message
        }
    }
}
