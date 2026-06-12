import Foundation

enum SelectionTriggerMode {
    case selection
    case terminalClipboard
}

struct SelectionCandidateFilter {
    static func cleanedText(from rawText: String, mode: SelectionTriggerMode) -> String? {
        let text = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.count >= 2, text.count <= 2_000 else { return nil }

        switch mode {
        case .selection:
            return text
        case .terminalClipboard:
            guard !isPureURL(text),
                  !isPurePath(text),
                  !isLargeJSON(text),
                  !looksLikeCode(text),
                  !looksLikeSecretOrToken(text) else {
                return nil
            }
            return text
        }
    }

    static func normalizedKey(for text: String) -> String {
        text
            .split(whereSeparator: { $0.isWhitespace })
            .joined(separator: " ")
            .lowercased()
    }

    private static func isPureURL(_ text: String) -> Bool {
        guard text.rangeOfCharacter(from: .whitespacesAndNewlines) == nil else { return false }
        let lowered = text.lowercased()
        if lowered.hasPrefix("www.") { return true }
        guard let components = URLComponents(string: text),
              let scheme = components.scheme?.lowercased() else {
            return false
        }
        return ["http", "https", "ftp", "ssh", "file", "mailto"].contains(scheme) &&
            (components.host != nil || scheme == "mailto" || scheme == "file")
    }

    private static func isPurePath(_ text: String) -> Bool {
        guard !text.contains("\n") else { return false }
        let pathPrefixes = ["/", "~/", "./", "../"]
        if pathPrefixes.contains(where: { text.hasPrefix($0) }) {
            return true
        }
        guard text.contains("/") else { return false }
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~/%+@")
        guard text.unicodeScalars.allSatisfy({ allowed.contains($0) }) else { return false }
        return true
    }

    private static func isLargeJSON(_ text: String) -> Bool {
        guard text.count > 80 || text.contains("\n") else { return false }
        let startsLikeJSON = (text.hasPrefix("{") && text.hasSuffix("}")) ||
            (text.hasPrefix("[") && text.hasSuffix("]"))
        guard startsLikeJSON, let data = text.data(using: .utf8) else { return false }
        return (try? JSONSerialization.jsonObject(with: data)) != nil
    }

    private static func looksLikeCode(_ text: String) -> Bool {
        if text.contains("```") { return true }

        let lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        if lines.count >= 3 {
            var codeishLineCount = 0
            for line in lines {
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { continue }
                if line.hasPrefix("    ") || line.hasPrefix("\t") {
                    codeishLineCount += 1
                }
                if codePrefixes.contains(where: { trimmed.hasPrefix($0) }) ||
                    codeSuffixes.contains(where: { trimmed.hasSuffix($0) }) ||
                    trimmed.contains("=>") ||
                    trimmed.contains(" = ") {
                    codeishLineCount += 1
                }
            }
            if codeishLineCount >= 2 { return true }
        }

        let nonWhitespace = text.filter { !$0.isWhitespace }
        guard text.contains("\n"), !nonWhitespace.isEmpty else { return false }
        let codeCharacterCount = nonWhitespace.filter { "{}[]();=<>`".contains($0) }.count
        return Double(codeCharacterCount) / Double(nonWhitespace.count) > 0.18
    }

    private static func looksLikeSecretOrToken(_ text: String) -> Bool {
        guard text.count >= 20,
              text.rangeOfCharacter(from: .whitespacesAndNewlines) == nil else {
            return false
        }
        if text.range(of: #"^[A-Fa-f0-9-]{24,}$"#, options: .regularExpression) != nil {
            return true
        }
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-.+/=:@")
        guard text.unicodeScalars.allSatisfy({ allowed.contains($0) }) else { return false }
        let hasLetter = text.rangeOfCharacter(from: .letters) != nil
        let hasDigit = text.rangeOfCharacter(from: .decimalDigits) != nil
        return hasLetter && hasDigit
    }

    private static let codePrefixes = [
        "#include",
        "async ",
        "await ",
        "case ",
        "class ",
        "const ",
        "def ",
        "enum ",
        "for ",
        "func ",
        "function ",
        "if ",
        "import ",
        "let ",
        "private ",
        "public ",
        "return ",
        "struct ",
        "var ",
        "while "
    ]

    private static let codeSuffixes = [";", "{", "}"]
}
