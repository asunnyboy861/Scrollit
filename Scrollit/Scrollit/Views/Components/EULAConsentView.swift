import SwiftUI

struct EULAConsentView: View {
    @State private var isScrolledToBottom = false
    let onAgree: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            headerSection

            eulaContent

            actionButtons
        }
        .background(Color(.systemBackground))
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "shield.checkered")
                .font(.system(size: 40))
                .foregroundStyle(.orange)

            Text("Terms of Use")
                .font(.title2)
                .fontWeight(.bold)

            Text("Please read and agree to continue")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 40)
        .padding(.bottom, 16)
    }

    private var eulaContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                eulaSection(
                    title: "1. Acceptance of Terms",
                    content: "By using Scrollit, you agree to these Terms of Use. If you do not agree, please do not use the app."
                )

                eulaSection(
                    title: "2. Zero Tolerance for Objectionable Content",
                    content: "Scrollit has a strict zero-tolerance policy for objectionable content, including but not limited to: sexual content involving minors, non-consensual intimate media, hate speech, harassment, threats of violence, and illegal content. Any user who posts such content will be immediately and permanently banned."
                )

                eulaSection(
                    title: "3. User-Generated Content",
                    content: "Scrollit displays content from Reddit, a third-party platform. Content marked as NSFW (Not Safe For Work) is available only to logged-in users. NSFW content is clearly labeled. You can report objectionable content and block abusive users at any time."
                )

                eulaSection(
                    title: "4. Content Reporting",
                    content: "If you encounter objectionable content, please use the Report button. We are committed to reviewing and acting on all reports within 24 hours. Reported content that violates our policies will be removed, and the offending user will be ejected from the platform."
                )

                eulaSection(
                    title: "5. User Responsibility",
                    content: "You are responsible for your use of the app. You must not use Scrollit to distribute, promote, or facilitate objectionable or illegal content. Violations will result in immediate account termination."
                )

                eulaSection(
                    title: "6. NSFW Content Controls",
                    content: "NSFW content visibility is managed through your Reddit account settings on reddit.com. You cannot enable or disable NSFW content within the Scrollit app. To change your NSFW preferences, visit reddit.com/settings/feed."
                )
            }
            .padding()
            .background(GeometryReader { geometry in
                Color.clear.preference(
                    key: ScrollOffsetPreferenceKey.self,
                    value: geometry.frame(in: .named("eulaScroll")).minY
                )
            })
        }
        .coordinateSpace(name: "eulaScroll")
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
            isScrolledToBottom = value < -300
        }
        .frame(maxHeight: .infinity)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                UserDefaults.standard.set(true, forKey: "eula_accepted")
                onAgree()
            } label: {
                Text("I Agree to the Terms of Use")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.orange, in: RoundedRectangle(cornerRadius: 10))
            }

            Button {
                exit(0)
            } label: {
                Text("Decline")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 20)
        }
        .padding(.horizontal)
        .padding(.top, 16)
    }

    private func eulaSection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.bold)

            Text(content)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
