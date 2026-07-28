import AppKit
import Combine
import Foundation

@MainActor
final class AppModel: ObservableObject {
    enum ScanState: Equatable {
        case idle
        case scanning
        case ready(Date)
        case failed(String)
    }

    @Published var watchedRoots: [URL]
    @Published private(set) var workspaces: [Workspace] = []
    @Published private(set) var scanState: ScanState = .idle
    @Published var selection: AppDestination? = .overview
    @Published var pendingPlan: ReconciliationPlan?
    @Published private(set) var lastReceipt: OperationReceipt?
    @Published var activityMessage: String?
    @Published private(set) var catalogResults: [CatalogSkill] = []
    @Published private(set) var catalogError: String?
    @Published private(set) var isSearchingCatalog = false
    @Published private(set) var isRunningSkillsCommand = false
    @Published private(set) var configuredMCPServers: [ConfiguredMCPServer] = []
    @Published private(set) var isLoadingMCPServers = false
    @Published private(set) var mcpRegistryResults: [RegistryMCPServer] = []
    @Published private(set) var isSearchingMCPRegistry = false
    @Published private(set) var mcpError: String?
    @Published private(set) var isRunningMCPCommand = false

    private let watchedRootsStore: WatchedRootsStore
    private let scanner: WorkspaceScanner
    private let planner: ReconciliationPlanner
    private let executor: ReconciliationExecutor
    private let catalogClient: SkillsCatalogClient
    private let skillsCLI: SkillsCLI
    private let mcpService: MCPService
    private let mcpRegistryClient: MCPRegistryClient
    private var hasBootstrapped = false

    init(
        watchedRootsStore: WatchedRootsStore = WatchedRootsStore(),
        fileSystem: SkillFileSystem = SkillFileSystem()
    ) {
        self.watchedRootsStore = watchedRootsStore
        self.watchedRoots = watchedRootsStore.load()
        self.scanner = WorkspaceScanner(fileSystem: fileSystem)
        self.planner = ReconciliationPlanner()
        self.executor = ReconciliationExecutor(fileSystem: fileSystem)
        self.catalogClient = SkillsCatalogClient()
        self.skillsCLI = SkillsCLI()
        self.mcpService = MCPService()
        self.mcpRegistryClient = MCPRegistryClient()
    }

    var globalWorkspace: Workspace? {
        workspaces.first { $0.rootURL.standardizedFileURL == Self.homeURL }
    }

    var projectWorkspaces: [Workspace] {
        workspaces.filter { $0.rootURL.standardizedFileURL != Self.homeURL }
    }

    var selectedWorkspace: Workspace? {
        guard case let .workspace(id) = selection else { return nil }
        return workspaces.first { $0.id == id }
    }

    var attentionCount: Int {
        workspaces.reduce(0) { $0 + $1.attentionCount }
    }

    var conflictCount: Int {
        workspaces.reduce(0) { $0 + $1.conflictCount }
    }

    var skillCount: Int {
        workspaces.reduce(0) { $0 + $1.skills.count }
    }

    func bootstrap() async {
        guard !hasBootstrapped else { return }
        hasBootstrapped = true
        await refresh()
    }

    func refresh() async {
        guard scanState != .scanning else { return }
        scanState = .scanning

        do {
            var projectURLs: Set<URL> = [Self.homeURL]
            for root in watchedRoots {
                let discovered = try await scanner.discoverProjects(in: root)
                projectURLs.formUnion(discovered.map(\.standardizedFileURL))
            }

            var scanned: [Workspace] = []
            for projectURL in projectURLs.sorted(by: Self.sortURLs) {
                scanned.append(try await scanner.scanProject(at: projectURL))
            }
            workspaces = scanned
            scanState = .ready(.now)

            if case let .workspace(id) = selection,
                !workspaces.contains(where: { $0.id == id })
            {
                selection = .overview
            }
        } catch {
            scanState = .failed(error.localizedDescription)
        }
    }

    func addWatchedRoot(_ url: URL) async {
        let normalized = url.standardizedFileURL
        guard !watchedRoots.contains(normalized) else { return }
        watchedRoots.append(normalized)
        watchedRoots.sort(by: Self.sortURLs)
        watchedRootsStore.save(watchedRoots)
        activityMessage = "Added \(normalized.path)"
        await refresh()
    }

    func removeWatchedRoot(_ url: URL) async {
        watchedRoots.removeAll { $0.standardizedFileURL == url.standardizedFileURL }
        watchedRootsStore.save(watchedRoots)
        activityMessage = "Stopped watching \(url.path)"
        await refresh()
    }

    func prepareCleanup(for workspace: Workspace) {
        pendingPlan = planner.plan(for: workspace)
    }

    func applyPendingPlan() async {
        guard let plan = pendingPlan, !plan.isEmpty else {
            pendingPlan = nil
            return
        }

        do {
            lastReceipt = try await executor.apply(plan)
            pendingPlan = nil
            activityMessage = "Cleaned up \(plan.affectedSkillNames.count) skill installation(s)."
            await refresh()
        } catch {
            activityMessage = "Cleanup failed: \(error.localizedDescription)"
        }
    }

    func undoLastCleanup() async {
        guard let receipt = lastReceipt else { return }
        do {
            try await executor.undo(receipt)
            lastReceipt = nil
            activityMessage = "Restored the previous skill layout."
            await refresh()
        } catch {
            activityMessage = "Undo failed: \(error.localizedDescription)"
        }
    }

    func searchCatalog(query: String) async {
        let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalized.count >= 2 else {
            catalogResults = []
            catalogError = nil
            isSearchingCatalog = false
            return
        }

        isSearchingCatalog = true
        catalogError = nil
        do {
            catalogResults = try await catalogClient.search(normalized)
        } catch is CancellationError {
            return
        } catch {
            catalogResults = []
            catalogError = error.localizedDescription
        }
        isSearchingCatalog = false
    }

    @discardableResult
    func installCatalogSkill(_ skill: CatalogSkill, target: SkillInstallationTarget) async -> Bool {
        guard !isRunningSkillsCommand else { return false }
        isRunningSkillsCommand = true
        defer { isRunningSkillsCommand = false }

        do {
            _ = try await skillsCLI.install(skill: skill, target: target)
            activityMessage = "Installed \(skill.skillID) for Codex and Claude Code."
            await refresh()
            return true
        } catch {
            activityMessage = "Install failed: \(error.localizedDescription)"
            return false
        }
    }

    func updateSkills(target: SkillInstallationTarget) async {
        guard !isRunningSkillsCommand else { return }
        isRunningSkillsCommand = true
        defer { isRunningSkillsCommand = false }

        do {
            _ = try await skillsCLI.update(target: target)
            activityMessage = "Checked \(target.displayName.lowercased()) skills for updates."
            await refresh()
        } catch {
            activityMessage = "Update failed: \(error.localizedDescription)"
        }
    }

    func refreshMCPServers() async {
        guard !isLoadingMCPServers else { return }
        isLoadingMCPServers = true
        let locations: [MCPInstallLocation] =
            [.global]
            + projectWorkspaces.map { .project($0.rootURL) }
        configuredMCPServers = await mcpService.list(locations: locations)
        isLoadingMCPServers = false
    }

    func searchMCPRegistry(query: String) async {
        let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalized.count >= 2 else {
            mcpRegistryResults = []
            mcpError = nil
            isSearchingMCPRegistry = false
            return
        }

        isSearchingMCPRegistry = true
        mcpError = nil
        do {
            mcpRegistryResults = try await mcpRegistryClient.search(normalized)
        } catch is CancellationError {
            return
        } catch {
            mcpRegistryResults = []
            mcpError = error.localizedDescription
        }
        isSearchingMCPRegistry = false
    }

    @discardableResult
    func addMCPServer(_ request: MCPInstallationRequest) async -> Bool {
        guard !isRunningMCPCommand else { return false }
        isRunningMCPCommand = true
        defer { isRunningMCPCommand = false }

        do {
            try await mcpService.add(request)
            activityMessage =
                "Added \(request.definition.name) to \(request.agents.count) agent(s)."
            await refreshMCPServers()
            return true
        } catch {
            activityMessage = "MCP setup failed: \(error.localizedDescription)"
            await refreshMCPServers()
            return false
        }
    }

    func removeMCPServer(_ server: ConfiguredMCPServer) async {
        guard !isRunningMCPCommand else { return }
        isRunningMCPCommand = true
        defer { isRunningMCPCommand = false }

        do {
            try await mcpService.remove(server)
            activityMessage = "Removed \(server.name) from \(server.agent.displayName)."
            await refreshMCPServers()
        } catch {
            activityMessage = "Remove failed: \(error.localizedDescription)"
        }
    }

    func reveal(_ url: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    func activateApp() {
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    static let homeURL = FileManager.default.homeDirectoryForCurrentUser.standardizedFileURL

    private static func sortURLs(_ lhs: URL, _ rhs: URL) -> Bool {
        lhs.path.localizedStandardCompare(rhs.path) == .orderedAscending
    }
}
