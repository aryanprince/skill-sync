import Foundation

enum MCPRegistryError: LocalizedError {
    case invalidRequest
    case invalidResponse
    case serviceError(Int)

    var errorDescription: String? {
        switch self {
        case .invalidRequest: "The MCP Registry request could not be created."
        case .invalidResponse: "The MCP Registry returned unreadable data."
        case let .serviceError(status): "The MCP Registry returned HTTP \(status)."
        }
    }
}

actor MCPRegistryClient {
    private struct Envelope: Decodable {
        struct Entry: Decodable {
            let server: RegistryMCPServer
        }

        let servers: [Entry]
    }

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func search(_ query: String) async throws -> [RegistryMCPServer] {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "registry.modelcontextprotocol.io"
        components.path = "/v0.1/servers"
        components.queryItems = [
            URLQueryItem(name: "limit", value: "50"),
            URLQueryItem(name: "version", value: "latest"),
            URLQueryItem(name: "search", value: query),
        ]
        guard let url = components.url else { throw MCPRegistryError.invalidRequest }

        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("SkillSync/0.1", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw MCPRegistryError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw MCPRegistryError.serviceError(httpResponse.statusCode)
        }
        do {
            return try JSONDecoder().decode(Envelope.self, from: data).servers.map(\.server)
        } catch {
            throw MCPRegistryError.invalidResponse
        }
    }
}
