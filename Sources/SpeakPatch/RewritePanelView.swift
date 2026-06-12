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
        VStack(alignment: .leading, spacing: 16) {
            header
            actionBar

            editor(
                title: "Input",
                text: $inputText,
                placeholder: "Type or paste the text you want to improve…",
                minHeight: 96
            )

            resultSection
            footer
        }
        .padding(20)
        .frame(width: 600, height: 540)
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            if let autoRunAction {
                selectedAction = autoRunAction
                run(autoRunAction)
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "wand.and.stars")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.accentColor)
                .frame(width: 32, height: 32)
                .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 1) {
                Text("SpeakPatch")
                    .font(.system(size: 15, weight: .semibold))
                Text(settings.selectedPreset)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                openSettings()
            } label: {
                Image(systemName: "gearshape")
            }
            .buttonStyle(.borderless)
            .controlSize(.large)
            .help("Settings")

            Button {
                NSApp.keyWindow?.close()
            } label: {
                Image(systemName: "xmark")
            }
            .buttonStyle(.borderless)
            .controlSize(.large)
            .help("Close")
        }
    }

    // MARK: - Action bar

    private var actionBar: some View {
        HStack(spacing: 8) {
            ForEach(RewriteAction.allCases) { action in
                Button {
                    selectedAction = action
                    run(action)
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: action.symbol)
                            .font(.system(size: 11, weight: .medium))
                        Text(action.shortTitle)
                            .font(.system(size: 12, weight: .medium))
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 5)
                }
                .buttonStyle(.borderedProminent)
                .tint(selectedAction == action ? Color.accentColor : Color(nsColor: .controlColor))
                .foregroundStyle(selectedAction == action ? Color.white : Color.primary)
                .disabled(inputIsEmpty || isLoading)
                .help(action.rawValue)
            }
        }
    }

    // MARK: - Result

    private var resultSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text("Result")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                    Text("Rewriting…")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            ZStack(alignment: .topLeading) {
                cardEditor(text: $outputText, minHeight: 130)

                if outputText.isEmpty && !isLoading {
                    Text("Your rewritten text will appear here.")
                        .font(.system(size: 13))
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 11)
                        .allowsHitTesting(false)
                }
            }

            if let errorMessage {
                errorBanner(errorMessage)
            }
        }
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 7) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 12))
            Text(message)
                .font(.footnote)
            Spacer(minLength: 0)
        }
        .foregroundStyle(Color.red)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 8) {
            Button {
                copy(outputText)
            } label: {
                Label(didCopy ? "Copied" : "Copy result", systemImage: didCopy ? "checkmark" : "doc.on.doc")
            }
            .disabled(outputText.isEmpty)

            Button {
                inputText = outputText
            } label: {
                Label("Replace input", systemImage: "arrow.up.to.line")
            }
            .disabled(outputText.isEmpty)

            Spacer()

            Label("⌘⇧E", systemImage: "keyboard")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .controlSize(.large)
    }

    // MARK: - Editors

    private func editor(title: String, text: Binding<String>, placeholder: String, minHeight: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)

            ZStack(alignment: .topLeading) {
                cardEditor(text: text, minHeight: minHeight)

                if text.wrappedValue.isEmpty {
                    Text(placeholder)
                        .font(.system(size: 13))
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 11)
                        .allowsHitTesting(false)
                }
            }
        }
    }

    private func cardEditor(text: Binding<String>, minHeight: CGFloat) -> some View {
        TextEditor(text: text)
            .font(.system(size: 13))
            .scrollContentBackground(.hidden)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .frame(minHeight: minHeight)
            .background(Color(nsColor: .textBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(Color(nsColor: .separatorColor), lineWidth: 1)
            )
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
