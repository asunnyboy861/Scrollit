import Foundation

enum FeedSort: String, CaseIterable {
    case hot = "hot"
    case new = "new"
    case top = "top"
    case rising = "rising"

    var iconName: String {
        switch self {
        case .hot: return "flame.fill"
        case .new: return "clock.fill"
        case .top: return "chart.bar.fill"
        case .rising: return "arrow.up.right"
        }
    }

    var displayName: String {
        switch self {
        case .hot: return "Hot"
        case .new: return "New"
        case .top: return "Top"
        case .rising: return "Rising"
        }
    }
}

enum CommentSort: String, CaseIterable {
    case best = "best"
    case top = "top"
    case new = "new"
    case controversial = "controversial"
    case old = "old"

    var displayName: String {
        switch self {
        case .best: return "Best"
        case .top: return "Top"
        case .new: return "New"
        case .controversial: return "Controversial"
        case .old: return "Old"
        }
    }
}

enum RedditAPIError: LocalizedError {
    case networkError(Error)
    case invalidResponse
    case rateLimited
    case unauthorized
    case decodingError
    case serverError(Int)

    var errorDescription: String? {
        switch self {
        case .networkError(let error): return error.localizedDescription
        case .invalidResponse: return "Invalid response from server"
        case .rateLimited: return "Too many requests. Please wait a moment."
        case .unauthorized: return "Please log in to continue"
        case .decodingError: return "Failed to parse response"
        case .serverError(let code): return "Server error (\(code))"
        }
    }
}

actor RedditAPIService {
    static let shared = RedditAPIService()

    private let publicBaseURL = "https://www.reddit.com"
    private let oauthBaseURL = "https://oauth.reddit.com"
    private let session: URLSession
    private let rateLimiter = RateLimiter()

    private init() {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.timeoutIntervalForRequest = 30
        config.httpAdditionalHeaders = ["User-Agent": "ios:com.zzoutuo.Scrollit:v1.0 (by /u/scrollit_app)"]
        self.session = URLSession(configuration: config)
    }

    private func baseURL(isAuthenticated: Bool) -> String {
        isAuthenticated ? oauthBaseURL : publicBaseURL
    }

    private func makeRequest(url: URL, token: String? = nil) -> URLRequest {
        var request = URLRequest(url: url)
        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }

    func getFeed(subreddit: String? = nil, sort: FeedSort = .hot, after: String? = nil, token: String? = nil) async throws -> (posts: [[String: Any]], after: String?) {
        try await rateLimiter.wait()

        var path = subreddit != nil ? "/r/\(subreddit!)/\(sort.rawValue).json" : "/\(sort.rawValue).json"
        var components = URLComponents(string: baseURL(isAuthenticated: token != nil) + path)
        var queryItems: [URLQueryItem] = [URLQueryItem(name: "limit", value: "25")]
        if let after { queryItems.append(URLQueryItem(name: "after", value: after)) }
        components?.queryItems = queryItems

        guard let url = components?.url else { throw RedditAPIError.invalidResponse }
        let request = makeRequest(url: url, token: token)
        let data = try await performRequest(request)

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let listing = json["data"] as? [String: Any],
              let children = listing["children"] as? [[String: Any]] else {
            throw RedditAPIError.decodingError
        }

        let posts = children.compactMap { child -> [String: Any]? in
            guard child["kind"] as? String == "t3" else { return nil }
            return child["data"] as? [String: Any]
        }

        return (posts, listing["after"] as? String)
    }

    func getPost(id: String, token: String? = nil) async throws -> (post: [String: Any], comments: [[String: Any]]) {
        try await rateLimiter.wait()

        let path = "/comments/\(id).json"
        let url = URL(string: baseURL(isAuthenticated: token != nil) + path)!
        let request = makeRequest(url: url, token: token)
        let data = try await performRequest(request)

        guard let array = try JSONSerialization.jsonObject(with: data) as? [[String: Any]],
              array.count >= 2 else {
            throw RedditAPIError.decodingError
        }

        let postData = array[0]
        let commentData = array[1]

        guard let postListing = postData["data"] as? [String: Any],
              let postChildren = postListing["children"] as? [[String: Any]],
              let firstPost = postChildren.first?["data"] as? [String: Any] else {
            throw RedditAPIError.decodingError
        }

        guard let commentListing = commentData["data"] as? [String: Any],
              let commentChildren = commentListing["children"] as? [[String: Any]] else {
            return (firstPost, [])
        }

        let comments = commentChildren.compactMap { child -> [String: Any]? in
            guard child["kind"] as? String == "t1" else { return nil }
            return child["data"] as? [String: Any]
        }

        return (firstPost, comments)
    }

    func search(query: String, type: String = "sr,link", token: String? = nil) async throws -> (subreddits: [[String: Any]], posts: [[String: Any]]) {
        try await rateLimiter.wait()

        var components = URLComponents(string: baseURL(isAuthenticated: token != nil) + "/search.json")
        components?.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "type", value: type),
            URLQueryItem(name: "limit", value: "25")
        ]

        guard let url = components?.url else { throw RedditAPIError.invalidResponse }
        let request = makeRequest(url: url, token: token)
        let data = try await performRequest(request)

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let listing = json["data"] as? [String: Any],
              let children = listing["children"] as? [[String: Any]] else {
            throw RedditAPIError.decodingError
        }

        var subreddits: [[String: Any]] = []
        var posts: [[String: Any]] = []

        for child in children {
            if child["kind"] as? String == "t5",
               let data = child["data"] as? [String: Any] {
                subreddits.append(data)
            } else if child["kind"] as? String == "t3",
                      let data = child["data"] as? [String: Any] {
                posts.append(data)
            }
        }

        return (subreddits, posts)
    }

    func vote(id: String, direction: Int, token: String) async throws {
        try await rateLimiter.wait()

        let url = URL(string: oauthBaseURL + "/api/vote")!
        var request = makeRequest(url: url, token: token)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = "id=\(id)&dir=\(direction)"
        request.httpBody = body.data(using: .utf8)

        _ = try await performRequest(request)
    }

    func savePost(id: String, save: Bool, token: String) async throws {
        try await rateLimiter.wait()

        let endpoint = save ? "/api/save" : "/api/unsave"
        let url = URL(string: oauthBaseURL + endpoint)!
        var request = makeRequest(url: url, token: token)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = "id=\(id)"
        request.httpBody = body.data(using: .utf8)

        _ = try await performRequest(request)
    }

    func submitComment(parentId: String, text: String, token: String) async throws -> [String: Any] {
        try await rateLimiter.wait()

        let url = URL(string: oauthBaseURL + "/api/comment")!
        var request = makeRequest(url: url, token: token)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = "parent=\(parentId)&text=\(text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? text)"
        request.httpBody = body.data(using: .utf8)

        let data = try await performRequest(request)

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw RedditAPIError.decodingError
        }

        return json
    }

    func getSubredditInfo(name: String, token: String? = nil) async throws -> [String: Any] {
        try await rateLimiter.wait()

        let url = URL(string: baseURL(isAuthenticated: token != nil) + "/r/\(name)/about.json")!
        let request = makeRequest(url: url, token: token)
        let data = try await performRequest(request)

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let subData = json["data"] as? [String: Any] else {
            throw RedditAPIError.decodingError
        }

        return subData
    }

    func getUserInfo(token: String) async throws -> [String: Any] {
        try await rateLimiter.wait()

        let url = URL(string: oauthBaseURL + "/api/v1/me")!
        let request = makeRequest(url: url, token: token)
        let data = try await performRequest(request)

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw RedditAPIError.decodingError
        }

        return json
    }

    private func performRequest(_ request: URLRequest) async throws -> Data {
        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw RedditAPIError.invalidResponse
            }

            switch httpResponse.statusCode {
            case 200...299:
                return data
            case 401:
                throw RedditAPIError.unauthorized
            case 429:
                throw RedditAPIError.rateLimited
            case 500...599:
                throw RedditAPIError.serverError(httpResponse.statusCode)
            default:
                throw RedditAPIError.invalidResponse
            }
        } catch let error as RedditAPIError {
            throw error
        } catch {
            throw RedditAPIError.networkError(error)
        }
    }
}

extension String {
    var urlEncoded: String {
        addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? self
    }
}
