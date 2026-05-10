import SwiftUI

struct PostSwipeActions: ViewModifier {
    let post: Post
    let onUpvote: () -> Void
    let onDownvote: () -> Void
    let onSave: () -> Void
    let onShare: () -> Void

    func body(content: Content) -> some View {
        content
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button {
                    onShare()
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
                .tint(.blue)

                Button {
                    onSave()
                } label: {
                    Label(post.isSaved ? "Unsave" : "Save", systemImage: post.isSaved ? "bookmark.slash" : "bookmark")
                }
                .tint(.indigo)

                Button {
                    onDownvote()
                } label: {
                    Label("Downvote", systemImage: "arrow.down")
                }
                .tint(.blue)

                Button {
                    onUpvote()
                } label: {
                    Label("Upvote", systemImage: "arrow.up")
                }
                .tint(.orange)
            }
    }
}
