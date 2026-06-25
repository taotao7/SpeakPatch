# SpeakPatch Beige Terminal Minimal Flat Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Apply the Beige Terminal minimal-flat theme to SpeakPatch's main rewrite panel, selection toolbar, and Settings window, shrinking the popup to 480 × 380.

**Architecture:** Add a single `Theme.swift` source of truth for the Beige Terminal palette. Update the three SwiftUI views and the coordinator that sizes the floating panel. No new view models or behavior changes; this is a pure visual restyling.

**Tech Stack:** Swift 5.9, SwiftUI, AppKit (`NSPanel`), `swift build` for verification.

## Global Constraints

- Theme variant: Light only — Beige Terminal.
- Panel size: Compact — 480 × 380.
- Scope: Main panel + selection toolbar + Settings window.
- Visual personality: Minimal Flat / retro workstation.
- No dark mode, no runtime theme switcher, no new animations.
- macOS 13+ target (from `Package.swift`).
- All colors must come from the provided Beige Terminal palette.

## File Structure

| File | Responsibility |
|------|----------------|
| `Sources/SpeakPatch/Theme.swift` | New. Static color constants + hex `Color` initializer. |
| `Sources/SpeakPatch/RewritePanelView.swift` | Redesigned main panel: 480 × 380, tab bar, flat editors, simplified header. |
| `Sources/SpeakPatch/SelectionToolbarView.swift` | Recolored PopClip-style toolbar using theme colors. |
| `Sources/SpeakPatch/SettingsView.swift` | Recolored grouped settings form and custom-styled fields. |
| `Sources/SpeakPatch/AppCoordinator.swift` | Adjust `FloatingPanel` content size to 480 × 380. |

## Task 1: Add the theme color constants

**Files:**
- Create: `Sources/SpeakPatch/Theme.swift`
- Test: `swift build`

**Interfaces:**
- Produces: `Theme` enum with static `Color` values; `Color.init(hex:)` initializer.

- [ ] **Step 1: Create `Theme.swift`**

```swift
import SwiftUI

enum Theme {
    static let background = Color(hex: "#f5f0e8ff")
    static let elevatedSurface = Color(hex: "#faf8f4ff")
    static let surface = Color(hex: "#ede8e0ff")
    static let border = Color(hex: "#c4b8a8ff")
    static let text = Color(hex: "#2d2a27ff")
    static let textMuted = Color(hex: "#6b6560ff")
    static let textPlaceholder = Color(hex: "#928374ff")
    static let accent = Color(hex: "#d65d0eff")
    static let success = Color(hex: "#458588ff")
    static let error = Color(hex: "#9d0006ff")
    static let errorBackground = Color(hex: "#9d00061a")
    static let hover = Color(hex: "#e8e0d6ff")
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
```

- [ ] **Step 2: Build to verify it compiles**

Run: `swift build`
Expected: succeeds with no errors.

- [ ] **Step 3: Commit**

```bash
git add Sources/SpeakPatch/Theme.swift
git commit -m "feat(theme): add Beige Terminal color constants"
```

## Task 2: Redesign the main rewrite panel

**Files:**
- Modify: `Sources/SpeakPatch/RewritePanelView.swift`
- Test: `swift build`, visual inspection

**Interfaces:**
- Consumes: `Theme` colors and `Color.init(hex:)`.
- Produces: Updated `RewritePanelView` at 480 × 380 with tab-style action bar.

- [ ] **Step 1: Replace the entire contents of `RewritePanelView.swift`**

```swift
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
        .frame(width: 480, height: 380)
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
        HStack(spacing: 0) {
            ForEach(RewriteAction.allCases) { action in
                Button {
                    selectedAction = action
                    run(action)
                } label: {
                    Text(action.shortTitle)
                        .font(.system(size: 11, weight: selectedAction == action ? .semibold : .medium))
                        .foregroundStyle(selectedAction == action ? Theme.accent : Theme.textMuted)
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
                .disabled(inputIsEmpty || isLoading)
                .help(action.rawValue)
            }
        }
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
            }
            .disabled(outputText.isEmpty)
            .foregroundStyle(outputText.isEmpty ? Theme.textMuted : Theme.accent)

            Button {
                inputText = outputText
            } label: {
                Text("Replace")
                    .font(.system(size: 12, weight: .medium))
            }
            .disabled(outputText.isEmpty)
            .foregroundStyle(outputText.isEmpty ? Theme.textMuted : Theme.textMuted)

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
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .foregroundStyle(Theme.textMuted)
                .frame(width: 24, height: 24)
                .background(
                    configuration.isPressed ? Theme.hover : Color.clear,
                    in: RoundedRectangle(cornerRadius: 5, style: .continuous)
                )
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
```

- [ ] **Step 2: Build to verify it compiles**

Run: `swift build`
Expected: succeeds with no errors.

- [ ] **Step 3: Commit**

```bash
git add Sources/SpeakPatch/RewritePanelView.swift
git commit -m "feat(ui): redesign main panel with Beige Terminal minimal-flat style"
```

## Task 3: Recolor the selection toolbar

**Files:**
- Modify: `Sources/SpeakPatch/SelectionToolbarView.swift`
- Test: `swift build`, visual inspection

**Interfaces:**
- Consumes: `Theme` colors.
- Produces: Updated `SelectionToolbarView` with beige background, border, and flat hover state.

- [ ] **Step 1: Replace the entire contents of `SelectionToolbarView.swift`**

```swift
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
                .frame(height: 24)
                .padding(.horizontal, 2)

            button(symbol: "ellipsis", title: "More") {
                onOpen()
            }
        }
        .padding(4)
        .background(Theme.background, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Theme.border, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.12), radius: 10, y: 4)
        .padding(8) // room for the shadow inside the hosting view
        .fixedSize()
    }

    private func button(symbol: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: symbol)
                    .font(.system(size: 14, weight: .medium))
                Text(title)
                    .font(.system(size: 9))
            }
            .frame(minWidth: 44)
            .padding(.vertical, 5)
            .padding(.horizontal, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(ToolbarButtonStyle())
    }
}

private struct ToolbarButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Theme.text)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(configuration.isPressed ? Theme.hover : Color.clear)
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
```

- [ ] **Step 2: Build to verify it compiles**

Run: `swift build`
Expected: succeeds with no errors.

- [ ] **Step 3: Commit**

```bash
git add Sources/SpeakPatch/SelectionToolbarView.swift
git commit -m "feat(ui): recolor selection toolbar with Beige Terminal theme"
```

## Task 4: Recolor the Settings window

**Files:**
- Modify: `Sources/SpeakPatch/SettingsView.swift`
- Test: `swift build`, visual inspection

**Interfaces:**
- Consumes: `Theme` colors.
- Produces: Updated `SettingsView` with beige palette and custom-styled fields.

- [ ] **Step 1: Replace the entire contents of `SettingsView.swift`**

```swift
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        Form {
            Section {
                LabeledContent("Base URL") {
                    TextField("https://api.openai.com", text: $settings.baseURL)
                        .beigeTextField()
                }
                LabeledContent("API Key") {
                    SecureField("sk-…", text: $settings.apiKey)
                        .beigeTextField()
                }
                LabeledContent("Model") {
                    TextField("gpt-4o-mini", text: $settings.model)
                        .beigeTextField()
                }
                LabeledContent("Path") {
                    TextField("/v1/chat/completions", text: $settings.path)
                        .beigeTextField()
                }
                LabeledContent("Temperature") {
                    HStack(spacing: 10) {
                        Slider(value: $settings.temperature, in: 0...1)
                        Text(String(format: "%.1f", settings.temperature))
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(Theme.textMuted)
                            .frame(width: 30, alignment: .trailing)
                    }
                }
            } header: {
                Text("OpenAI-compatible Provider")
                    .foregroundStyle(Theme.accent)
            }

            Section {
                Picker("Preset", selection: $settings.selectedPreset) {
                    ForEach(PromptPreset.allCases) { preset in
                        Text(preset.rawValue).tag(preset.rawValue)
                    }
                }
                .onChange(of: settings.selectedPreset) { newValue in
                    if let preset = PromptPreset(rawValue: newValue) {
                        settings.systemPrompt = preset.systemPrompt
                    }
                }

                TextEditor(text: $settings.systemPrompt)
                    .font(.system(size: 12, design: .monospaced))
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .frame(height: 150)
                    .foregroundStyle(Theme.text)
                    .background(Theme.elevatedSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(Theme.border, lineWidth: 1)
                    )

                HStack {
                    Button {
                        if let preset = PromptPreset(rawValue: settings.selectedPreset) {
                            settings.systemPrompt = preset.systemPrompt
                        }
                    } label: {
                        Label("Reset to preset", systemImage: "arrow.counterclockwise")
                    }
                    .buttonStyle(BeigeButtonStyle())

                    Spacer()

                    Button {
                        settings.selectedPreset = PromptPreset.grammarOnly.rawValue
                        settings.systemPrompt = PromptPreset.grammarOnly.systemPrompt
                    } label: {
                        Label("Use Grammar Only", systemImage: "checkmark.circle")
                    }
                    .buttonStyle(BeigeButtonStyle())
                }
            } header: {
                Text("System Prompt")
                    .foregroundStyle(Theme.accent)
            }

            Section {
                Toggle("Show quick toolbar when I select text", isOn: $settings.autoToolbarEnabled)
                Text("Requires Accessibility permission. Reads selected text via the Accessibility API without touching your clipboard.")
                    .font(.footnote)
                    .foregroundStyle(Theme.textMuted)

                Toggle("Show quick toolbar for terminal clipboard changes", isOn: $settings.terminalClipboardToolbarEnabled)
                Text("Only runs while a terminal app is frontmost, after a short debounce, and ignores paths, URLs, code-like blocks, large JSON, and token-like text.")
                    .font(.footnote)
                    .foregroundStyle(Theme.textMuted)
            } header: {
                Text("Behavior")
                    .foregroundStyle(Theme.accent)
            }

            Section {
                exampleRow(provider: "OpenAI", url: "https://api.openai.com", model: "gpt-4o-mini")
                exampleRow(provider: "DeepSeek", url: "https://api.deepseek.com", model: "deepseek-chat")
                Text("Any compatible endpoint works with path /v1/chat/completions.")
                    .font(.footnote)
                    .foregroundStyle(Theme.textMuted)
            } header: {
                Text("Examples")
                    .foregroundStyle(Theme.accent)
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .frame(width: 560, height: 600)
    }

    private func exampleRow(provider: String, url: String, model: String) -> some View {
        HStack(spacing: 6) {
            Text(provider)
                .font(.system(size: 12, weight: .medium))
                .frame(width: 64, alignment: .leading)
            Text(url)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(Theme.accent)
            Text("·")
                .foregroundStyle(Theme.textMuted)
            Text(model)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(Theme.textMuted)
            Spacer()
        }
    }
}

private struct BeigeTextFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .textFieldStyle(.plain)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .foregroundStyle(Theme.text)
            .background(Theme.elevatedSurface)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(Theme.border, lineWidth: 1)
            )
    }
}

private extension View {
    func beigeTextField() -> some View {
        modifier(BeigeTextFieldStyle())
    }
}

private struct BeigeButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(Theme.text)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                configuration.isPressed ? Theme.hover : Theme.elevatedSurface,
                in: RoundedRectangle(cornerRadius: 6, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(Theme.border, lineWidth: 1)
            )
    }
}
```

- [ ] **Step 2: Build to verify it compiles**

Run: `swift build`
Expected: succeeds with no errors.

- [ ] **Step 3: Commit**

```bash
git add Sources/SpeakPatch/SettingsView.swift
git commit -m "feat(ui): recolor settings window with Beige Terminal theme"
```

## Task 5: Resize the floating panel

**Files:**
- Modify: `Sources/SpeakPatch/AppCoordinator.swift`
- Test: `swift build`, visual inspection

**Interfaces:**
- Consumes: New 480 × 380 panel size from the design.
- Produces: `FloatingPanel` content rect updated to 480 × 380.

- [ ] **Step 1: Update the panel size in `AppCoordinator.swift`**

Locate:

```swift
let newPanel = FloatingPanel(contentRect: NSRect(x: 0, y: 0, width: 560, height: 460))
```

Replace with:

```swift
let newPanel = FloatingPanel(contentRect: NSRect(x: 0, y: 0, width: 480, height: 380))
```

- [ ] **Step 2: Build to verify it compiles**

Run: `swift build`
Expected: succeeds with no errors.

- [ ] **Step 3: Commit**

```bash
git add Sources/SpeakPatch/AppCoordinator.swift
git commit -m "feat(ui): shrink floating panel to 480 x 380"
```

## Task 6: Final build and visual verification

**Files:**
- All modified files.
- Test: manual build + launch.

- [ ] **Step 1: Build release binary**

Run: `swift build -c release`
Expected: succeeds with no errors.

- [ ] **Step 2: Package and run the app**

Run: `./scripts/build-app.sh release && open SpeakPatch.app`
Expected: app launches and shows the menu-bar icon.

- [ ] **Step 3: Verify visual acceptance criteria**

Checklist:
- [ ] Main panel opens at 480 × 380.
- [ ] Panel background is warm beige (`#f5f0e8`).
- [ ] Action bar shows five tabs with accent underline on active tab.
- [ ] Input/Result editors have beige card surfaces and thin borders.
- [ ] Selection toolbar uses beige background and border.
- [ ] Settings window uses beige palette and styled text fields.
- [ ] Copy/Replace/footer buttons are flat text buttons.

- [ ] **Step 4: Commit any final tweaks**

```bash
git add -A
git commit -m "chore: final visual polish"
```

## Plan Self-Review

1. **Spec coverage:**
   - Color palette constants → Task 1.
   - Main panel 480 × 380 + tab bar + flat editors → Task 2.
   - Toolbar recolor → Task 3.
   - Settings recolor → Task 4.
   - Panel resize → Task 5.
   - Build/verification → Task 6.
   - No gaps identified.

2. **Placeholder scan:**
   - No TBD/TODO.
   - All code blocks are complete.
   - All commands have expected outputs.

3. **Type consistency:**
   - `Theme` enum used consistently across tasks.
   - `Color.init(hex:)` supports 8-character hex strings used in Theme.swift.
   - `BeigeTextFieldStyle` and `BeigeButtonStyle` are private helpers in SettingsView.swift.

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-06-25-speakpatch-beige-terminal-redesign.md`.

**Two execution options:**

1. **Subagent-Driven (recommended)** — I dispatch a fresh subagent per task, review between tasks, fast iteration.
2. **Inline Execution** — Execute tasks in this session using executing-plans, batch execution with checkpoints.

Which approach?
