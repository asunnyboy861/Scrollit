import Foundation
import SwiftData

@Model
final class FilterRule {
    var keyword: String
    var targetSubreddit: String?
    var isNSFWFilter: Bool
    var isEnabled: Bool
    var createdAt: Date

    init(keyword: String, targetSubreddit: String? = nil, isNSFWFilter: Bool = false) {
        self.keyword = keyword
        self.targetSubreddit = targetSubreddit
        self.isNSFWFilter = isNSFWFilter
        self.isEnabled = true
        self.createdAt = Date()
    }
}
