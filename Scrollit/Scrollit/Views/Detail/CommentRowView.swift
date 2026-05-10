import SwiftUI

struct CommentRowView: View {
    let comment: CommentItem
    let onUpvote: () -> Void
    let onDownvote: () -> Void
    let onReply: (String) -> Void
    @State private var isCollapsed = false
    @State private var showingReply = false
    @State private var replyText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            commentHeader

            if !isCollapsed {
                Text(comment.body)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .padding(.top, 2)

                commentActions

                ForEach(comment.replies) { reply in
                    CommentRowView(
                        comment: reply,
                        onUpvote: onUpvote,
                        onDownvote: onDownvote,
                        onReply: onReply
                    )
                    .padding(.leading, 16)
                }
            }

            if showingReply {
                replyField
            }
        }
        .padding(.vertical, 6)
        .padding(.leading, CGFloat(comment.depth) * 16)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                isCollapsed.toggle()
            }
        }
    }

    private var commentHeader: some View {
        HStack(spacing: 6) {
            Text(comment.author)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.blue)

            Text("·")
                .foregroundStyle(.secondary)

            Text(comment.createdAt.timeAgo)
                .font(.caption2)
                .foregroundStyle(.secondary)

            if isCollapsed {
                Text("+ \(countReplies(comment)) replies")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var commentActions: some View {
        HStack(spacing: 16) {
            Button {
                onUpvote()
            } label: {
                HStack(spacing: 2) {
                    Image(systemName: "arrow.up")
                        .font(.caption2)
                    Text("\(comment.score)")
                        .font(.caption2)
                }
                .foregroundStyle(comment.isLiked == true ? .orange : .secondary)
            }

            Button {
                onDownvote()
            } label: {
                Image(systemName: "arrow.down")
                    .font(.caption2)
                    .foregroundStyle(comment.isLiked == false ? .blue : .secondary)
            }

            Button {
                showingReply.toggle()
            } label: {
                Text("Reply")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.top, 2)
    }

    private var replyField: some View {
        VStack(spacing: 6) {
            TextField("Reply...", text: $replyText, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(2...4)

            HStack {
                Spacer()
                Button("Cancel") {
                    showingReply = false
                    replyText = ""
                }
                .buttonStyle(.bordered)

                Button("Send") {
                    onReply(replyText)
                    replyText = ""
                    showingReply = false
                }
                .buttonStyle(.borderedProminent)
                .disabled(replyText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(.top, 4)
    }

    private func countReplies(_ comment: CommentItem) -> Int {
        comment.replies.count + comment.replies.reduce(0) { $0 + countReplies($1) }
    }
}
