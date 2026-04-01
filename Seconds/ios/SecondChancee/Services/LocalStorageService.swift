import Foundation

class LocalStorageService {
    private let summariesKey = "conversation_summaries"
    private let maxSummaries = 5

    func saveSummary(_ summary: String) {
        var summaries = getSummaries()
        summaries.append(summary)
        if summaries.count > maxSummaries {
            summaries = Array(summaries.suffix(maxSummaries))
        }
        UserDefaults.standard.set(summaries, forKey: summariesKey)
    }

    func getSummaries() -> [String] {
        UserDefaults.standard.stringArray(forKey: summariesKey) ?? []
    }

    func clearAll() {
        UserDefaults.standard.removeObject(forKey: summariesKey)
    }
}
