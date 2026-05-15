import Foundation
import SwiftUI

@Observable
final class PostDetailViewModel {
    var post: Post?
    var comments: [CommentItem] = []
    var isLoading = false
    var error: RedditAPIError?
    var commentSort: CommentSort = .best

    private let api = RedditAPIService.shared
    private let cache = CacheManager.shared
    private let auth = AuthService.shared
    private let subscription = SubscriptionManager.shared

    func loadPost(id: String, subreddit: String) async {
        isLoading = true
        error = nil

        if let cached = await cache.getCachedPost(id: id) {
            post = cached
        }

        do {
            let token = subscription.isPro ? auth.currentToken : nil
            let result = try await api.getPost(id: id, token: token)

            let loadedPost = Post(from: result.post)
            if post == nil { post = loadedPost }
            await cache.cachePost(loadedPost)

            comments = parseCommentTree(result.comments, postId: id)
        } catch let apiError as RedditAPIError {
            error = apiError
        } catch {
            self.error = RedditAPIError.networkError(error)
        }

        isLoading = false
    }

    func vote(post: Post, direction: Int) async {
        guard subscription.isPro else { return }

        if auth.isDemoMode {
            withAnimation(.spring(duration: 0.3)) {
                let originalLiked = post.isLiked
                post.isLiked = direction == 1 ? true : (direction == -1 ? false : nil)
                post.score += (direction == 1 ? 1 : (direction == -1 ? -1 : (originalLiked == true ? -1 : (originalLiked == false ? 1 : 0))))
            }
            return
        }

        guard let token = auth.currentToken else { return }

        let originalLiked = post.isLiked
        let originalScore = post.score

        withAnimation(.spring(duration: 0.3)) {
            post.isLiked = direction == 1 ? true : (direction == -1 ? false : nil)
            post.score = originalScore + (direction == 1 ? 1 : (direction == -1 ? -1 : (originalLiked == true ? -1 : (originalLiked == false ? 1 : 0))))
        }

        do {
            try await api.vote(id: post.id, direction: direction, token: token)
        } catch {
            withAnimation(.spring(duration: 0.3)) {
                post.isLiked = originalLiked
                post.score = originalScore
            }
        }
    }

    func voteCommentById(_ commentId: String, direction: Int) {
        guard subscription.isPro else { return }
        guard let index = comments.firstIndex(where: { $0.id == commentId }) else { return }
        let originalLiked = comments[index].isLiked
        let originalScore = comments[index].score

        comments[index].isLiked = direction == 1 ? true : (direction == -1 ? false : nil)
        comments[index].score = originalScore + (direction == 1 ? 1 : (direction == -1 ? -1 : (originalLiked == true ? -1 : (originalLiked == false ? 1 : 0))))

        if auth.isDemoMode { return }

        Task {
            do {
                try await api.vote(id: "t1_\(commentId)", direction: direction, token: auth.currentToken ?? "")
            } catch {
                comments[index].isLiked = originalLiked
                comments[index].score = originalScore
            }
        }
    }

    func reply(to parentId: String, text: String) async {
        guard subscription.isPro else { return }

        if auth.isDemoMode {
            let newComment = CommentItem(
                id: UUID().uuidString,
                author: "Demo User",
                body: text,
                score: 1,
                createdAt: Date(),
                depth: 0,
                isLiked: true,
                parentId: parentId,
                replies: []
            )
            comments.insert(newComment, at: 0)
            return
        }

        guard let token = auth.currentToken else { return }

        do {
            let result = try await api.submitComment(parentId: parentId, text: text, token: token)

            if let data = result as? [String: Any],
               let commentData = data["data"] as? [String: Any] {
                let newComment = CommentItem(
                    id: commentData["id"] as? String ?? UUID().uuidString,
                    author: commentData["author"] as? String ?? "",
                    body: commentData["body"] as? String ?? "",
                    score: commentData["score"] as? Int ?? 1,
                    createdAt: Date(timeIntervalSince1970: commentData["created_utc"] as? Double ?? 0),
                    depth: 0,
                    isLiked: nil,
                    parentId: parentId,
                    replies: []
                )
                comments.insert(newComment, at: 0)
            }
        } catch {
            self.error = RedditAPIError.networkError(error)
        }
    }

    private func parseCommentTree(_ rawComments: [[String: Any]], postId: String, depth: Int = 0) -> [CommentItem] {
        guard depth < 4 else { return [] }

        return rawComments.compactMap { dict -> CommentItem? in
            let id = dict["id"] as? String ?? ""
            let author = dict["author"] as? String ?? ""
            let body = dict["body"] as? String ?? ""
            let score = dict["score"] as? Int ?? 0
            let createdAt = Date(timeIntervalSince1970: dict["created_utc"] as? Double ?? 0)
            let isLiked = dict["likes"] as? Bool
            let parentId = dict["parent_id"] as? String ?? ""

            var replies: [CommentItem] = []
            if let repliesData = dict["replies"] as? [String: Any],
               let repliesListing = repliesData["data"] as? [String: Any],
               let repliesChildren = repliesListing["children"] as? [[String: Any]] {
                let replyDicts = repliesChildren.compactMap { $0["data"] as? [String: Any] }
                replies = parseCommentTree(replyDicts, postId: postId, depth: depth + 1)
            }

            return CommentItem(
                id: id,
                author: author,
                body: body,
                score: score,
                createdAt: createdAt,
                depth: depth,
                isLiked: isLiked,
                parentId: parentId,
                replies: replies
            )
        }
    }
}

struct CommentItem: Identifiable {
    let id: String
    let author: String
    let body: String
    var score: Int
    let createdAt: Date
    let depth: Int
    var isLiked: Bool?
    let parentId: String
    var replies: [CommentItem]
    var isCollapsed = false
}
