import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = SettingsViewModel()

    var body: some View {
        List {
            contentSection
            filterSection
            blockedUsersSection
            aboutSection
            legalSection
        }
        .navigationTitle("Settings")
        .task {
            viewModel.loadFilterRules(modelContext: modelContext)
        }
    }

    private var contentSection: some View {
        Section("Content") {
            HStack {
                Label("NSFW Content", systemImage: "eye.slash")
                Spacer()
                Link("Manage on reddit.com", destination: URL(string: "https://www.reddit.com/settings/feed")!)
                    .font(.caption)
                    .foregroundStyle(.blue)
            }

            NavigationLink {
                SubscriptionView()
            } label: {
                HStack {
                    Label("Scrollit Pro", systemImage: "crown.fill")
                        .foregroundStyle(.orange)
                    Spacer()
                    if viewModel.isPro {
                        Text("Active")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
            }

            Button {
                Task { await viewModel.restorePurchases() }
            } label: {
                Label("Restore Purchases", systemImage: "arrow.uturn.down")
            }
        }
    }

    private var filterSection: some View {
        Section("Content Filters") {
            NavigationLink {
                FilterSettingsView()
            } label: {
                Label("Keyword Filters", systemImage: "line.3.horizontal.decrease")
            }
        }
    }

    private var blockedUsersSection: some View {
        Section("Blocked Users") {
            let blocked = ContentFilterService.shared.blockedUsers.sorted()
            if blocked.isEmpty {
                Text("No blocked users")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            } else {
                ForEach(blocked, id: \.self) { username in
                    HStack {
                        Text("u/\(username)")
                            .font(.subheadline)
                        Spacer()
                        Button("Unblock") {
                            ContentFilterService.shared.unblockUser(username)
                        }
                        .font(.caption)
                        .foregroundStyle(.blue)
                    }
                }
            }
        }
    }

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("Version")
                Spacer()
                Text("\(viewModel.appVersion) (\(viewModel.buildNumber))")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var legalSection: some View {
        Section("Legal") {
            Link("Privacy Policy", destination: URL(string: viewModel.privacyURL)!)
            Link("Terms of Use", destination: URL(string: viewModel.termsURL)!)
            Link("Support", destination: URL(string: viewModel.supportURL)!)
            NavigationLink {
                ContactSupportView()
            } label: {
                Label("Contact Us", systemImage: "envelope")
            }
        }
    }
}
