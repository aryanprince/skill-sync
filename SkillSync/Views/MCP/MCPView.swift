import SwiftUI

struct MCPView: View {
    private enum Section: String, CaseIterable, Identifiable {
        case installed = "Installed"
        case registry = "Registry"

        var id: String { rawValue }
    }

    @EnvironmentObject private var model: AppModel
    @State private var section = Section.installed
    @State private var registryQuery = ""
    @State private var serverToConfigure: RegistryMCPServer?
    @State private var isShowingManualServer = false
    @State private var serverToRemove: ConfiguredMCPServer?

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            content
        }
        .task { await model.refreshMCPServers() }
        .task(id: registryQuery) {
            do {
                try await Task.sleep(for: .milliseconds(350))
                guard !Task.isCancelled else { return }
                await model.searchMCPRegistry(query: registryQuery)
            } catch {}
        }
        .sheet(item: $serverToConfigure) { server in
            MCPServerEditorView(registryServer: server)
                .environmentObject(model)
        }
        .sheet(isPresented: $isShowingManualServer) {
            MCPServerEditorView(registryServer: nil)
                .environmentObject(model)
        }
        .confirmationDialog(
            "Remove this MCP server?",
            isPresented: Binding(
                get: { serverToRemove != nil },
                set: { if !$0 { serverToRemove = nil } }
            ),
            presenting: serverToRemove
        ) { server in
            Button("Remove from \(server.agent.displayName)", role: .destructive) {
                Task { await model.removeMCPServer(server) }
            }
            Button("Cancel", role: .cancel) {}
        } message: { server in
            Text(
                "This removes \(server.name) from the \(server.location.displayName) configuration."
            )
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("MCP Servers")
                        .font(.system(size: 26, weight: .semibold))
                    Text("Inspect and configure Codex and Claude Code from one place.")
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Add Server", systemImage: "plus") {
                    isShowingManualServer = true
                }
                .buttonStyle(.borderedProminent)
            }

            Picker("Section", selection: $section) {
                ForEach(Section.allCases) { item in
                    Text(item.rawValue).tag(item)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 320)
        }
        .padding(AppStyle.contentInset)
    }

    @ViewBuilder private var content: some View {
        switch section {
        case .installed:
            installedServers
        case .registry:
            registry
        }
    }

    @ViewBuilder private var installedServers: some View {
        if model.isLoadingMCPServers {
            ProgressView("Reading agent configuration…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if model.configuredMCPServers.isEmpty {
            ContentUnavailableView {
                Label("No MCP Servers Found", systemImage: "server.rack")
            } description: {
                Text("Add one manually or find a published server in the official Registry.")
            } actions: {
                Button("Browse Registry") { section = .registry }
            }
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(model.configuredMCPServers) { server in
                        HStack(spacing: 12) {
                            Image(systemName: server.transport == .stdio ? "terminal" : "network")
                                .foregroundStyle(.secondary)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(server.name)
                                    .fontWeight(.medium)
                                Text(server.endpointSummary)
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            Spacer()
                            Text(server.location.displayName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Label(server.agent.displayName, systemImage: agentIcon(server.agent))
                                .font(.caption.weight(.medium))
                                .frame(width: 105, alignment: .leading)
                            Button("Remove", systemImage: "trash", role: .destructive) {
                                serverToRemove = server
                            }
                            .labelStyle(.iconOnly)
                            .buttonStyle(.plain)
                            .disabled(model.isRunningMCPCommand)
                        }
                        .padding(.vertical, 10)
                        Divider()
                    }
                }
                .padding(.horizontal, AppStyle.contentInset)
            }
            .toolbar {
                Button("Refresh MCP Servers", systemImage: "arrow.clockwise") {
                    Task { await model.refreshMCPServers() }
                }
            }
        }
    }

    private var registry: some View {
        VStack(spacing: 0) {
            TextField("Search the official MCP Registry", text: $registryQuery)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, AppStyle.contentInset)
                .padding(.vertical, 14)

            if registryQuery.trimmingCharacters(in: .whitespacesAndNewlines).count < 2 {
                ContentUnavailableView(
                    "Discover MCP Servers",
                    systemImage: "server.rack",
                    description: Text("Search by server name, such as “filesystem” or “GitHub”.")
                )
            } else if model.isSearchingMCPRegistry {
                ProgressView("Searching the official Registry…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = model.mcpError {
                ContentUnavailableView(
                    "Registry Unavailable",
                    systemImage: "wifi.exclamationmark",
                    description: Text(error)
                )
            } else if model.mcpRegistryResults.isEmpty {
                ContentUnavailableView.search(text: registryQuery)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(model.mcpRegistryResults) { server in
                            Button {
                                serverToConfigure = server
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "shippingbox")
                                        .foregroundStyle(.secondary)
                                        .frame(width: 24)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(server.displayName)
                                            .fontWeight(.medium)
                                        Text(server.description ?? server.name)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(2)
                                    }
                                    Spacer()
                                    Text("v\(server.version)")
                                        .font(.caption.monospaced())
                                        .foregroundStyle(.secondary)
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(.tertiary)
                                }
                                .padding(.vertical, 10)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            Divider()
                        }
                    }
                    .padding(.horizontal, AppStyle.contentInset)
                }
            }
        }
    }

    private func agentIcon(_ agent: MCPAgent) -> String {
        switch agent {
        case .codex: "chevron.left.forwardslash.chevron.right"
        case .claudeCode: "brain.head.profile"
        }
    }
}
