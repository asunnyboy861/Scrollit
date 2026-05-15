import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = ProfileViewModel()
    @State private var showingLogin = false

    var body: some View {
        List {
            if viewModel.isLoggedIn {
                if AuthService.shared.isDemoMode {
                    demoBanner
                }

                if let profile = viewModel.userProfile {
                    loggedInSection(profile)
                } else if AuthService.shared.isDemoMode {
                    demoProfileSection
                }

                accountActionsSection
            } else {
                loggedOutSection
            }

            settingsSection
        }
        .navigationTitle("Profile")
        .task {
            if viewModel.isLoggedIn && !AuthService.shared.isDemoMode {
                await viewModel.loadProfile(modelContext: modelContext)
            }
        }
        .onChange(of: viewModel.isLoggedIn) {
            if viewModel.isLoggedIn && !AuthService.shared.isDemoMode {
                Task {
                    await viewModel.loadProfile(modelContext: modelContext)
                }
            }
        }
        .sheet(isPresented: $showingLogin) {
            LoginView()
        }
    }

    private var demoBanner: some View {
        Section {
            VStack(spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: "play.circle.fill")
                        .foregroundStyle(.blue)
                    Text("Demo Mode")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.blue)
                    Spacer()
                    if let remaining = AuthService.shared.demoTimeRemaining {
                        Text(remaining)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Text("Subscribe to keep all Pro features after demo expires")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 4)
        }
    }

    private var demoProfileSection: some View {
        Section {
            HStack(spacing: 12) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.blue)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Demo User")
                        .font(.headline)

                    HStack(spacing: 12) {
                        Label("1,234", systemImage: "arrow.up")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Label("567", systemImage: "text.bubble")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.vertical, 4)
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
                Label(AuthService.shared.isDemoMode ? "Exit Demo Mode" : "Log Out", systemImage: "rectangle.portrait.and.arrow.right")
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
