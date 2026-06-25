import SwiftUI
import AppKit

struct RewritePanelView: View {
    @EnvironmentObject var settings: AppSettings
    @State private var inputText: String
    @State private var outputText: String = ""
    @State private var selectedAction: RewriteAction = .fixGrammar
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var didCopy = false

    private let autoRunAction: RewriteAction?

    init(initialText: String, autoRunAction: RewriteAction? = nil) {
        _inputText = State(initialValue: initialText)
        self.autoRunAction = autoRunAction
    }

    private var inputIsEmpty: Bool {
        inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            actionBar

            editor(
                title: "Input",
                text: $inputText,
                placeholder: "Type or paste the text you want to improve…",
                minHeight: 72
            )

            resultSection
            footer
        }
        .padding(16)
        .frame(width: Theme.panelSize.width, height: Theme.panelSize.height)
        .background(Theme.background)
        .onAppear {
            if let autoRunAction {
                selectedAction = autoRunAction
                run(autoRunAction)
            }
        }
        .onExitCommand {
            NSApp.keyWindow?.close()
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 0) {
                Text("SpeakPatch")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.text)
                Text(settings.selectedPreset)
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.textMuted)
            }

            Spacer()

            Button {
                openSettings()
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 13, weight: .medium))
            }
            .buttonStyle(PanelIconButtonStyle())
            .help("Settings")

            Button {
                NSApp.keyWindow?.close()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .medium))
            }
            .buttonStyle(PanelIconButtonStyle())
            .help("Close")
        }
    }

    // MARK: - Action bar

    private var actionBar: some View {
        let isDisabled = inputIsEmpty || isLoading
        return HStack(spacing: 0) {
            ForEach(RewriteAction.allCases) { action in
                Button {
                    selectedAction = action
                    run(action)
                } label: {
                    Text(action.shortTitle)
                        .font(.system(size: 11, weight: selectedAction == action ? .semibold : .medium))
                        .foregroundStyle(actionTabForeground(isSelected: selectedAction == action, isDisabled: isDisabled))
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity)
                        .overlay(alignment: .bottom) {
                            Rectangle()
                                .fill(Theme.accent)
                                .frame(height: selectedAction == action ? 2 : 0)
                        }
                }
                .buttonStyle(.plain)
                .disabled(isDisabled)
                .help(action.rawValue)
            }
        }
    }

    private func actionTabForeground(isSelected: Bool, isDisabled: Bool) -> Color {
        if isDisabled {
            return Theme.textMuted.opacity(0.5)
        }
        return isSelected ? Theme.accent : Theme.textMuted
    }

    // MARK: - Result

    private var resultSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text("Result")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.textMuted)
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                        .scaleEffect(0.7)
                    Text("Rewriting…")
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.textMuted)
                }
                Spacer()
            }

            ZStack(alignment: .topLeading) {
                cardEditor(text: $outputText, minHeight: 88)

                if outputText.isEmpty && !isLoading {
                    Text("Your rewritten text will appear here.")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textPlaceholder)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .allowsHitTesting(false)
                }
            }

            if let errorMessage {
                errorBanner(errorMessage)
            }
        }
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 11))
            Text(message)
                .font(.system(size: 11))
            Spacer(minLength: 0)
        }
        .foregroundStyle(Theme.error)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Theme.errorBackground, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 12) {
            Button {
                copy(outputText)
            } label: {
                Text(didCopy ? "Copied" : "Copy")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(outputText.isEmpty ? Theme.textMuted.opacity(0.5) : Theme.accent)
            }
            .disabled(outputText.isEmpty)

            Button {
                inputText = outputText
            } label: {
                Text("Replace")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(outputText.isEmpty ? Theme.textMuted.opacity(0.5) : Theme.textMuted)
            }
            .disabled(outputText.isEmpty)

            Spacer()

            Text("⌘⇧E")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(Theme.textMuted)
        }
    }

    // MARK: - Editors

    private func editor(title: String, text: Binding<String>, placeholder: String, minHeight: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Theme.textMuted)

            ZStack(alignment: .topLeading) {
                cardEditor(text: text, minHeight: minHeight)

                if text.wrappedValue.isEmpty {
                    Text(placeholder)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textPlaceholder)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .allowsHitTesting(false)
                }
            }
        }
    }

    private func cardEditor(text: Binding<String>, minHeight: CGFloat) -> some View {
        TextEditor(text: text)
            .font(.system(size: 12))
            .scrollContentBackground(.hidden)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .frame(minHeight: minHeight)
            .foregroundStyle(Theme.text)
            .background(Theme.elevatedSurface)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(Theme.border, lineWidth: 1)
            )
    }

    // MARK: - Button styles

    private struct PanelIconButtonStyle: ButtonStyle {
        @State private var isHovered = false

        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .foregroundStyle(Theme.textMuted)
                .frame(width: 24, height: 24)
                .background(
                    (configuration.isPressed || isHovered) ? Theme.hover : Color.clear,
                    in: RoundedRectangle(cornerRadius: 5, style: .continuous)
                )
                .onHover { isHovered = $0 }
        }
    }

    // MARK: - Actions

    private func run(_ action: RewriteAction) {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        outputText = ""
        Task {
            do {
                let result = try await LLMClient(settings: settings).rewrite(text: text, action: action)
                await MainActor.run { outputText = result; isLoading = false }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }

    private func copy(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        withAnimation { didCopy = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation { didCopy = false }
        }
    }

    private func openSettings() {
        SettingsWindowController.shared.show()
    }
}
