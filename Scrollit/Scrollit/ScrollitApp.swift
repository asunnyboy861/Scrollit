import SwiftUI
import SwiftData

@main
struct ScrollitApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(for: [Post.self, Comment.self, Subreddit.self, UserProfile.self, FilterRule.self])
    }
}
