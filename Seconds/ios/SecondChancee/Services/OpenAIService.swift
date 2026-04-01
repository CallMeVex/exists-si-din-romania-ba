import Foundation

nonisolated struct OpenAIChatRequest: Codable, Sendable {
    let model: String
    let messages: [OpenAIMessage]
    let temperature: Double?
    let maxTokens: Int?

    enum CodingKeys: String, CodingKey {
        case model, messages, temperature
        case maxTokens = "max_tokens"
    }
}

nonisolated struct OpenAIMessage: Codable, Sendable {
    let role: String
    let content: String
}

nonisolated struct OpenAIChatResponse: Codable, Sendable {
    let choices: [Choice]

    struct Choice: Codable, Sendable {
        let message: OpenAIMessage
    }
}

class OpenAIService {
    private let apiKey: String

    init() {
        let info = Bundle.main.infoDictionary
        let infoKey = (info?["OpenAIAPIKey"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let infoExpoKey = (info?["EXPO_PUBLIC_OPENAI_API_KEY"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let envKey = (ProcessInfo.processInfo.environment["EXPO_PUBLIC_OPENAI_API_KEY"] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let configKey = Config.EXPO_PUBLIC_OPENAI_API_KEY.trimmingCharacters(in: .whitespacesAndNewlines)

        self.apiKey = [infoKey, infoExpoKey, envKey, configKey].first(where: { !$0.isEmpty }) ?? ""
    }

    func sendMessage(messages: [OpenAIMessage]) async throws -> String {
        guard !apiKey.isEmpty else {
            throw NSError(
                domain: "OpenAI",
                code: 401,
                userInfo: [NSLocalizedDescriptionKey: "OpenAI API key is missing. Add `OpenAIAPIKey` to Info.plist (or set EXPO_PUBLIC_OPENAI_API_KEY) and try again."]
            )
        }

        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let chatRequest = OpenAIChatRequest(
            model: "gpt-4o",
            messages: messages,
            temperature: 0.8,
            maxTokens: 1000
        )
        request.httpBody = try JSONEncoder().encode(chatRequest)

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
            let apiError = String(data: data, encoding: .utf8) ?? "AI service unavailable. Please try again."
            throw NSError(
                domain: "OpenAI",
                code: httpResponse.statusCode,
                userInfo: [NSLocalizedDescriptionKey: "OpenAI error (\(httpResponse.statusCode)): \(apiError)"]
            )
        }

        let chatResponse = try JSONDecoder().decode(OpenAIChatResponse.self, from: data)
        return chatResponse.choices.first?.message.content ?? "I'm here with you. Take your time."
    }

    func generateAnalysis(journalEntries: [JournalEntry], conversationSummaries: [String]) async throws -> String {
        var contextParts: [String] = []

        if !conversationSummaries.isEmpty {
            contextParts.append("Recent conversation summaries:\n" + conversationSummaries.joined(separator: "\n---\n"))
        }

        for entry in journalEntries.prefix(10) {
            var entryText = "Journal (\(entry.date)):"
            if let responses = entry.promptResponses {
                for (prompt, response) in responses {
                    entryText += "\n  \(prompt): \(response)"
                }
            }
            if let freeText = entry.freeText, !freeText.isEmpty {
                entryText += "\n  Free text: \(freeText)"
            }
            contextParts.append(entryText)
        }

        let systemPrompt = """
        You are generating a compassionate, honest narrative summary for someone in recovery. \
        Based on their journal entries and conversation summaries, write a flowing paragraph that: \
        notices patterns, acknowledges progress, gently highlights areas to be aware of, and offers encouragement. \
        Write in warm second-person ("You've been showing up even when it was hard..."). \
        Do not use bullet points. Do not diagnose. Do not give medical advice. \
        Keep it under 300 words.
        """

        let messages = [
            OpenAIMessage(role: "system", content: systemPrompt),
            OpenAIMessage(role: "user", content: contextParts.joined(separator: "\n\n"))
        ]

        return try await sendMessage(messages: messages)
    }

    func summarizeConversation(messages: [ChatMessage]) async throws -> String {
        let transcript = messages.map { "\($0.role.rawValue): \($0.content)" }.joined(separator: "\n")

        let summaryMessages = [
            OpenAIMessage(role: "system", content: "Summarize this recovery support conversation in 2-3 sentences. Capture the key themes, emotional state, and any insights discussed. Be concise but preserve emotional context."),
            OpenAIMessage(role: "user", content: transcript)
        ]

        return try await sendMessage(messages: summaryMessages)
    }
}
