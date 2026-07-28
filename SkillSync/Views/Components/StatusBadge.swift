import SwiftUI

struct StatusBadge: View {
    let status: SkillStatus

    var body: some View {
        Label(status.attentionLabel, systemImage: status.systemImage)
            .font(.caption.weight(.medium))
            .foregroundStyle(status.tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(status.tint.opacity(0.1), in: Capsule())
    }
}

private extension SkillStatus {
    var attentionLabel: String {
        switch self {
        case .canonical: "Canonical"
        case .linked: "Linked"
        case .needsMigration: "Migrate"
        case .identicalDuplicate: "Duplicate"
        case .conflict: "Conflict"
        case .brokenLink: "Broken"
        case .unmanaged: "Unmanaged"
        }
    }
}
