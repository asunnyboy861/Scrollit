import Foundation
import SwiftData

@Observable
final class ContentFilterService {
    static let shared = ContentFilterService()

    var filterRules: [FilterRule] = []
    var blockedUsers: Set<String> {
        get {
            let users = UserDefaults.standard.stringArray(forKey: "blocked_users") ?? []
            return Set(users)
        }
        set {
            UserDefaults.standard.set(Array(newValue), forKey: "blocked_users")
        }
    }

    private init() {}

    func loadRules(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<FilterRule>(sortBy: [SortDescriptor(\.createdAt)])
        filterRules = (try? modelContext.fetch(descriptor)) ?? []
    }

    func addRule(_ rule: FilterRule, modelContext: ModelContext) {
        modelContext.insert(rule)
        try? modelContext.save()
        filterRules.append(rule)
    }

    func removeRule(_ rule: FilterRule, modelContext: ModelContext) {
        modelContext.delete(rule)
        try? modelContext.save()
        filterRules.removeAll { $0.keyword == rule.keyword && $0.targetSubreddit == rule.targetSubreddit }
    }

    func blockUser(_ username: String) {
        var users = blockedUsers
        users.insert(username)
        blockedUsers = users
    }

    func unblockUser(_ username: String) {
        var users = blockedUsers
        users.remove(username)
        blockedUsers = users
    }

    func isUserBlocked(_ username: String) -> Bool {
        blockedUsers.contains(username)
    }

    func shouldFilter(post: Post) -> Bool {
        if !AuthService.shared.isLoggedIn && post.isNSFW {
            return true
        }

        if isUserBlocked(post.author) {
            return true
        }

        for rule in filterRules where rule.isEnabled {
            if let target = rule.targetSubreddit, target != post.subreddit {
                continue
            }
            if post.title.localizedCaseInsensitiveContains(rule.keyword) {
                return true
            }
            if let body = post.body, body.localizedCaseInsensitiveContains(rule.keyword) {
                return true
            }
        }

        return false
    }

    func reportContent(postId: String, author: String, reason: String) {
        let report = ContentReport(
            postId: postId,
            author: author,
            reason: reason,
            timestamp: Date()
        )
        var reports = getAllReports()
        reports.append(report)
        saveReports(reports)
    }

    func getAllReports() -> [ContentReport] {
        let data = UserDefaults.standard.data(forKey: "content_reports")
        guard let data else { return [] }
        return (try? JSONDecoder().decode([ContentReport].self, from: data)) ?? []
    }

    func saveReports(_ reports: [ContentReport]) {
        let data = try? JSONEncoder().encode(reports)
        UserDefaults.standard.set(data, forKey: "content_reports")
    }
}

struct ContentReport: Codable {
    let postId: String
    let author: String
    let reason: String
    let timestamp: Date
}
