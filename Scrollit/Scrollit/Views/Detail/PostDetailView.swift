import SwiftUI
import SwiftData

struct PostDetailView: View {
    let post: Post
    @State private var viewModel = PostDetailViewModel()
    @State private var showingImageViewer = false
    @State private var showingVideoPlayer = false
    @State private var replyText = ""
    @State private var showingReplyField = false
    @State private var showingReportSheet = false
    @State private var showingBlockAlert = false
    @State private var revealNSFW = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                postHeader
                postContent
                postActions
                commentSection
            }
            .padding(.horizontal, 16)
        }
        .navigationTitle("r/\(post.subreddit)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    ShareLink(item: URL(string: "https://reddit.com\(post.permalink)")!) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }

                    Button {
                        showingReportSheet = true
                    } label: {
                        Label("Report Content", systemImage: "exclamationmark.triangle")
                    }

                    Button {
                        showingBlockAlert = true
                    } label: {
                        Label("Block User", systemImage: "person.crop.circle.badge.xmark")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                }
            }
        }
        .task {
            await viewModel.loadPost(id: post.id, subreddit: post.subreddit)
        }
        .fullScreenCover(isPresented: $showingImageViewer) {
            if let imageURL = post.imageURL, let url = URL(string: imageURL) {
                ImageViewer(url: url, isPresented: $showingImageViewer)
            }
        }
        .fullScreenCover(isPresented: $showingVideoPlayer) {
            if let videoURL = post.videoURL, let url = URL(string: videoURL) {
                VideoPlayerView(url: url, isPresented: $showingVideoPlayer)
            }
        }
        .sheet(isPresented: $showingReportSheet) {
            ReportContentView(
                postId: post.id,
                postAuthor: post.author,
                postTitle: post.title
            )
        }
        .alert("Block u/\(post.author)?", isPresented: $showingBlockAlert) {
            Button("Block", role: .destructive) {
                ContentFilterService.shared.blockUser(post.author)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Posts and comments from this user will be hidden. You can unblock them in Settings.")
        }
    }

    private var postHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            NavigationLink {
                FeedView(initialSubreddit: post.subreddit)
            } label: {
                Text("r/\(post.subreddit)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.blue)
            }

            HStack(spacing: 6) {
                Text("u/\(post.author)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("·")
                    .foregroundStyle(.secondary)

                Text(post.createdAt.timeAgo)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if post.isNSFW {
                    nsfwTag
                }
            }

            Text(post.title)
                .font(.headline)
                .fontWeight(.bold)
        }
    }

    private var nsfwTag: some View {
        HStack(spacing: 3) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption2)
            Text("NSFW")
                .font(.caption2)
                .fontWeight(.bold)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(.red, in: RoundedRectangle(cornerRadius: 4))
    }

    @ViewBuilder
    private var postContent: some View {
        if let body = post.body, !body.isEmpty {
            Text(body)
                .font(.subheadline)
                .foregroundStyle(.primary)
        }

        if post.isNSFW {
            nsfwBlurOverlay
        }

        if let imageURL = post.imageURL, let url = URL(string: imageURL) {
            if post.isNSFW {
                ZStack {
                    AsyncImage(url: url) { phase in
                        if case .success(let image) = phase {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .blur(radius: revealNSFW ? 0 : 30)
                                .overlay {
                                    if !revealNSFW {
                                        nsfwBlurOverlay
                                    }
                                }
                        }
                    }
                }
            } else {
                normalImagePreview
            }
        }

        if post.isVideo, post.videoURL != nil {
            Button {
                showingVideoPlayer = true
            } label: {
                HStack {
                    Image(systemName: "play.circle.fill")
                        .font(.title2)
                    Text("Play Video")
                        .font(.subheadline)
                }
                .foregroundStyle(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue, in: RoundedRectangle(cornerRadius: 8))
            }
        }

        if let url = post.url, !post.isSelf, !post.isVideo, post.imageURL == nil {
            Link(destination: URL(string: url)!) {
                HStack {
                    Image(systemName: "link")
                    Text(url)
                        .font(.caption)
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                }
                .foregroundStyle(.blue)
                .padding(10)
                .background(Color.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    @ViewBuilder
    private var normalImagePreview: some View {
        if let imageURL = post.imageURL, let url = URL(string: imageURL) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .onTapGesture { showingImageViewer = true }
                case .failure:
                    Color.gray.opacity(0.2)
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(Image(systemName: "photo").foregroundStyle(.secondary))
                case .empty:
                    Color.gray.opacity(0.1)
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(ProgressView())
                @unknown default:
                    EmptyView()
                }
            }
        }
    }

    private var nsfwBlurOverlay: some View {
        VStack(spacing: 8) {
            Image(systemName: "eye.slash.fill")
                .font(.title2)
                .foregroundStyle(.white)

            Text("NSFW Content")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.white)

            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    revealNSFW = true
                }
            } label: {
                Text("Tap to Reveal")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.2), in: RoundedRectangle(cornerRadius: 6))
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
        .background(Color.red.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var postActions: some View {
        HStack(spacing: 20) {
            voteButtons
            commentButton
            saveButton
            reportButton
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
    }

    private var voteButtons: some View {
        HStack(spacing: 8) {
            Button {
                Task { await viewModel.vote(post: post, direction: post.isLiked == true ? 0 : 1) }
            } label: {
                Image(systemName: "arrow.up")
                    .foregroundStyle(post.isLiked == true ? .orange : .secondary)
            }

            Text("\(post.score)")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(post.isLiked == true ? .orange : (post.isLiked == false ? .blue : .primary))

            Button {
                Task { await viewModel.vote(post: post, direction: post.isLiked == false ? 0 : -1) }
            } label: {
                Image(systemName: "arrow.down")
                    .foregroundStyle(post.isLiked == false ? .blue : .secondary)
            }
        }
    }

    private var commentButton: some View {
        Button {
            showingReplyField.toggle()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "bubble.left")
                Text("\(post.commentCount)")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
    }

    private var saveButton: some View {
        Button {
            Task { await FeedViewModel().toggleSave(post: post) }
        } label: {
            Image(systemName: post.isSaved ? "bookmark.fill" : "bookmark")
                .foregroundStyle(post.isSaved ? .yellow : .secondary)
        }
    }

    private var reportButton: some View {
        Button {
            showingReportSheet = true
        } label: {
            Image(systemName: "exclamationmark.triangle")
                .foregroundStyle(.secondary)
        }
    }

    private var commentSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            if showingReplyField {
                replyField
            }

            if viewModel.isLoading {
                ProgressView()
                    .padding()
                    .frame(maxWidth: .infinity)
            } else if viewModel.comments.isEmpty {
                Text("No comments yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 16)
            } else {
                ForEach(viewModel.comments) { comment in
                    CommentRowView(
                        comment: comment,
                        onUpvote: {
                            viewModel.voteCommentById(comment.id, direction: comment.isLiked == true ? 0 : 1)
                        },
                        onDownvote: {
                            viewModel.voteCommentById(comment.id, direction: comment.isLiked == false ? 0 : -1)
                        },
                        onReply: { text in
                            Task { await viewModel.reply(to: "t1_\(comment.id)", text: text) }
                        }
                    )
                }
            }
        }
    }

    private var replyField: some View {
        VStack(spacing: 8) {
            TextField("Write a comment...", text: $replyText, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...6)

            HStack {
                Spacer()
                Button("Cancel") {
                    showingReplyField = false
                    replyText = ""
                }
                .buttonStyle(.bordered)

                Button("Reply") {
                    Task {
                        await viewModel.reply(to: "t3_\(post.id)", text: replyText)
                        replyText = ""
                        showingReplyField = false
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(replyText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
