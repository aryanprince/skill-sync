import Foundation

struct TestDirectory {
    let url: URL

    init(name: String = UUID().uuidString) throws {
        url = FileManager.default.temporaryDirectory
            .appending(path: "SkillSyncTests", directoryHint: .isDirectory)
            .appending(path: name, directoryHint: .isDirectory)
        try? FileManager.default.removeItem(at: url)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    func makeSkill(
        at relativePath: String,
        name: String,
        body: String = "Instructions"
    ) throws -> URL {
        let skillURL =
            url
            .appending(path: relativePath, directoryHint: .isDirectory)
            .appending(path: name, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: skillURL, withIntermediateDirectories: true)
        let skill = """
            ---
            name: \(name)
            description: Test skill
            ---

            \(body)
            """
        try Data(skill.utf8).write(to: skillURL.appending(path: "SKILL.md"), options: .atomic)
        return skillURL
    }
}
