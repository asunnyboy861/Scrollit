import Foundation

actor CacheManager {
    static let shared = CacheManager()

    private let cache = NSCache<NSString, CacheEntry>()

    private let feedTTL: TimeInterval = 300
    private let postTTL: TimeInterval = 1800
    private let commentTTL: TimeInterval = 600
    private let searchTTL: TimeInterval = 300

    private init() {}

    func cacheFeed(posts: [Post], key: String) {
        let entry = CacheEntry(data: posts, expiration: Date().addingTimeInterval(feedTTL))
        cache.setObject(entry, forKey: key as NSString)
    }

    func getCachedFeed(key: String) -> [Post]? {
        guard let entry = cache.object(forKey: key as NSString),
              entry.expiration > Date() else {
            return nil
        }
        return entry.data as? [Post]
    }

    func cachePost(_ post: Post) {
        let entry = CacheEntry(data: post, expiration: Date().addingTimeInterval(postTTL))
        cache.setObject(entry, forKey: "post_\(post.id)" as NSString)
    }

    func getCachedPost(id: String) -> Post? {
        guard let entry = cache.object(forKey: "post_\(id)" as NSString),
              entry.expiration > Date() else {
            return nil
        }
        return entry.data as? Post
    }

    func cacheSearchResults(results: Any, query: String) {
        let entry = CacheEntry(data: results, expiration: Date().addingTimeInterval(searchTTL))
        cache.setObject(entry, forKey: "search_\(query)" as NSString)
    }

    func getCachedSearchResults(query: String) -> Any? {
        guard let entry = cache.object(forKey: "search_\(query)" as NSString),
              entry.expiration > Date() else {
            return nil
        }
        return entry.data
    }

    func invalidateAll() {
        cache.removeAllObjects()
    }
}

final class CacheEntry {
    let data: Any
    let expiration: Date

    init(data: Any, expiration: Date) {
        self.data = data
        self.expiration = expiration
    }
}
