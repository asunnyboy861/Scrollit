import Foundation
import SwiftData

@Observable
final class ContentFilterService {
    static let shared = ContentFilterService()

    var filterRules: [FilterRule] = []
    var hideNSFW = false

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

    func shouldFilter(post: Post) -> Bool {
        if hideNSFW && post.isNSFW { return true }

        for rule in filterRules where rule.isEnabled {
            if let target = rule.targetSubreddit, target != post.subreddit { continue }
            if post.title.localizedCaseInsensitiveContains(rule.keyword) { return true }
            if let body = post.body, body.localizedCaseInsensitiveContains(rule.keyword) { return true }
        }

        return false
    }
}
