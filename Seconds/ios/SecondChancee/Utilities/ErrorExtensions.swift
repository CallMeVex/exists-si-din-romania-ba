import Foundation

extension Task where Success == Never, Failure == Never {
    static func sleepWithErrorHandling(seconds: Double) async {
        do {
            try await Task.sleep(for: .seconds(seconds))
        } catch {
            ErrorViewModel.shared.showError(error)
        }
    }
}

func withErrorHandling<T>(
    file: String = #file,
    function: String = #function,
    line: Int = #line,
    operation: () async throws -> T
) async -> T? {
    do {
        return try await operation()
    } catch let error as NSError where error.domain == "Auth" {
        ErrorViewModel.shared.showError(error, file: file, function: function, line: line)
        return nil
    } catch let error as URLError {
        let friendlyError = NSError(
            domain: "Network",
            code: error.code.rawValue,
            userInfo: [NSLocalizedDescriptionKey: "Unable to connect to the server. Please check your internet connection and try again."]
        )
        ErrorViewModel.shared.showError(friendlyError, file: file, function: function, line: line)
        return nil
    } catch {
        ErrorViewModel.shared.showError(error, file: file, function: function, line: line)
        return nil
    }
}

func withErrorHandlingThrowing<T>(
    file: String = #file,
    function: String = #function,
    line: Int = #line,
    operation: () async throws -> T
) async throws -> T {
    do {
        return try await operation()
    } catch {
        ErrorViewModel.shared.showError(error, file: file, function: function, line: line)
        throw error
    }
}
