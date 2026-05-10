import Foundation
import SwiftData

@Model
final class UserProfile {
    @Attribute(.unique) var username: String
    var avatarURL: String?
    var linkKarma: Int
    var commentKarma: Int
    var createdAt: Date
    var isActive: Bool

    init(from dict: [String: Any]) {
        self.username = dict["name"] as? String ?? ""
        self.avatarURL = (dict["icon_img"] as? String)?.components(separatedBy: "?").first
        self.linkKarma = dict["link_karma"] as? Int ?? 0
        self.commentKarma = dict["comment_karma"] as? Int ?? 0
        self.createdAt = Date(timeIntervalSince1970: dict["created_utc"] as? Double ?? 0)
        self.isActive = true
    }
}
