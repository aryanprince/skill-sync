import SwiftUI

struct MCPServerEditorView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss

    let registryServer: RegistryMCPServer?

    @State private var name: String
    @State private var transport: MCPTransport
    @State private var commandText: String
    @State private var urlText: String
    @State private var environment: [MCPEnvironmentEntry]
    @State private var headers: [MCPHeader] = []
    @State private var bearerTokenEnvironmentVariable = ""
    @State private var targetID = MCPInstallLocation.global.id
    @State private var agents: Set<MCPAgent> = Set(MCPAgent.allCases)

    init(registryServer: RegistryMCPServer?) {
        self.registryServer = registryServer
        let initial = Self.initialValues(for: registryServer)
        _name = State(initialValue: initial.name)
        _transport = State(initialValue: initial.transport)
        _commandText = State(initialValue: initial.command)
        _urlText = State(initialValue: initial.url)
        _environment = State(initialValue: initial.environment)
    }

    private var locations: [MCPInstallLocation] {
        [.global] + model.projectWorkspaces.map { .project($0.rootURL) }
    }

    private var selectedLocation: MCPInstallLocation {
        locations.first { $0.id == targetID } ?? .global
    }

    private var request: MCPInstallationRequest {
        let parsedURL = URL(string: urlText.trimmingCharacters(in: .whitespacesAndNewlines))
        return MCPInstallationRequest(
            definition: MCPServerDefinition(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                transport: transport,
                command: CommandLineParser.parse(commandText),
                url: parsedURL,
                environment: environment.filter { !$0.key.isEmpty },
                headers: headers.filter { !$0.name.isEmpty },
                scope: selectedLocation.projectURL == nil ? .user : .project,
                sourceURL: registryServer?.repository?.url
            ),
            location: selectedLocation,
            agents: agents,
            bearerTokenEnvironmentVariable: bearerTokenEnvironmentVariable
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 5) {
                Text(
                    registryServer == nil
                        ? "Add MCP Server" : "Configure \(registryServer?.displayName ?? "Server")"
                )
                .font(.title2.weight(.semibold))
                Text("Review both agent commands before writing configuration.")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)

            Divider()

            Form {
                TextField("Name", text: $name)
                Picker("Location", selection: $targetID) {
                    ForEach(locations) { location in
                        Text(location.displayName).tag(location.id)
                    }
                }

                LabeledContent("Agents") {
                    HStack {
                        ForEach(MCPAgent.allCases) { agent in
                            Toggle(agent.displayName, isOn: agentBinding(agent))
                                .toggleStyle(.checkbox)
                        }
                    }
                }

                Picker("Transport", selection: $transport) {
                    Text("Local command (stdio)").tag(MCPTransport.stdio)
                    Text("Remote HTTP").tag(MCPTransport.http)
                    Text("Remote SSE").tag(MCPTransport.sse)
                }

                if transport == .stdio {
                    TextField("Command", text: $commandText, prompt: Text("npx -y package-name"))
                        .font(.body.monospaced())
                    environmentFields
                } else {
                    TextField("URL", text: $urlText, prompt: Text("https://example.com/mcp"))
                        .font(.body.monospaced())
                    headerFields
                    TextField(
                        "Codex bearer token variable",
                        text: $bearerTokenEnvironmentVariable,
                        prompt: Text("Optional, e.g. GITHUB_TOKEN")
                    )
                    .font(.body.monospaced())
                }

                Section("Command preview") {
                    ForEach(previewCommands, id: \.self) { command in
                        Text(redacted(command))
                            .font(.caption.monospaced())
                            .textSelection(.enabled)
                    }
                }

                Section {
                    Label(
                        selectedLocation.projectURL == nil
                            ? "Credentials are stored locally in each agent's user configuration."
                            : "Project configuration may be committed. Review secret values before committing.",
                        systemImage: "exclamationmark.shield"
                    )
                    .font(.caption)
                    .foregroundStyle(.orange)
                }
            }
            .formStyle(.grouped)

            Divider()

            HStack {
                Button("Cancel", role: .cancel) { dismiss() }
                Spacer()
                if model.isRunningMCPCommand {
                    ProgressView().controlSize(.small)
                }
                Button("Add to Agents") {
                    Task {
                        if await model.addMCPServer(request) {
                            dismiss()
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isValid || model.isRunningMCPCommand)
            }
            .padding(16)
        }
        .frame(width: 700, height: 680)
    }

    private var environmentFields: some View {
        Section("Environment") {
            ForEach($environment) { $entry in
                HStack {
                    TextField("KEY", text: $entry.key)
                        .font(.body.monospaced())
                    if entry.isSecret {
                        SecureField("Value", text: $entry.value)
                    } else {
                        TextField("Value", text: $entry.value)
                    }
                    Toggle("Secret", isOn: $entry.isSecret)
                        .toggleStyle(.checkbox)
                    Button("Remove", systemImage: "minus.circle", role: .destructive) {
                        environment.removeAll { $0.key == entry.key }
                    }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.plain)
                }
            }
            Button("Add Variable", systemImage: "plus") {
                environment.append(MCPEnvironmentEntry(key: "", value: "", isSecret: true))
            }
        }
    }

    private var headerFields: some View {
        Section("Claude Code headers") {
            ForEach($headers) { $header in
                HStack {
                    TextField("Header", text: $header.name)
                        .font(.body.monospaced())
                    if header.isSecret {
                        SecureField("Value", text: $header.value)
                    } else {
                        TextField("Value", text: $header.value)
                    }
                    Toggle("Secret", isOn: $header.isSecret)
                        .toggleStyle(.checkbox)
                    Button("Remove", systemImage: "minus.circle", role: .destructive) {
                        headers.removeAll { $0.name == header.name }
                    }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.plain)
                }
            }
            Button("Add Header", systemImage: "plus") {
                headers.append(MCPHeader(name: "", value: "", isSecret: true))
            }
        }
    }

    private var previewCommands: [String] {
        var commands: [String] = []
        if agents.contains(.codex), let command = try? CodexMCPAdapter.addCommand(for: request) {
            commands.append(command.preview)
        }
        if agents.contains(.claudeCode),
            let command = try? ClaudeMCPAdapter.addCommand(for: request)
        {
            commands.append(command.preview)
        }
        return commands
    }

    private var isValid: Bool {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, !agents.isEmpty else {
            return false
        }
        switch transport {
        case .stdio: return !CommandLineParser.parse(commandText).isEmpty
        case .http, .sse: return URL(string: urlText)?.scheme != nil
        }
    }

    private func agentBinding(_ agent: MCPAgent) -> Binding<Bool> {
        Binding(
            get: { agents.contains(agent) },
            set: { isSelected in
                if isSelected { agents.insert(agent) } else { agents.remove(agent) }
            }
        )
    }

    private func redacted(_ command: String) -> String {
        let secrets =
            environment.filter(\.isSecret).map(\.value)
            + headers.filter(\.isSecret).map(\.value)
        return secrets.filter { !$0.isEmpty }.reduce(command) { partial, secret in
            partial.replacingOccurrences(of: secret, with: "••••••••")
        }
    }

    private static func initialValues(for server: RegistryMCPServer?) -> (
        name: String, transport: MCPTransport, command: String, url: String,
        environment: [MCPEnvironmentEntry]
    ) {
        guard let server else { return ("", .stdio, "", "", []) }
        if let remote = server.remotes?.first {
            let transport: MCPTransport = remote.type == "sse" ? .sse : .http
            return (server.displayName, transport, "", remote.url.absoluteString, [])
        }
        guard let package = server.preferredPackage else {
            return (server.displayName, .stdio, "", "", [])
        }
        let command: String
        if package.registryType == "npm" {
            let version = package.version.map { "@\($0)" } ?? ""
            command = "\(package.runtimeHint ?? "npx") -y \(package.identifier)\(version)"
        } else {
            command = package.identifier
        }
        let environment = (package.environmentVariables ?? []).map {
            MCPEnvironmentEntry(
                key: $0.name,
                value: $0.default ?? "",
                isSecret: $0.isSecret ?? false
            )
        }
        return (server.displayName, .stdio, command, "", environment)
    }
}
