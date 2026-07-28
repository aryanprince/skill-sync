import Foundation

@MainActor
final class WatchedRootsStore {
    private let defaults: UserDefaults
    private let key = "watchedRootPaths"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> [URL] {
        let paths = defaults.stringArray(forKey: key) ?? []
        return paths.map { URL(filePath: $0, directoryHint: .isDirectory) }
    }

    func save(_ urls: [URL]) {
        let paths = Array(Set(urls.map(\.standardizedFileURL.path))).sorted()
        defaults.set(paths, forKey: key)
    }
}
