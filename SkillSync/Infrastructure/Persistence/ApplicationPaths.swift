import Foundation

enum ApplicationPaths {
    static let applicationSupport: URL = {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[
            0]
        return base.appending(path: "Skill Sync", directoryHint: .isDirectory)
    }()

    static let backups = applicationSupport.appending(path: "Backups", directoryHint: .isDirectory)
    static let cache = applicationSupport.appending(path: "Cache", directoryHint: .isDirectory)
    static let journal = applicationSupport.appending(path: "OperationJournal.json")
}
