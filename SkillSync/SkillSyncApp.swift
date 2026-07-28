import SwiftUI

@main
struct SkillSyncApp: App {
    @StateObject private var model = AppModel()
    @StateObject private var updater = AppUpdater()

    var body: some Scene {
        WindowGroup("Skill Sync", id: "manager") {
            ManagerView()
                .environmentObject(model)
                .environmentObject(updater)
        }
        .defaultSize(width: 980, height: 680)
        .commands {
            CommandGroup(after: .newItem) {
                Button("Scan Now") {
                    Task { await model.refresh() }
                }
                .keyboardShortcut("r", modifiers: .command)
            }

            CommandGroup(after: .appInfo) {
                CheckForUpdatesButton(updater: updater)
            }
        }

        MenuBarExtra {
            MenuBarView()
                .environmentObject(model)
                .environmentObject(updater)
        } label: {
            Label("Skill Sync", systemImage: menuBarSymbol)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environmentObject(model)
                .environmentObject(updater)
        }
    }

    private var menuBarSymbol: String {
        model.conflictCount > 0 ? "link.badge.plus" : "link"
    }
}
