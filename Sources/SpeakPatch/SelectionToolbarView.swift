import SwiftUI
import AppKit

/// The compact PopClip-style bar that appears next to a selection.
struct SelectionToolbarView: View {
    /// Actions to surface as buttons, in order.
    let actions: [RewriteAction]
    /// Invoked with the chosen action.
    let onAction: (RewriteAction) -> Void
    /// Opens the full rewrite panel.
    let onOpen: () -> Void

    var body: some View {
        HStack(spacing: 2) {
            ForEach(actions) { action in
                button(symbol: action.symbol, title: action.shortTitle) {
                    onAction(action)
                }
            }

            Divider()
                .frame(height: 26)
                .padding(.horizontal, 2)

            button(symbol: "ellipsis", title: "More") {
                onOpen()
            }
        }
        .padding(5)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .stroke(.black.opacity(0.08), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.22), radius: 10, y: 4)
        .padding(8) // room for the shadow inside the hosting view
        .fixedSize()
    }

    private func button(symbol: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: symbol)
                    .font(.system(size: 15, weight: .medium))
                Text(title)
                    .font(.system(size: 10))
            }
            .frame(minWidth: 48)
            .padding(.vertical, 6)
            .padding(.horizontal, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(ToolbarButtonStyle())
    }
}

private struct ToolbarButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.primary)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(configuration.isPressed ? Color.accentColor.opacity(0.25) : Color.clear)
            )
            .contentShape(Rectangle())
    }
}

/// Borderless, non-activating floating bar. It never becomes key, so the
/// source app keeps its selection while the bar is visible.
final class SelectionToolbarPanel: NSPanel {
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 10, height: 10),
            styleMask: [.nonactivatingPanel, .borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        isReleasedWhenClosed = false
        level = .statusBar
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false // the SwiftUI view draws its own shadow
        isMovable = false
        hidesOnDeactivate = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
