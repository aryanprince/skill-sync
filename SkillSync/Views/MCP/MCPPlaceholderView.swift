import SwiftUI

struct MCPPlaceholderView: View {
    var body: some View {
        ContentUnavailableView {
            Label("MCP Servers", systemImage: "server.rack")
        } description: {
            Text("Inspect Codex and Claude Code MCP configuration from one place.")
        }
    }
}
