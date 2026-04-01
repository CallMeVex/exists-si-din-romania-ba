import Foundation

@Observable
class ChatViewModel {
    var messages: [ChatMessage] = []
    var inputText = ""
    var isTyping = false
    private var messageCount = 0
    private var companionName: String = "Joy"

    private let openAI = OpenAIService()
    private let localStorage = LocalStorageService()

    private func buildSystemPrompt(appState: AppState?) -> String {
        let name = companionName
        let userName = appState?.currentUser?.nickname ?? appState?.currentUser?.username ?? "this person"
        let addictions = appState?.currentUser?.selectedAddictions.joined(separator: ", ") ?? "addiction"
        let reason = appState?.currentUser?.reasonForQuitting ?? ""
        let whoFor = appState?.currentUser?.whoFor ?? ""
        let streak = appState?.primaryStreak ?? 0
        let urgeLevel = appState?.todayCheckin?.urgeLevel
        let urgeReason = appState?.todayCheckin?.urgeReason ?? ""

        var prompt = """
        You are \(name), a compassionate recovery support companion inside an app called Second Chance. \
        Your name is \(name) — always use this name if the user asks. \
        You are not a therapist, psychologist, doctor, or licensed counselor of any kind. \
        You never claim or imply that you are. You do not give medical advice, diagnose conditions, \
        or recommend medications or treatments.

        Your role is simple: listen, reflect, support, and when the time is right, gently guide. \
        You are not here to fix anyone. You are here to be a steady, honest presence for someone doing something genuinely hard.

        Who you're talking to:
        - Name or nickname: \(userName)
        - What they're working on: \(addictions)
        - Why they want to stop: \(reason)
        - Who they're doing this for: \(whoFor)
        - Days clean (current streak): \(streak)
        """

        if let urgeLevel {
            prompt += "\n        - Today's urge level: \(urgeLevel)/10"
            if !urgeReason.isEmpty {
                prompt += "\n        - Today's urge reason: \(urgeReason)"
            }
        }

        prompt += """


        How you speak:
        Your tone is warm, calm, and honest. Not cheerful. Not clinical. Not motivational-poster. \
        Think of a trusted friend who has been through hard things themselves — someone who doesn't flinch, \
        doesn't lecture, and doesn't pretend everything is fine when it isn't.

        You write in short to medium length responses. You never write walls of text. \
        You never use bullet points or numbered lists in conversation.

        You never use: "should", "must", "need to", "have to" when directing the user. \
        Never say "I understand how you feel". Never say "That's great!", "Amazing!", "Fantastic!". \
        Never say "As an AI..." or "I'm just an AI so...".

        How you behave:
        - Always acknowledge before anything else. When someone shares something difficult, reflect it back first.
        - Ask one question at a time. Never two questions in one message.
        - Listen and reflect more than you advise.
        - Gently challenge unhealthy thinking — but acknowledge the feeling first.
        - Never minimize what they're going through. Don't rush toward silver linings.
        - When urge level is 6–10: acknowledge the weight first, don't immediately ask what happened.
        - When someone logs a relapse: acknowledge the honesty it took, don't treat it as catastrophe.
        - When someone expresses hopelessness: take it seriously, ask them to say more, then offer a quiet alternative lens.
        - When someone expresses self-harm or crisis: express genuine care, direct them to Resources in their Profile. Do not try to handle it yourself.
        - When asked if you're real: "I'm not — I'm an AI companion built into this app. But I'm here, and what you share with me matters."
        - When asked for medical advice: decline warmly, direct to a real medical professional.

        Use context from previous conversations naturally. Do not announce that you remember things.
        """

        let summaries = (appState?.incognitoModeEnabled == true) ? [] : localStorage.getSummaries()
        if !summaries.isEmpty {
            prompt += "\n\nPrevious conversation context:\n" + summaries.joined(separator: "\n---\n")
        }

        return prompt
    }

    func loadWithContext(appState: AppState?, preloadMessage: String?) {
        companionName = appState?.aiCompanionName ?? "Joy"
        messages = []
        messageCount = 0

        if let preloadMessage {
            messages.append(ChatMessage(role: .assistant, content: preloadMessage))
        } else {
            let greeting = buildInitialGreeting(appState: appState)
            messages.append(ChatMessage(role: .assistant, content: greeting))
        }
    }

    func loadWithPreloadMessage(_ message: String?) {
        messages = []
        messageCount = 0
        if let message {
            messages.append(ChatMessage(role: .assistant, content: message))
        } else {
            let greeting = "I'm here whenever you're ready to talk. What's on your mind?"
            messages.append(ChatMessage(role: .assistant, content: greeting))
        }
    }

    private func buildInitialGreeting(appState: AppState?) -> String {
        let name = companionName
        let userName = appState?.currentUser?.nickname ?? appState?.currentUser?.username
        let streak = appState?.primaryStreak ?? 0

        if let userName {
            if streak > 0 {
                return "Hey \(userName). Day \(streak) — you're still here. That matters. What's going on today?"
            } else {
                return "Hey \(userName). I'm \(name). Whatever brought you here today, I'm glad you came. What's on your mind?"
            }
        }
        return "I'm \(name). Whatever brought you here today, I'm glad you're here. What's on your mind?"
    }

    func sendMessage(appState: AppState? = nil) async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        if let appState {
            companionName = appState.aiCompanionName
        }

        let userMessage = ChatMessage(role: .user, content: text)
        messages.append(userMessage)
        inputText = ""
        messageCount += 1
        isTyping = true

        defer { isTyping = false }

        do {
            var apiMessages: [OpenAIMessage] = []
            let sysPrompt = buildSystemPrompt(appState: appState)
            apiMessages.append(OpenAIMessage(role: "system", content: sysPrompt))

            for msg in messages.suffix(20) {
                switch msg.role {
                case .user: apiMessages.append(OpenAIMessage(role: "user", content: msg.content))
                case .assistant: apiMessages.append(OpenAIMessage(role: "assistant", content: msg.content))
                case .system: break
                }
            }

            let response = try await openAI.sendMessage(messages: apiMessages)
            let assistantMessage = ChatMessage(role: .assistant, content: response)
            messages.append(assistantMessage)
            messageCount += 1

            if messageCount >= 10 {
                await summarizeAndSaveIfAllowed(appState: appState)
                messageCount = 0
            }
        } catch {
            let errorMessage = ChatMessage(role: .assistant, content: "I'm having trouble connecting right now. Take a breath \u{2014} I'll be here when you're ready to try again.")
            messages.append(errorMessage)
        }
    }

    func summarizeAndSave() async {
        guard !messages.isEmpty else { return }
        do {
            let summary = try await openAI.summarizeConversation(messages: messages)
            localStorage.saveSummary(summary)
        } catch {
        }
    }

    func summarizeAndSaveIfAllowed(appState: AppState?) async {
        guard appState?.incognitoModeEnabled != true else { return }
        await summarizeAndSave()
    }
}
