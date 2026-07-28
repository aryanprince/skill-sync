import SwiftUI

struct CatalogPlaceholderView: View {
    var body: some View {
        ContentUnavailableView {
            Label("Skills Catalog", systemImage: "sparkle.magnifyingglass")
        } description: {
            Text("Search skills.sh and install a canonical project or global copy.")
        }
    }
}

struct MCPPlaceholderView: View {
    var body: some View {
        ContentUnavailableView {
            Label("MCP Servers", systemImage: "server.rack")
        } description: {
            Text("Inspect Codex and Claude Code MCP configuration from one place.")
        }
    }
}
