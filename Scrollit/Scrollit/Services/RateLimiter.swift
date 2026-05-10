import Foundation

actor RateLimiter {
    private var lastRequestTime: Date = .distantPast
    private let minimumInterval: TimeInterval = 0.5

    func wait() async throws {
        let now = Date()
        let elapsed = now.timeIntervalSince(lastRequestTime)
        let remaining = minimumInterval - elapsed

        if remaining > 0 {
            try await Task.sleep(for: .seconds(remaining))
        }

        lastRequestTime = Date()
    }
}
