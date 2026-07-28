import SwiftUI

struct CatalogView: View {
    @EnvironmentObject private var model: AppModel
    @State private var query = ""
    @State private var selectedSkill: CatalogSkill?

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            results
        }
        .sheet(item: $selectedSkill) { skill in
            SkillInstallView(skill: skill)
                .environmentObject(model)
        }
        .task(id: query) {
            do {
                try await Task.sleep(for: .milliseconds(350))
                guard !Task.isCancelled else { return }
                await model.searchCatalog(query: query)
            } catch {}
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Skills Catalog")
                        .font(.system(size: 26, weight: .semibold))
                    Text(
                        "Search skills.sh, then install one canonical copy for Codex and Claude Code."
                    )
                    .foregroundStyle(.secondary)
                }
                Spacer()
                Menu("Check for Skill Updates", systemImage: "arrow.down.circle") {
                    Button("Global Skills") {
                        Task { await model.updateSkills(target: .global) }
                    }
                    ForEach(model.projectWorkspaces) { workspace in
                        Button(workspace.name) {
                            Task { await model.updateSkills(target: .project(workspace.rootURL)) }
                        }
                    }
                }
                .disabled(model.isRunningSkillsCommand)
            }

            TextField("Search by name, topic, or repository", text: $query)
                .textFieldStyle(.roundedBorder)
                .font(.body)
        }
        .padding(AppStyle.contentInset)
    }

    @ViewBuilder private var results: some View {
        if query.trimmingCharacters(in: .whitespacesAndNewlines).count < 2 {
            ContentUnavailableView(
                "Find a Skill",
                systemImage: "sparkle.magnifyingglass",
                description: Text("Try “SwiftUI”, “code review”, or a GitHub organization.")
            )
        } else if model.isSearchingCatalog {
            ProgressView("Searching skills.sh…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = model.catalogError {
            ContentUnavailableView(
                "Catalog Unavailable",
                systemImage: "wifi.exclamationmark",
                description: Text(error)
            )
        } else if model.catalogResults.isEmpty {
            ContentUnavailableView.search(text: query)
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(model.catalogResults) { skill in
                        Button {
                            selectedSkill = skill
                        } label: {
                            CatalogSkillRow(skill: skill)
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

private struct CatalogSkillRow: View {
    let skill: CatalogSkill

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "shippingbox")
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 3) {
                Text(skill.displayName)
                    .fontWeight(.medium)
                Text("\(skill.source) · \(skill.skillID)")
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(skill.installs.formatted())
                .monospacedDigit()
                .foregroundStyle(.secondary)
            Image(systemName: "arrow.down.circle")
                .foregroundStyle(.tint)
        }
        .padding(.vertical, 11)
        .contentShape(Rectangle())
    }
}
