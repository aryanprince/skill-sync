import AppKit
import SwiftUI

struct DirectoryPickerButton<Label: View>: View {
    @EnvironmentObject private var model: AppModel
    private let label: () -> Label

    init(@ViewBuilder label: @escaping () -> Label) {
        self.label = label
    }

    var body: some View {
        Button(action: chooseDirectory, label: label)
    }

    private func chooseDirectory() {
        let panel = NSOpenPanel()
        panel.title = "Choose a folder containing coding projects"
        panel.prompt = "Watch Folder"
        panel.message = "Skill Sync searches this folder for projects with agent configuration."
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false

        guard panel.runModal() == .OK, let url = panel.url else { return }
        Task { await model.addWatchedRoot(url) }
    }
}
