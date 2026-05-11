import SwiftUI

struct PostRowView: View {
    let post: Post

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            headerRow

            Text(post.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(post.isRead ? .secondary : .primary)
                .lineLimit(3)

            if let body = post.body, !body.isEmpty, post.isSelf {
                Text(body)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            mediaPreview

            footerRow
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }

    private var headerRow: some View {
        HStack(spacing: 6) {
            Text("r/\(post.subreddit)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.blue)

            Text("·")
                .foregroundStyle(.secondary)

            Text(post.author)
                .font(.caption)
                .foregroundStyle(.secondary)

            if post.isNSFW {
                nsfwTag
            }

            if let flair = post.flair, !flair.isEmpty {
                Text(flair)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.blue.opacity(0.7), in: RoundedRectangle(cornerRadius: 3))
            }

            Spacer()

            Text(post.createdAt.timeAgo)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var nsfwTag: some View {
        HStack(spacing: 2) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 8))
            Text("NSFW")
                .font(.caption2)
                .fontWeight(.bold)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 5)
        .padding(.vertical, 1)
        .background(.red, in: RoundedRectangle(cornerRadius: 3))
    }

    @ViewBuilder
    private var mediaPreview: some View {
        if let imageURL = post.imageURL, let url = URL(string: imageURL) {
            if post.isNSFW {
                nsfwBlurredPreview(url: url)
            } else {
                normalPreview(url: url)
            }
        } else if let thumbnailURL = post.thumbnailURL, let url = URL(string: thumbnailURL), !post.isVideo {
            if post.isNSFW {
                nsfwBlurredPreview(url: url)
            } else {
                AsyncImage(url: url) { phase in
                    if case .success(let image) = phase {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
    }

    private func nsfwBlurredPreview(url: URL) -> some View {
        ZStack {
            AsyncImage(url: url) { phase in
                if case .success(let image) = phase {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .blur(radius: 25)
                }
            }

            VStack(spacing: 4) {
                Image(systemName: "eye.slash.fill")
                    .font(.title3)
                    .foregroundStyle(.white)
                Text("NSFW")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 150)
            .background(Color.red.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .frame(maxHeight: 300)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func normalPreview(url: URL) -> some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            case .failure:
                Color.gray.opacity(0.2)
                    .frame(height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(Image(systemName: "photo").foregroundStyle(.secondary))
            case .empty:
                Color.gray.opacity(0.1)
                    .frame(height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(ProgressView())
            @unknown default:
                EmptyView()
            }
        }
    }

    private var footerRow: some View {
        HStack(spacing: 16) {
            voteDisplay

            Label("\(post.commentCount)", systemImage: "bubble.left")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            if post.isVideo {
                Image(systemName: "play.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var voteDisplay: some View {
        HStack(spacing: 4) {
            Image(systemName: post.isLiked == true ? "arrow.up" : "arrow.up")
                .font(.caption)
                .foregroundStyle(post.isLiked == true ? .orange : .secondary)

            Text(formatScore(post.score))
                .font(.caption)
                .foregroundStyle(post.isLiked == true ? .orange : (post.isLiked == false ? .blue : .secondary))

            if post.isLiked == false {
                Image(systemName: "arrow.down")
                    .font(.caption)
                    .foregroundStyle(.blue)
            }
        }
    }

    private func formatScore(_ score: Int) -> String {
        if score >= 10000 {
            return String(format: "%.1fk", Double(score) / 1000.0)
        } else if score >= 1000 {
            return String(format: "%.1fk", Double(score) / 1000.0)
        }
        return "\(score)"
    }
}
