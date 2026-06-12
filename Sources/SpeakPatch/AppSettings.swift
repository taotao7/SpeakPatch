import Foundation

final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var baseURL: String { didSet { UserDefaults.standard.set(baseURL, forKey: Keys.baseURL) } }
    @Published var apiKey: String { didSet { UserDefaults.standard.set(apiKey, forKey: Keys.apiKey) } }
    @Published var model: String { didSet { UserDefaults.standard.set(model, forKey: Keys.model) } }
    @Published var path: String { didSet { UserDefaults.standard.set(path, forKey: Keys.path) } }
    @Published var temperature: Double { didSet { UserDefaults.standard.set(temperature, forKey: Keys.temperature) } }
    @Published var systemPrompt: String { didSet { UserDefaults.standard.set(systemPrompt, forKey: Keys.systemPrompt) } }
    @Published var selectedPreset: String { didSet { UserDefaults.standard.set(selectedPreset, forKey: Keys.selectedPreset) } }
    @Published var autoToolbarEnabled: Bool { didSet { UserDefaults.standard.set(autoToolbarEnabled, forKey: Keys.autoToolbarEnabled) } }

    private enum Keys {
        static let baseURL = "provider.baseURL"
        static let apiKey = "provider.apiKey"
        static let model = "provider.model"
        static let path = "provider.path"
        static let temperature = "provider.temperature"
        static let systemPrompt = "prompt.systemPrompt"
        static let selectedPreset = "prompt.selectedPreset"
        static let autoToolbarEnabled = "behavior.autoToolbarEnabled"
    }

    private init() {
        baseURL = UserDefaults.standard.string(forKey: Keys.baseURL) ?? "https://api.openai.com"
        apiKey = UserDefaults.standard.string(forKey: Keys.apiKey) ?? ""
        model = UserDefaults.standard.string(forKey: Keys.model) ?? "gpt-4o-mini"
        path = UserDefaults.standard.string(forKey: Keys.path) ?? "/v1/chat/completions"
        let savedTemperature = UserDefaults.standard.object(forKey: Keys.temperature) as? Double
        temperature = savedTemperature ?? 0.2
        selectedPreset = UserDefaults.standard.string(forKey: Keys.selectedPreset) ?? PromptPreset.speakingCoach.rawValue
        systemPrompt = UserDefaults.standard.string(forKey: Keys.systemPrompt) ?? PromptPreset.speakingCoach.systemPrompt
        let savedAutoToolbar = UserDefaults.standard.object(forKey: Keys.autoToolbarEnabled) as? Bool
        autoToolbarEnabled = savedAutoToolbar ?? true
    }
}
