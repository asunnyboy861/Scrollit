import Foundation

enum ErrorHandler {
    static func handle(_ error: Error) -> String {
        if let apiError = error as? RedditAPIError {
            return apiError.localizedDescription
        }
        return error.localizedDescription
    }
}
