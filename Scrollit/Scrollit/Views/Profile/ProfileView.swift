import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = ProfileViewModel()
    @State private var showingLogin = false

    var body: some View {
        List {
            if viewModel.isLoggedIn, let profile = viewModel.userProfile {
                loggedInSection(profile)
            } else {
                loggedOutSection
            }

            if viewModel.isLoggedIn {
                accountActionsSection
            }

            settingsSection
        }
        .navigationTitle("Profile")
        .task {
            if viewModel.isLoggedIn {
                await viewModel.loadProfile(modelContext: modelContext)
            }
        }
        .onChange(of: viewModel.isLoggedIn) {
            if viewModel.isLoggedIn {
                Task {
                    await viewModel.loadProfile(modelContext: modelContext)
                }
            }
        }
        .sheet(isPresented: $showingLogin) {
            LoginView()
        }
    }

    private func loggedInSection(_ profile: UserProfile) -> some View {
        Section {
            HStack(spacing: 12) {
                if let avatarURL = profile.avatarURL, let url = URL(string: avatarURL) {
                    AsyncImage(url: url) { phase in
                        if case .success(let image) = phase {
                            image.resizable()
                        } else {
                            Color.orange
                        }
                    }
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.orange)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("u/\(profile.username)")
                        .font(.headline)

                    HStack(spacing: 12) {
                        Label("\(profile.linkKarma)", systemImage: "arrow.up")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Label("\(profile.commentKarma)", systemImage: "text.bubble")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var loggedOutSection: some View {
        Section {
            VStack(spacing: 12) {
                Image(systemName: "person.circle")
                    .font(.system(size: 50))
                    .foregroundStyle(.secondary)

                Text("Not Logged In")
                    .font(.headline)

                Text("Log in to vote, comment, and more")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if SubscriptionManager.shared.isPro {
                    Button("Sign In") {
                        showingLogin = true
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    NavigationLink {
                        SubscriptionView()
                    } label: {
                        Text("Go Pro to Login")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
    }

    private var accountActionsSection: some View {
        Section {
            Button(role: .destructive) {
                viewModel.logout()
            } label: {
                Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
            }
        }
    }

    private var settingsSection: some View {
        Section("Settings") {
            NavigationLink {
                SettingsView()
            } label: {
                Label("Settings", systemImage: "gear")
            }

            NavigationLink {
                SubscriptionView()
            } label: {
                Label("Scrollit Pro", systemImage: "crown.fill")
            }
            .foregroundStyle(.orange)
        }
    }
}
