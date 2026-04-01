import SwiftUI

@Observable
class ErrorViewModel {
    var currentError: AppError?
    var isShowingError = false
    
    static let shared = ErrorViewModel()
    
    private init() {}
    
    func showError(_ error: Error, file: String = #file, function: String = #function, line: Int = #line) {
        let appError = AppError(
            underlyingError: error,
            file: file,
            function: function,
            line: line
        )
        currentError = appError
        isShowingError = true
    }
    
    func showError(message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let appError = AppError(
            message: message,
            file: file,
            function: function,
            line: line
        )
        currentError = appError
        isShowingError = true
    }
    
    func dismissError() {
        isShowingError = false
        currentError = nil
    }
}

struct AppError: Identifiable {
    let id = UUID()
    let message: String
    let detailedDescription: String
    let file: String
    let function: String
    let line: Int
    let timestamp: Date
    
    init(underlyingError: Error, file: String, function: String, line: Int) {
        self.message = underlyingError.localizedDescription
        self.detailedDescription = String(describing: underlyingError)
        self.file = (file as NSString).lastPathComponent
        self.function = function
        self.line = line
        self.timestamp = Date()
    }
    
    init(message: String, file: String, function: String, line: Int) {
        self.message = message
        self.detailedDescription = message
        self.file = (file as NSString).lastPathComponent
        self.function = function
        self.line = line
        self.timestamp = Date()
    }
    
    var locationString: String {
        "\(file):\(line) in \(function)"
    }
    
    var timestampString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: timestamp)
    }
}
