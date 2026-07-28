import Foundation

struct ProcessRequest: Sendable {
    let executableURL: URL
    let arguments: [String]
    let environment: [String: String]
    let currentDirectoryURL: URL?
    let timeout: TimeInterval
    let secretValues: Set<String>
}

struct ProcessResult: Sendable {
    let exitCode: Int32
    let standardOutput: String
    let standardError: String

    var succeeded: Bool { exitCode == 0 }
}

enum ProcessRunnerError: LocalizedError {
    case timedOut(String)
    case launchFailed(String)

    var errorDescription: String? {
        switch self {
        case let .timedOut(command):
            "The command timed out: \(command)"
        case let .launchFailed(message):
            "The command could not start: \(message)"
        }
    }
}

actor ProcessRunner {
    func run(_ request: ProcessRequest) throws -> ProcessResult {
        let process = Process()
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.executableURL = request.executableURL
        process.arguments = request.arguments
        process.currentDirectoryURL = request.currentDirectoryURL
        process.environment = ProcessInfo.processInfo.environment.merging(request.environment) {
            _, new in
            new
        }
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        do {
            try process.run()
        } catch {
            throw ProcessRunnerError.launchFailed(error.localizedDescription)
        }

        let deadline = Date().addingTimeInterval(request.timeout)
        while process.isRunning {
            if Date() >= deadline {
                process.terminate()
                throw ProcessRunnerError.timedOut(redactedCommand(for: request))
            }
            Thread.sleep(forTimeInterval: 0.05)
        }

        let output =
            String(
                data: outputPipe.fileHandleForReading.readDataToEndOfFile(),
                encoding: .utf8
            ) ?? ""
        let error =
            String(
                data: errorPipe.fileHandleForReading.readDataToEndOfFile(),
                encoding: .utf8
            ) ?? ""
        return ProcessResult(
            exitCode: process.terminationStatus,
            standardOutput: redact(output, secrets: request.secretValues),
            standardError: redact(error, secrets: request.secretValues)
        )
    }

    private func redactedCommand(for request: ProcessRequest) -> String {
        redact(
            ([request.executableURL.path] + request.arguments).joined(separator: " "),
            secrets: request.secretValues
        )
    }

    private func redact(_ value: String, secrets: Set<String>) -> String {
        secrets.filter { !$0.isEmpty }.reduce(value) { partial, secret in
            partial.replacingOccurrences(of: secret, with: "••••••••")
        }
    }
}

enum ExecutableLocator {
    static func locate(
        _ name: String, homeURL: URL = FileManager.default.homeDirectoryForCurrentUser
    )
        -> URL?
    {
        let environmentPaths =
            ProcessInfo.processInfo.environment["PATH"]?
            .split(separator: ":")
            .map(String.init) ?? []
        let commonPaths = [
            "/opt/homebrew/bin",
            "/usr/local/bin",
            "/usr/bin",
            homeURL.appending(path: ".local/bin").path,
            homeURL.appending(path: ".bun/bin").path,
        ]
        for directory in environmentPaths + commonPaths {
            let candidate = URL(filePath: directory).appending(path: name)
            if FileManager.default.isExecutableFile(atPath: candidate.path) {
                return candidate
            }
        }
        return nil
    }
}
