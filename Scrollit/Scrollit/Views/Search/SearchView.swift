import SwiftUI
import SwiftData

struct SearchView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = SearchViewModel()
    @State private var searchDebounceTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 0) {
            searchField

            if viewModel.isSearching {
                LoadingView(message: "Searching...")
            } else if viewModel.searchQuery.isEmpty {
                EmptyStateView(
                    icon: "magnifyingglass",
                    title: "Search Reddit",
                    subtitle: "Find subreddits and posts"
                )
            } else if viewModel.subreddits.isEmpty && viewModel.posts.isEmpty {
                EmptyStateView(
                    icon: "questionmark.circle",
                    title: "No Results",
                    subtitle: "Try a different search term"
                )
            } else {
                searchResults
            }
        }
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search Reddit", text: $viewModel.searchQuery)
                .textFieldStyle(.plain)
                .onSubmit {
                    Task { await viewModel.search() }
                }

            if !viewModel.searchQuery.isEmpty {
                Button {
                    viewModel.searchQuery = ""
                    viewModel.subreddits = []
                    viewModel.posts = []
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(10)
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private var searchResults: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                if !viewModel.subreddits.isEmpty {
                    sectionHeader("Communities")

                    ForEach(viewModel.subreddits) { subreddit in
                        NavigationLink {
                            FeedView(initialSubreddit: subreddit.displayName)
                        } label: {
                            subredditRow(subreddit)
                        }
                        .buttonStyle(.plain)

                        Divider().padding(.leading, 60)
                    }
                }

                if !viewModel.posts.isEmpty {
                    sectionHeader("Posts")

                    ForEach(viewModel.posts, id: \.id) { post in
                        NavigationLink(value: post) {
                            PostRowView(post: post)
                        }
                        .buttonStyle(.plain)

                        Divider().padding(.leading, 16)
                    }
                }
            }
        }
        .navigationDestination(for: Post.self) { post in
            PostDetailView(post: post)
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.footnote)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 4)
    }

    private func subredditRow(_ subreddit: Subreddit) -> some View {
        HStack(spacing: 12) {
            if let iconURL = subreddit.iconURL, let url = URL(string: iconURL) {
                AsyncImage(url: url) { phase in
                    if case .success(let image) = phase {
                        image.resizable()
                    } else {
                        Color.blue
                    }
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            } else {
                Image(systemName: "person.3.fill")
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.blue, in: Circle())
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("r/\(subreddit.displayName)")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text("\(formatNumber(subreddit.subscriberCount)) members")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private func formatNumber(_ n: Int) -> String {
        if n >= 1_000_000 { return "\(n / 1_000_000)M" }
        if n >= 1_000 { return "\(n / 1_000)K" }
        return "\(n)"
    }
}
