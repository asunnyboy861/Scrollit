import Foundation
import SwiftData

@Model
final class Subreddit {
    @Attribute(.unique) var name: String
    var displayName: String
    var subscriberCount: Int
    var subredditDescription: String?
    var iconURL: String?
    var bannerURL: String?
    var isSubscribed: Bool
    var isLocal: Bool
    var over18: Bool

    init(from dict: [String: Any]) {
        self.name = dict["name"] as? String ?? ""
        self.displayName = dict["display_name"] as? String ?? ""
        self.subscriberCount = dict["subscribers"] as? Int ?? 0
        self.subredditDescription = dict["public_description"] as? String
        self.iconURL = (dict["icon_img"] as? String)?.components(separatedBy: "?").first
        self.bannerURL = (dict["banner_img"] as? String)?.components(separatedBy: "?").first
        self.isSubscribed = dict["user_is_subscriber"] as? Bool ?? false
        self.isLocal = false
        self.over18 = dict["over18"] as? Bool ?? false
    }

    init(localName: String) {
        self.name = localName
        self.displayName = localName
        self.subscriberCount = 0
        self.isSubscribed = true
        self.isLocal = true
        self.over18 = false
    }
}
