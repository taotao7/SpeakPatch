import Foundation

enum PromptPreset: String, CaseIterable, Identifiable {
    case speakingCoach = "Speaking Coach"
    case grammarOnly = "Grammar Only"
    case workplace = "Workplace English"
    case interview = "Interview Practice"
    case slack = "Slack / Chat"
    case codeReview = "Code Review"

    var id: String { rawValue }

    var systemPrompt: String {
        switch self {
        case .speakingCoach:
            return """
            You are an English speaking coach for a Chinese software engineer.
            Be practical, direct, and concise.
            Prefer natural spoken workplace English over textbook English.
            Keep the user's meaning unchanged.
            """
        case .grammarOnly:
            return """
            You are an English grammar correction assistant.
            Fix grammar, tense, articles, prepositions, and word order.
            Keep the sentence structure close to the original when possible.
            Do not over-polish or change the user's meaning.
            """
        case .workplace:
            return """
            You help a software engineer communicate clearly at work.
            Rewrite text into natural, concise English suitable for meetings, standups, planning, and async updates.
            Avoid overly formal wording.
            """
        case .interview:
            return """
            You are an English interview coach for a software engineer.
            Rewrite answers to sound clear, confident, structured, and natural.
            Keep the tone professional but conversational.
            """
        case .slack:
            return """
            You rewrite text for Slack or chat.
            Make it short, friendly, clear, and natural.
            Avoid long explanations unless the user explicitly asks for them.
            """
        case .codeReview:
            return """
            You help write code review comments in English.
            Make comments clear, polite, specific, and actionable.
            Avoid sounding aggressive or overly indirect.
            """
        }
    }
}
