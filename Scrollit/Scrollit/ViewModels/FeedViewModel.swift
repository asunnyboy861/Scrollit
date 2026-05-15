import SwiftUI
import SwiftData

@Observable
final class FeedViewModel {
    var posts: [Post] = []
    var isLoading = false
    var isLoadingMore = false
    var error: RedditAPIError?
    var currentSort: FeedSort = .hot
    var currentSubreddit: String?
    var afterCursor: String?

    private let api = RedditAPIService.shared
    private let cache = CacheManager.shared
    private let filter = ContentFilterService.shared
    private let auth = AuthService.shared
    private let subscription = SubscriptionManager.shared

    var filteredPosts: [Post] {
        posts.filter { !filter.shouldFilter(post: $0) }
    }

    func loadFeed(subreddit: String? = nil, sort: FeedSort? = nil, modelContext: ModelContext? = nil) async {
        let targetSort = sort ?? currentSort
        let targetSubreddit = subreddit ?? currentSubreddit

        isLoading = true
        error = nil
        currentSort = targetSort
        currentSubreddit = targetSubreddit

        let cacheKey = "feed_\(targetSubreddit ?? "front")_\(targetSort.rawValue)"

        if let cached: [Post] = await cache.getCachedFeed(key: cacheKey) {
            posts = cached
            isLoading = false
            return
        }

        do {
            let token = subscription.isPro ? auth.currentToken : nil
            let result = try await api.getFeed(subreddit: targetSubreddit, sort: targetSort, token: token)
            let newPosts = result.posts.map { Post(from: $0) }

            posts = newPosts
            afterCursor = result.after

            await cache.cacheFeed(posts: newPosts, key: cacheKey)

            if let modelContext {
                markReadPosts(modelContext: modelContext)
            }
        } catch let apiError as RedditAPIError {
            error = apiError
        } catch {
            self.error = RedditAPIError.networkError(error)
        }

        isLoading = false
    }

    func loadMore(modelContext: ModelContext? = nil) async {
        guard !isLoadingMore, let after = afterCursor else { return }
        isLoadingMore = true

        do {
            let token = subscription.isPro ? auth.currentToken : nil
            let result = try await api.getFeed(subreddit: currentSubreddit, sort: currentSort, after: after, token: token)
            let newPosts = result.posts.map { Post(from: $0) }

            posts.append(contentsOf: newPosts)
            afterCursor = result.after

            let cacheKey = "feed_\(currentSubreddit ?? "front")_\(currentSort.rawValue)"
            await cache.cacheFeed(posts: posts, key: cacheKey)
        } catch {
            self.error = RedditAPIError.networkError(error)
        }

        isLoadingMore = false
    }

    func vote(post: Post, direction: Int, modelContext: ModelContext) async {
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

    func toggleSave(post: Post) async {
        guard subscription.isPro else { return }

        if auth.isDemoMode {
            withAnimation(.spring(duration: 0.3)) {
                post.isSaved.toggle()
            }
            return
        }

        guard let token = auth.currentToken else { return }

        let originalSaved = post.isSaved
        post.isSaved = !post.isSaved

        do {
            try await api.savePost(id: post.id, save: post.isSaved, token: token)
        } catch {
            post.isSaved = originalSaved
        }
    }

    func markAsRead(post: Post) {
        post.isRead = true
    }

    private func markReadPosts(modelContext: ModelContext) {
        for post in posts where post.isRead {
            modelContext.insert(post)
        }
        try? modelContext.save()
    }

    func saveScrollPosition(offset: CGFloat) {
        let key = "scroll_\(currentSubreddit ?? "front")_\(currentSort.rawValue)"
        UserDefaults.standard.set(Double(offset), forKey: key)
    }

    func getScrollPosition() -> CGFloat {
        let key = "scroll_\(currentSubreddit ?? "front")_\(currentSort.rawValue)"
        return CGFloat(UserDefaults.standard.double(forKey: key))
    }
}
