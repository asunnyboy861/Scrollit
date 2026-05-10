import Foundation

@Observable
final class SearchViewModel {
    var searchQuery = ""
    var subreddits: [Subreddit] = []
    var posts: [Post] = []
    var isSearching = false
    var error: RedditAPIError?

    private let api = RedditAPIService.shared
    private let auth = AuthService.shared
    private let subscription = SubscriptionManager.shared

    func search() async {
        let query = searchQuery.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else {
            subreddits = []
            posts = []
            return
        }

        isSearching = true
        error = nil

        do {
            let token = subscription.isPro ? auth.currentToken : nil
            let result = try await api.search(query: query, token: token)

            subreddits = result.subreddits.map { Subreddit(from: $0) }
            posts = result.posts.map { Post(from: $0) }
        } catch let apiError as RedditAPIError {
            error = apiError
        } catch {
            self.error = RedditAPIError.networkError(error)
        }

        isSearching = false
    }
}
