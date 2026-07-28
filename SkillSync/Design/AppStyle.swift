import AppKit
import SwiftUI

enum AppStyle {
    static let sidebarWidth: CGFloat = 218
    static let contentInset: CGFloat = 24
    static let rowHeight: CGFloat = 44
}

extension Color {
    static let appCanvas = Color(nsColor: .windowBackgroundColor)
    static let appSecondaryCanvas = Color(nsColor: .underPageBackgroundColor)
    static let appSeparator = Color(nsColor: .separatorColor)
    static let appMuted = Color(nsColor: .secondaryLabelColor)
}

extension SkillStatus {
    var systemImage: String {
        switch self {
        case .canonical: "circle.dotted"
        case .linked: "link"
        case .needsMigration: "arrow.triangle.merge"
        case .identicalDuplicate: "square.on.square"
        case .conflict: "exclamationmark.triangle.fill"
        case .brokenLink: "link.badge.plus"
        case .unmanaged: "questionmark.folder"
        }
    }

    var tint: Color {
        switch self {
        case .canonical, .linked: .green
        case .needsMigration, .identicalDuplicate: .orange
        case .conflict, .brokenLink: .red
        case .unmanaged: .secondary
        }
    }
}
