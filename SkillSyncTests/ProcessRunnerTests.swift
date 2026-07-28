import Foundation
import Testing

@testable import SkillSync

@Suite("Process runner")
struct ProcessRunnerTests {
    @Test("Known secrets are redacted from command output")
    func redactsSecrets() async throws {
        let secret = "test-secret-value"
        let result = try await ProcessRunner().run(
            ProcessRequest(
                executableURL: URL(filePath: "/bin/echo"),
                arguments: [secret],
                environment: [:],
                currentDirectoryURL: nil,
                timeout: 2,
                secretValues: [secret]
            )
        )

        #expect(result.succeeded)
        #expect(!result.standardOutput.contains(secret))
        #expect(result.standardOutput.contains("••••••••"))
    }
}
