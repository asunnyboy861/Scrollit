import Foundation
import SwiftData

@Model
final class Post {
    @Attribute(.unique) var id: String
    var title: String
    var author: String
    var subreddit: String
    var score: Int
    var commentCount: Int
    var createdAt: Date
    var body: String?
    var url: String?
    var thumbnailURL: String?
    var imageURL: String?
    var videoURL: String?
    var isVideo: Bool
    var isSelf: Bool
    var isNSFW: Bool
    var isSpoiler: Bool
    var isSaved: Bool
    var isLiked: Bool?
    var flair: String?
    var permalink: String
    var cachedAt: Date
    var isRead: Bool
    var isBookmarked: Bool
    var readAt: Date?

    init(from dict: [String: Any]) {
        self.id = dict["name"] as? String ?? ""
        self.title = dict["title"] as? String ?? ""
        self.author = dict["author"] as? String ?? ""
        self.subreddit = dict["subreddit"] as? String ?? ""
        self.score = dict["score"] as? Int ?? 0
        self.commentCount = dict["num_comments"] as? Int ?? 0
        self.createdAt = Date(timeIntervalSince1970: dict["created_utc"] as? Double ?? 0)
        self.isSelf = dict["is_self"] as? Bool ?? false
        self.isVideo = dict["is_video"] as? Bool ?? false
        self.isNSFW = dict["over_18"] as? Bool ?? false
        self.isSpoiler = dict["spoiler"] as? Bool ?? false
        self.isSaved = dict["saved"] as? Bool ?? false
        self.isLiked = (dict["likes"] as? Bool)
        self.permalink = dict["permalink"] as? String ?? ""
        self.body = dict["selftext"] as? String
        self.url = dict["url"] as? String
        self.flair = dict["link_flair_text"] as? String
        self.cachedAt = Date()
        self.isRead = false
        self.isBookmarked = false
        self.readAt = nil

        if let preview = dict["preview"] as? [String: Any],
           let images = preview["images"] as? [[String: Any]],
           let first = images.first,
           let source = first["source"] as? [String: Any] {
            self.imageURL = (source["url"] as? String)?.replacingOccurrences(of: "&amp;", with: "&")
        }

        if let media = dict["media"] as? [String: Any],
           let redditVideo = media["reddit_video"] as? [String: Any] {
            self.videoURL = redditVideo["hls_url"] as? String
        }

        if let thumbnail = dict["thumbnail"] as? String,
           thumbnail.hasPrefix("http") {
            self.thumbnailURL = thumbnail
        }
    }
}
