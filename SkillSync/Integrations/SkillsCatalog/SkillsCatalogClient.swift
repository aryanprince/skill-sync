import Foundation

enum SkillsCatalogError: LocalizedError {
    case invalidRequest
    case invalidResponse
    case serviceError(Int)

    var errorDescription: String? {
        switch self {
        case .invalidRequest:
            "The skills.sh search request could not be created."
        case .invalidResponse:
            "skills.sh returned an unreadable response."
        case let .serviceError(status):
            "skills.sh returned HTTP \(status)."
        }
    }
}

actor SkillsCatalogClient {
    private struct SearchResponse: Decodable {
        let skills: [CatalogSkill]
    }

    private let session: URLSession
    private let baseURL: URL

    private static let defaultBaseURL: URL = {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "skills.sh"
        components.path = "/api/search"
        guard let url = components.url else {
            preconditionFailure("The built-in skills.sh URL must be valid.")
        }
        return url
    }()

    init(
        session: URLSession = .shared,
        baseURL: URL = SkillsCatalogClient.defaultBaseURL
    ) {
        self.session = session
        self.baseURL = baseURL
    }

    func search(_ query: String) async throws -> [CatalogSkill] {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            throw SkillsCatalogError.invalidRequest
        }
        components.queryItems = [URLQueryItem(name: "q", value: query)]
        guard let url = components.url else { throw SkillsCatalogError.invalidRequest }

        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("SkillSync/0.1", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SkillsCatalogError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw SkillsCatalogError.serviceError(httpResponse.statusCode)
        }

        do {
            return try JSONDecoder().decode(SearchResponse.self, from: data).skills
        } catch {
            throw SkillsCatalogError.invalidResponse
        }
    }
}
