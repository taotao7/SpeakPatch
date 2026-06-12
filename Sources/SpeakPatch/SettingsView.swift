import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        Form {
            Section {
                LabeledContent("Base URL") {
                    TextField("https://api.openai.com", text: $settings.baseURL)
                        .textFieldStyle(.roundedBorder)
                }
                LabeledContent("API Key") {
                    SecureField("sk-…", text: $settings.apiKey)
                        .textFieldStyle(.roundedBorder)
                }
                LabeledContent("Model") {
                    TextField("gpt-4o-mini", text: $settings.model)
                        .textFieldStyle(.roundedBorder)
                }
                LabeledContent("Path") {
                    TextField("/v1/chat/completions", text: $settings.path)
                        .textFieldStyle(.roundedBorder)
                }
                LabeledContent("Temperature") {
                    HStack(spacing: 10) {
                        Slider(value: $settings.temperature, in: 0...1)
                        Text(String(format: "%.1f", settings.temperature))
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .frame(width: 30, alignment: .trailing)
                    }
                }
            } header: {
                Text("OpenAI-compatible Provider")
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
                    .padding(.horizontal, 7)
                    .padding(.vertical, 5)
                    .frame(height: 150)
                    .background(Color(nsColor: .textBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(Color(nsColor: .separatorColor), lineWidth: 1)
                    )

                HStack {
                    Button {
                        if let preset = PromptPreset(rawValue: settings.selectedPreset) {
                            settings.systemPrompt = preset.systemPrompt
                        }
                    } label: {
                        Label("Reset to preset", systemImage: "arrow.counterclockwise")
                    }
                    Spacer()
                    Button {
                        settings.selectedPreset = PromptPreset.grammarOnly.rawValue
                        settings.systemPrompt = PromptPreset.grammarOnly.systemPrompt
                    } label: {
                        Label("Use Grammar Only", systemImage: "checkmark.circle")
                    }
                }
            } header: {
                Text("System Prompt")
            }

            Section {
                Toggle("Show quick toolbar when I select text", isOn: $settings.autoToolbarEnabled)
                Text("Requires Accessibility permission. Reads selected text via the Accessibility API without touching your clipboard.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Toggle("Show quick toolbar for terminal clipboard changes", isOn: $settings.terminalClipboardToolbarEnabled)
                Text("Only runs while a terminal app is frontmost, after a short debounce, and ignores paths, URLs, code-like blocks, large JSON, and token-like text.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Behavior")
            }

            Section {
                exampleRow(provider: "OpenAI", url: "https://api.openai.com", model: "gpt-4o-mini")
                exampleRow(provider: "DeepSeek", url: "https://api.deepseek.com", model: "deepseek-chat")
                Text("Any compatible endpoint works with path /v1/chat/completions.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Examples")
            }
        }
        .formStyle(.grouped)
        .frame(width: 560, height: 600)
    }

    private func exampleRow(provider: String, url: String, model: String) -> some View {
        HStack(spacing: 6) {
            Text(provider)
                .font(.system(size: 12, weight: .medium))
                .frame(width: 64, alignment: .leading)
            Text(url)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(Color.accentColor)
            Text("·")
                .foregroundStyle(.secondary)
            Text(model)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(.secondary)
            Spacer()
        }
    }
}
