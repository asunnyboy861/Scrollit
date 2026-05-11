import Foundation
import SwiftData

@Observable
final class SettingsViewModel {
    var isPro: Bool { SubscriptionManager.shared.isPro }

    let supportURL = "https://asunnyboy861.github.io/Scrollit/support.html"
    let privacyURL = "https://asunnyboy861.github.io/Scrollit/privacy.html"
    let termsURL = "https://asunnyboy861.github.io/Scrollit/terms.html"

    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    func restorePurchases() async {
        await SubscriptionManager.shared.restorePurchases()
    }

    func loadFilterRules(modelContext: ModelContext) {
        ContentFilterService.shared.loadRules(modelContext: modelContext)
    }

    func addFilterRule(keyword: String, subreddit: String?, modelContext: ModelContext) {
        let rule = FilterRule(keyword: keyword, targetSubreddit: subreddit)
        ContentFilterService.shared.addRule(rule, modelContext: modelContext)
    }

    func removeFilterRule(_ rule: FilterRule, modelContext: ModelContext) {
        ContentFilterService.shared.removeRule(rule, modelContext: modelContext)
    }
}
