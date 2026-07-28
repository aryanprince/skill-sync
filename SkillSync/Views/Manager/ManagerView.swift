import SwiftUI

struct ManagerView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        NavigationSplitView {
            SidebarView()
        } detail: {
            detail
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.appCanvas)
        }
        .frame(minWidth: 860, minHeight: 590)
        .toolbar {
            ToolbarItemGroup {
                if model.lastReceipt != nil {
                    Button("Undo", systemImage: "arrow.uturn.backward") {
                        Task { await model.undoLastCleanup() }
                    }
                    .help("Undo the last cleanup from this app session")
                }

                Button("Scan", systemImage: "arrow.clockwise") {
                    Task { await model.refresh() }
                }
                .disabled(model.scanState == .scanning)

                DirectoryPickerButton {
                    Label("Add Folder", systemImage: "folder.badge.plus")
                }
            }
        }
        .task { await model.bootstrap() }
        .sheet(item: $model.pendingPlan) { plan in
            CleanupReviewView(plan: plan)
                .environmentObject(model)
        }
        .overlay(alignment: .bottom) {
            if let message = model.activityMessage {
                ActivityToast(message: message) {
                    model.activityMessage = nil
                }
                .padding(.bottom, 18)
            }
        }
    }

    @ViewBuilder private var detail: some View {
        switch model.selection ?? .overview {
        case .overview:
            OverviewView()
        case .workspace:
            if let workspace = model.selectedWorkspace {
                WorkspaceDetailView(workspace: workspace)
            } else {
                ContentUnavailableView(
                    "Workspace Not Found", systemImage: "folder.badge.questionmark")
            }
        case .catalog:
            CatalogView()
        case .mcpServers:
            MCPView()
        }
    }
}

private struct ActivityToast: View {
    let message: String
    let dismiss: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Text(message)
                .font(.callout)
            Button(action: dismiss) {
                Image(systemName: "xmark")
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.regularMaterial, in: Capsule())
        .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
    }
}
