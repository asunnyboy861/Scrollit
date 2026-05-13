import SwiftUI
import SwiftData

struct BookmarksView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = 0
    @State private var tracker = ReadingTrackerService.shared

    var body: some View {
        VStack(spacing: 0) {
            segmentedPicker
            contentView
        }
        .navigationTitle("Library")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var segmentedPicker: some View {
        Picker("", selection: $selectedTab) {
            Text("History").tag(0)
            Text("Bookmarks").tag(1)
            Text("Stats").tag(2)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var contentView: some View {
        switch selectedTab {
        case 0: historyView
        case 1: bookmarksView
        case 2: statsView
        default: historyView
        }
    }

    private var historyView: some View {
        let groups = tracker.getHistoryGrouped(modelContext: modelContext)

        return Group {
            if groups.isEmpty {
                EmptyStateView(
                    icon: "clock.arrow.circlepath",
                    title: "No Reading History",
                    subtitle: "Posts you read will appear here"
                )
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(groups, id: \.0) { label, posts in
                            Section {
                                ForEach(posts) { post in
                                    NavigationLink(value: post) {
                                        historyRow(post)
                                    }
                                    .buttonStyle(.plain)

                                    if post.id != posts.last?.id {
                                        Divider().padding(.leading, 60)
                                    }
                                }
                            } header: {
                                HStack {
                                    Text(label)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.secondary)

                                    Spacer()

                                    Text("\(posts.count) posts")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.top, 12)
                                .padding(.bottom, 4)
                            }
                        }
                    }
                }
                .navigationDestination(for: Post.self) { post in
                    PostDetailView(post: post)
                }
            }
        }
    }

    private func historyRow(_ post: Post) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("r/\(post.subreddit)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.blue)

                Text(post.title)
                    .font(.subheadline)
                    .lineLimit(2)
            }

            Spacer()

            if let readAt = post.readAt {
                Text(readAt.timeAgo)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private var bookmarksView: some View {
        let bookmarks = tracker.getBookmarkedPosts(modelContext: modelContext)

        return Group {
            if bookmarks.isEmpty {
                EmptyStateView(
                    icon: "bookmark",
                    title: "No Bookmarks",
                    subtitle: "Save posts to read later"
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(bookmarks) { post in
                            NavigationLink(value: post) {
                                bookmarkRow(post)
                            }
                            .buttonStyle(.plain)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    tracker.toggleBookmark(post: post)
                                } label: {
                                    Label("Remove", systemImage: "bookmark.slash")
                                }
                            }

                            Divider().padding(.leading, 16)
                        }
                    }
                }
                .navigationDestination(for: Post.self) { post in
                    PostDetailView(post: post)
                }
            }
        }
    }

    private func bookmarkRow(_ post: Post) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("r/\(post.subreddit)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.blue)

                    Text("·")
                        .foregroundStyle(.secondary)

                    Text("u/\(post.author)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(post.title)
                    .font(.subheadline)
                    .lineLimit(2)

                HStack(spacing: 12) {
                    Label("\(post.score)", systemImage: "arrow.up")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Label("\(post.commentCount)", systemImage: "bubble.left")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Image(systemName: "bookmark.fill")
                .font(.caption)
                .foregroundStyle(.orange)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var statsView: some View {
        let todayCount = tracker.getPostsReadToday()
        let weekCount = tracker.getPostsReadThisWeek()
        let totalCount = tracker.getTotalPostsRead()
        let streak = tracker.getReadingStreak()
        let topSubs = tracker.getTopSubreddits(modelContext: modelContext)

        return ScrollView {
            VStack(spacing: 20) {
                statsHeader

                statsGrid(todayCount: todayCount, weekCount: weekCount, totalCount: totalCount, streak: streak)

                if !topSubs.isEmpty {
                    topSubredditsSection(topSubs)
                }

                if totalCount > 0 {
                    readingInsightsSection(todayCount: todayCount, weekCount: weekCount, totalCount: totalCount, streak: streak)
                }
            }
            .padding()
        }
    }

    private var statsHeader: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 36))
                .foregroundStyle(.orange)

            Text("Reading Insights")
                .font(.title3)
                .fontWeight(.bold)

            Text("Your Reddit browsing at a glance")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 16)
    }

    private func statsGrid(todayCount: Int, weekCount: Int, totalCount: Int, streak: Int) -> some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            statCard(icon: "doc.text.fill", title: "Today", value: "\(todayCount)", color: .blue)
            statCard(icon: "calendar", title: "This Week", value: "\(weekCount)", color: .green)
            statCard(icon: "flame.fill", title: "Streak", value: "\(streak) day\(streak == 1 ? "" : "s")", color: .orange)
            statCard(icon: "books.vertical.fill", title: "All Time", value: "\(totalCount)", color: .purple)
        }
    }

    private func statCard(icon: String, title: String, value: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(.title)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
    }

    private func topSubredditsSection(_ subs: [(String, Int)]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Communities")
                .font(.headline)

            ForEach(Array(subs.enumerated()), id: \.offset) { index, sub in
                HStack(spacing: 12) {
                    Text("\(index + 1)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .frame(width: 24, height: 24)
                        .background(index < 3 ? Color.orange : Color.gray, in: Circle())

                    Text("r/\(sub.0)")
                        .font(.subheadline)

                    Spacer()

                    Text("\(sub.1) posts")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
    }

    private func readingInsightsSection(todayCount: Int, weekCount: Int, totalCount: Int, streak: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Insights")
                .font(.headline)

            if weekCount > 0 {
                let avgPerDay = Double(weekCount) / 7.0
                insightRow(
                    "calendar.badge.clock",
                    "Daily Average",
                    String(format: "%.1f posts/day", avgPerDay)
                )
            }

            if streak > 1 {
                insightRow(
                    "flame.fill",
                    "Keep It Up!",
                    "You've been reading for \(streak) consecutive days"
                )
            }

            if todayCount == 0 {
                insightRow(
                    "sparkles",
                    "Start Reading",
                    "Browse your feed to start building today's history"
                )
            } else if todayCount >= 20 {
                insightRow(
                    "star.fill",
                    "Power Reader",
                    "You've read \(todayCount) posts today!"
                )
            }
        }
        .padding()
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
    }

    private func insightRow(_ icon: String, _ title: String, _ detail: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.orange)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
