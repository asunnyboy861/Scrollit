import Foundation
import SwiftData

@Observable
final class ProfileViewModel {
    var userProfile: UserProfile?
    var isLoading = false
    var error: Error?

    private let api = RedditAPIService.shared
    private let auth = AuthService.shared
    private let subscription = SubscriptionManager.shared

    var isLoggedIn: Bool { auth.isLoggedIn }
    var isPro: Bool { subscription.isPro }

    func loadProfile(modelContext: ModelContext) async {
        guard auth.isLoggedIn, let token = auth.currentToken else { return }

        isLoading = true
        error = nil

        do {
            let userData = try await api.getUserInfo(token: token)
            let profile = UserProfile(from: userData)

            let targetUsername = profile.username
            let descriptor = FetchDescriptor<UserProfile>(predicate: #Predicate<UserProfile> { $0.username == targetUsername })
            let existing = try modelContext.fetch(descriptor)
            for old in existing {
                modelContext.delete(old)
            }

            modelContext.insert(profile)
            try modelContext.save()
            userProfile = profile
        } catch {
            self.error = error
        }

        isLoading = false
    }

    func login() async throws {
        _ = try await auth.login()
    }

    func logout() {
        auth.logout()
        userProfile = nil
    }
}
