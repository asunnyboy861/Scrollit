import Foundation
import SwiftData

@Model
final class Comment {
    @Attribute(.unique) var id: String
    var postId: String
    var author: String
    var body: String
    var score: Int
    var createdAt: Date
    var depth: Int
    var isLiked: Bool?
    var parentId: String
    var permalink: String
    var cachedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Comment.parent)
    var replies: [Comment] = []

    var parent: Comment?

    init(from dict: [String: Any], postId: String, depth: Int = 0) {
        self.id = dict["id"] as? String ?? UUID().uuidString
        self.postId = postId
        self.author = dict["author"] as? String ?? ""
        self.body = dict["body"] as? String ?? ""
        self.score = dict["score"] as? Int ?? 0
        self.createdAt = Date(timeIntervalSince1970: dict["created_utc"] as? Double ?? 0)
        self.depth = depth
        self.isLiked = (dict["likes"] as? Bool)
        self.parentId = dict["parent_id"] as? String ?? ""
        self.permalink = dict["permalink"] as? String ?? ""
        self.cachedAt = Date()
    }
}
