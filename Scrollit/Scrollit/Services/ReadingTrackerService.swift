import Foundation
import SwiftData

@MainActor
@Observable
final class ReadingTrackerService {
    static let shared = ReadingTrackerService()

    private let defaults = UserDefaults.standard

    private init() {}

    func markAsRead(post: Post) {
        guard !post.isRead else { return }
        post.isRead = true
        post.readAt = Date()
        incrementDailyCount()
    }

    func toggleBookmark(post: Post) {
        post.isBookmarked.toggle()
        if post.isBookmarked {
            HapticManager.success()
        }
    }

    func getHistoryPosts(modelContext: ModelContext) -> [Post] {
        let descriptor = FetchDescriptor<Post>(
            predicate: #Predicate { $0.isRead },
            sortBy: [SortDescriptor(\Post.readAt, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func getBookmarkedPosts(modelContext: ModelContext) -> [Post] {
        let descriptor = FetchDescriptor<Post>(
            predicate: #Predicate { $0.isBookmarked },
            sortBy: [SortDescriptor(\Post.cachedAt, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func getPostsReadToday() -> Int {
        let key = todayKey()
        return defaults.integer(forKey: key)
    }

    func getPostsReadThisWeek() -> Int {
        var total = 0
        let calendar = Calendar.current
        let today = Date()
        for i in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { continue }
            let key = dateKey(for: date)
            total += defaults.integer(forKey: key)
        }
        return total
    }

    func getTotalPostsRead() -> Int {
        defaults.integer(forKey: "total_posts_read")
    }

    func getReadingStreak() -> Int {
        let calendar = Calendar.current
        var streak = 0
        let today = Date()

        for i in 0..<365 {
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { break }
            let key = dateKey(for: date)
            let count = defaults.integer(forKey: key)
            if count > 0 {
                streak += 1
            } else if i > 0 {
                break
            }
        }

        return streak
    }

    func getTopSubreddits(modelContext: ModelContext) -> [(String, Int)] {
        let posts = getHistoryPosts(modelContext: modelContext)
        var counts: [String: Int] = [:]
        for post in posts {
            counts[post.subreddit, default: 0] += 1
        }
        return counts.sorted { $0.value > $1.value }.prefix(10).map { ($0.key, $0.value) }
    }

    func getHistoryGrouped(modelContext: ModelContext) -> [(String, [Post])] {
        let posts = getHistoryPosts(modelContext: modelContext)
        let calendar = Calendar.current
        let today = Date()

        var groups: [(String, [Post])] = []
        var todayPosts: [Post] = []
        var yesterdayPosts: [Post] = []
        var thisWeekPosts: [Post] = []
        var earlierPosts: [Post] = []

        for post in posts {
            guard let readAt = post.readAt else { continue }
            if calendar.isDateInToday(readAt) {
                todayPosts.append(post)
            } else if calendar.isDateInYesterday(readAt) {
                yesterdayPosts.append(post)
            } else if calendar.isDate(readAt, equalTo: today, toGranularity: .weekOfYear) {
                thisWeekPosts.append(post)
            } else {
                earlierPosts.append(post)
            }
        }

        if !todayPosts.isEmpty { groups.append(("Today", todayPosts)) }
        if !yesterdayPosts.isEmpty { groups.append(("Yesterday", yesterdayPosts)) }
        if !thisWeekPosts.isEmpty { groups.append(("This Week", thisWeekPosts)) }
        if !earlierPosts.isEmpty { groups.append(("Earlier", earlierPosts)) }

        return groups
    }

    func clearHistory(modelContext: ModelContext) {
        let posts = getHistoryPosts(modelContext: modelContext)
        for post in posts {
            post.isRead = false
            post.readAt = nil
        }
        try? modelContext.save()
    }

    private func incrementDailyCount() {
        let key = todayKey()
        let current = defaults.integer(forKey: key)
        defaults.set(current + 1, forKey: key)

        let total = defaults.integer(forKey: "total_posts_read")
        defaults.set(total + 1, forKey: "total_posts_read")
    }

    private func todayKey() -> String {
        dateKey(for: Date())
    }

    private func dateKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return "posts_read_\(formatter.string(from: date))"
    }
}
