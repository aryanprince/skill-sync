import CryptoKit
import Foundation

enum SkillFileSystemError: LocalizedError {
    case invalidSkillDirectory(URL)
    case destinationExists(URL)
    case linkEscapesRoot(URL)
    case verificationFailed(URL)

    var errorDescription: String? {
        switch self {
        case let .invalidSkillDirectory(url):
            "No SKILL.md was found in \(url.path)."
        case let .destinationExists(url):
            "The destination already exists at \(url.path)."
        case let .linkEscapesRoot(url):
            "The symbolic link would leave the approved workspace at \(url.path)."
        case let .verificationFailed(url):
            "Verification failed for \(url.path)."
        }
    }
}

actor SkillFileSystem {
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func directoryExists(at url: URL) -> Bool {
        var isDirectory = ObjCBool(false)
        return fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory)
            && isDirectory.boolValue
    }

    func itemExists(at url: URL) -> Bool {
        fileManager.fileExists(atPath: url.path)
            || ((try? url.resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink) == true)
    }

    func skillDirectories(at rootURL: URL) throws -> [URL] {
        guard directoryExists(at: rootURL) else { return [] }

        return try fileManager.contentsOfDirectory(
            at: rootURL,
            includingPropertiesForKeys: [.isDirectoryKey, .isSymbolicLinkKey],
            options: []
        )
        .filter { url in
            guard !url.lastPathComponent.hasPrefix(".") else { return false }
            let values = try? url.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey])
            if values?.isSymbolicLink == true {
                return true
            }
            return values?.isDirectory == true
                && fileManager.fileExists(atPath: url.appending(path: "SKILL.md").path)
        }
        .sorted {
            $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending
        }
    }

    func installation(
        at url: URL,
        agent: AgentKind
    ) throws -> SkillInstallation {
        let values = try url.resourceValues(forKeys: [.isSymbolicLinkKey])
        if values.isSymbolicLink == true {
            let destinationPath = try fileManager.destinationOfSymbolicLink(atPath: url.path)
            let destinationURL = URL(
                filePath: destinationPath,
                relativeTo: url.deletingLastPathComponent()
            ).standardizedFileURL
            let isBroken = !fileManager.fileExists(atPath: destinationURL.path)
            return SkillInstallation(
                agent: agent,
                url: url,
                kind: isBroken ? .brokenSymbolicLink : .symbolicLink,
                fingerprint: isBroken ? nil : try fingerprintDirectory(at: destinationURL),
                symbolicLinkDestination: destinationURL
            )
        }

        guard fileManager.fileExists(atPath: url.appending(path: "SKILL.md").path) else {
            throw SkillFileSystemError.invalidSkillDirectory(url)
        }
        return SkillInstallation(
            agent: agent,
            url: url,
            kind: .directory,
            fingerprint: try fingerprintDirectory(at: url),
            symbolicLinkDestination: nil
        )
    }

    func fingerprintDirectory(at rootURL: URL) throws -> String {
        guard directoryExists(at: rootURL) else {
            throw SkillFileSystemError.invalidSkillDirectory(rootURL)
        }

        var entries: [(String, URL, URLResourceValues)] = []
        guard
            let enumerator = fileManager.enumerator(
                at: rootURL,
                includingPropertiesForKeys: [
                    .isRegularFileKey,
                    .isDirectoryKey,
                    .isSymbolicLinkKey,
                ],
                options: [.skipsPackageDescendants]
            )
        else {
            throw SkillFileSystemError.invalidSkillDirectory(rootURL)
        }

        for case let url as URL in enumerator {
            let relativePath = String(url.path.dropFirst(rootURL.path.count + 1))
            let firstComponent = relativePath.split(separator: "/").first.map(String.init)
            if firstComponent == ".git" || firstComponent == "node_modules" {
                if (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true {
                    enumerator.skipDescendants()
                }
                continue
            }
            let values = try url.resourceValues(forKeys: [
                .isRegularFileKey,
                .isDirectoryKey,
                .isSymbolicLinkKey,
            ])
            if values.isSymbolicLink == true {
                enumerator.skipDescendants()
            }
            entries.append((relativePath, url, values))
        }

        var hasher = SHA256()
        for entry in entries.sorted(by: { $0.0 < $1.0 }) {
            hasher.update(data: Data(entry.0.utf8))
            if entry.2.isSymbolicLink == true {
                hasher.update(data: Data("link".utf8))
                let destination = try fileManager.destinationOfSymbolicLink(atPath: entry.1.path)
                hasher.update(data: Data(destination.utf8))
            } else if entry.2.isDirectory == true {
                hasher.update(data: Data("directory".utf8))
            } else if entry.2.isRegularFile == true {
                hasher.update(data: Data("file".utf8))
                hasher.update(data: try Data(contentsOf: entry.1, options: .mappedIfSafe))
            }
        }
        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }

    func createDirectory(at url: URL) throws {
        try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
    }

    func moveItem(from source: URL, to destination: URL) throws {
        guard !itemExists(at: destination) else {
            throw SkillFileSystemError.destinationExists(destination)
        }
        try fileManager.createDirectory(
            at: destination.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        do {
            try fileManager.moveItem(at: source, to: destination)
        } catch {
            try fileManager.copyItem(at: source, to: destination)
            let sourceFingerprint = try fingerprintDirectory(at: source)
            let destinationFingerprint = try fingerprintDirectory(at: destination)
            guard sourceFingerprint == destinationFingerprint else {
                try? fileManager.removeItem(at: destination)
                throw SkillFileSystemError.verificationFailed(destination)
            }
            try fileManager.removeItem(at: source)
        }
    }

    func createRelativeSymbolicLink(at linkURL: URL, destination: URL) throws {
        guard !itemExists(at: linkURL) else {
            throw SkillFileSystemError.destinationExists(linkURL)
        }
        try fileManager.createDirectory(
            at: linkURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let relativeDestination = Self.relativePath(
            from: linkURL.deletingLastPathComponent(),
            to: destination
        )
        try fileManager.createSymbolicLink(
            atPath: linkURL.path,
            withDestinationPath: relativeDestination
        )
        let resolved = try fileManager.destinationOfSymbolicLink(atPath: linkURL.path)
        let resolvedURL = URL(
            filePath: resolved,
            relativeTo: linkURL.deletingLastPathComponent()
        ).standardizedFileURL
        guard
            resolvedURL.resolvingSymlinksInPath().standardizedFileURL.path
                == destination.resolvingSymlinksInPath().standardizedFileURL.path
        else {
            throw SkillFileSystemError.verificationFailed(linkURL)
        }
    }

    func removeItem(at url: URL) throws {
        try fileManager.removeItem(at: url)
    }

    static func relativePath(from sourceDirectory: URL, to destination: URL) -> String {
        let source = sourceDirectory.standardizedFileURL.pathComponents
        let target = destination.standardizedFileURL.pathComponents
        var commonIndex = 0
        while commonIndex < source.count
            && commonIndex < target.count
            && source[commonIndex] == target[commonIndex]
        {
            commonIndex += 1
        }
        let upward = Array(repeating: "..", count: source.count - commonIndex)
        let downward = Array(target.dropFirst(commonIndex))
        return (upward + downward).joined(separator: "/")
    }
}
