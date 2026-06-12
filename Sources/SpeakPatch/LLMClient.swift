import Foundation

enum RewriteAction: String, CaseIterable, Identifiable {
    case fixGrammar = "Fix grammar"
    case natural = "Make natural"
    case concise = "Make concise"
    case translate = "Translate"
    case explain = "Explain mistakes"

    var id: String { rawValue }

    /// SF Symbol used in the compact selection toolbar.
    var symbol: String {
        switch self {
        case .fixGrammar: return "checkmark.circle"
        case .natural: return "wand.and.stars"
        case .concise: return "scissors"
        case .translate: return "globe"
        case .explain: return "text.magnifyingglass"
        }
    }

    /// Short label for the compact selection toolbar.
    var shortTitle: String {
        switch self {
        case .fixGrammar: return "Grammar"
        case .natural: return "Rewrite"
        case .concise: return "Concise"
        case .translate: return "Translate"
        case .explain: return "Explain"
        }
    }

    var instruction: String {
        switch self {
        case .fixGrammar:
            return "Correct grammar and wording. Keep the original meaning. Return only the corrected English."
        case .natural:
            return "Rewrite into natural spoken workplace English. Keep it concise and not overly formal. Return only the rewritten English."
        case .concise:
            return "Rewrite into concise English suitable for Slack, standup, or a meeting. Return only the rewritten English."
        case .translate:
            return "Translate the text. If it is Chinese, translate into natural workplace English; if it is English, translate into natural Chinese. Return only the translation, no explanation."
        case .explain:
            return "Explain the grammar or wording problems briefly, then provide a corrected version. Use simple explanations for a Chinese software engineer improving spoken English."
        }
    }
}

struct LLMClient {
    let settings: AppSettings

    func rewrite(text: String, action: RewriteAction) async throws -> String {
        guard !settings.apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw LLMError.missingAPIKey
        }
        guard var components = URLComponents(string: settings.baseURL) else {
            throw LLMError.invalidURL
        }
        let path = settings.path.hasPrefix("/") ? settings.path : "/\(settings.path)"
        components.path = path
        guard let url = components.url else { throw LLMError.invalidURL }

        let requestBody = ChatCompletionRequest(
            model: settings.model,
            messages: [
                .init(role: "system", content: settings.systemPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? PromptPreset.grammarOnly.systemPrompt : settings.systemPrompt),
                .init(role: "user", content: "Task: \(action.instruction)\n\nText:\n\(text)")
            ],
            temperature: settings.temperature
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(settings.apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw LLMError.badResponse }
        guard (200..<300).contains(http.statusCode) else {
            let detail = String(data: data, encoding: .utf8) ?? "HTTP \(http.statusCode)"
            throw LLMError.provider(detail)
        }
        let decoded = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        return decoded.choices.first?.message.content.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}

enum LLMError: LocalizedError {
    case missingAPIKey
    case invalidURL
    case badResponse
    case provider(String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey: return "Missing API key. Open Settings and configure your provider."
        case .invalidURL: return "Invalid provider URL."
        case .badResponse: return "Bad provider response."
        case .provider(let message): return message
        }
    }
}

struct ChatCompletionRequest: Encodable {
    let model: String
    let messages: [ChatMessage]
    let temperature: Double
}

struct ChatMessage: Codable {
    let role: String
    let content: String
}

struct ChatCompletionResponse: Decodable {
    struct Choice: Decodable {
        let message: ChatMessage
    }
    let choices: [Choice]
}
