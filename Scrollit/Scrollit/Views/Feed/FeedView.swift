import SwiftUI
import SwiftData

struct FeedView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = FeedViewModel()
    var initialSubreddit: String? = nil

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.posts.isEmpty {
                LoadingView(message: "Loading feed...")
            } else if let error = viewModel.error, viewModel.posts.isEmpty {
                ErrorView(error: error.localizedDescription) {
                    Task { await viewModel.loadFeed(subreddit: initialSubreddit, modelContext: modelContext) }
                }
            } else if viewModel.filteredPosts.isEmpty {
                EmptyStateView(
                    icon: "doc.text.magnifyingglass",
                    title: "No Posts",
                    subtitle: "Pull to refresh or try a different sort"
                )
            } else {
                postList
            }
        }
        .navigationTitle(viewModel.currentSubreddit != nil ? "r/\(viewModel.currentSubreddit!)" : "Scrollit")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    ForEach(FeedSort.allCases, id: \.self) { sort in
                        Button {
                            HapticManager.selection()
                            Task { await viewModel.loadFeed(subreddit: viewModel.currentSubreddit ?? initialSubreddit, sort: sort, modelContext: modelContext) }
                        } label: {
                            Label(sort.displayName, systemImage: sort.iconName)
                        }
                    }
                } label: {
                    Image(systemName: viewModel.currentSort.iconName)
                }
            }
        }
        .refreshable {
            HapticManager.light()
            await viewModel.loadFeed(subreddit: viewModel.currentSubreddit ?? initialSubreddit, modelContext: modelContext)
        }
        .task {
            if viewModel.posts.isEmpty {
                await viewModel.loadFeed(subreddit: initialSubreddit, modelContext: modelContext)
            }
        }
    }

    private var postList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.filteredPosts, id: \.id) { post in
                    NavigationLink(value: post) {
                        PostRowView(post: post)
                    }
                    .buttonStyle(.plain)
                    .contextMenu { postContextMenu(post) }
                    .onAppear {
                        if post.id == viewModel.filteredPosts.last?.id {
                            Task { await viewModel.loadMore(modelContext: modelContext) }
                        }
                        ReadingTrackerService.shared.markAsRead(post: post)
                    }

                    Divider()
                        .padding(.leading, 16)
                }

                if viewModel.isLoadingMore {
                    ProgressView()
                        .padding()
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationDestination(for: Post.self) { post in
            PostDetailView(post: post)
        }
    }

    @ViewBuilder
    private func postContextMenu(_ post: Post) -> some View {
        Button {
            ReadingTrackerService.shared.toggleBookmark(post: post)
        } label: {
            Label(post.isBookmarked ? "Remove Bookmark" : "Bookmark", systemImage: post.isBookmarked ? "bookmark.slash" : "bookmark")
        }

        ShareLink(item: URL(string: "https://reddit.com\(post.permalink)")!) {
            Label("Share", systemImage: "square.and.arrow.up")
        }

        Button {
            Task { await viewModel.vote(post: post, direction: post.isLiked == true ? 0 : 1, modelContext: modelContext) }
        } label: {
            Label("Upvote", systemImage: "arrow.up")
        }

        Button {
            Task { await viewModel.vote(post: post, direction: post.isLiked == false ? 0 : -1, modelContext: modelContext) }
        } label: {
            Label("Downvote", systemImage: "arrow.down")
        }

        Button {
            Task { await viewModel.toggleSave(post: post) }
        } label: {
            Label(post.isSaved ? "Unsave" : "Save", systemImage: post.isSaved ? "bookmark.slash" : "bookmark.fill")
        }
    }
}
