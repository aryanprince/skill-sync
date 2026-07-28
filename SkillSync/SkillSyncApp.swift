import SwiftUI

@main
struct SkillSyncApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup("Skill Sync", id: "manager") {
            ManagerView()
                .environmentObject(model)
        }
        .defaultSize(width: 980, height: 680)
        .commands {
            CommandGroup(after: .newItem) {
                Button("Scan Now") {
                    Task { await model.refresh() }
                }
                .keyboardShortcut("r", modifiers: .command)
            }
        }

        MenuBarExtra {
            MenuBarView()
                .environmentObject(model)
        } label: {
            Label("Skill Sync", systemImage: menuBarSymbol)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environmentObject(model)
        }
    }

    private var menuBarSymbol: String {
        model.conflictCount > 0 ? "link.badge.plus" : "link"
    }
}
