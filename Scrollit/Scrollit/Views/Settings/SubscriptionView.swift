import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @State private var subscription = SubscriptionManager.shared
    @State private var isLoading = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                featuresSection
                pricingSection
                restoreSection
                termsSection
            }
            .padding()
        }
        .navigationTitle("Scrollit Pro")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await subscription.loadProducts()
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.system(size: 50))
                .foregroundStyle(.orange)

            Text("Unlock Scrollit Pro")
                .font(.title2)
                .fontWeight(.bold)

            Text("Get the full Reddit experience")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 20)
    }

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            featureRow("person.badge.key.fill", "Login with Reddit")
            featureRow("arrow.up.arrow.down", "Vote on posts & comments")
            featureRow("bubble.left.and.bubble.right", "Comment & reply")
            featureRow("paperplane", "Post text, images & links")
            featureRow("bookmark.fill", "Save posts to your account")
            featureRow("person.2.fill", "Multi-account switching")
            featureRow("bell.fill", "Messages & notifications")
        }
        .padding()
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
    }

    private func featureRow(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.orange)
                .frame(width: 24)

            Text(text)
                .font(.subheadline)

            Spacer()

            Image(systemName: "checkmark")
                .foregroundStyle(.green)
                .font(.caption)
        }
    }

    private var pricingSection: some View {
        VStack(spacing: 12) {
            if subscription.isPro {
                proActiveView
            } else {
                subscriptionOptions
            }
        }
    }

    private var proActiveView: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 40))
                .foregroundStyle(.green)

            Text("You're a Pro member!")
                .font(.headline)
                .foregroundStyle(.green)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }

    private var subscriptionOptions: some View {
        VStack(spacing: 12) {
            if let monthly = subscription.monthlyProduct {
                subscriptionCard(
                    product: monthly,
                    title: "Monthly",
                    subtitle: "$1.99/month",
                    isBestValue: false
                )
            }

            if let yearly = subscription.yearlyProduct {
                subscriptionCard(
                    product: yearly,
                    title: "Yearly",
                    subtitle: "$14.99/year",
                    isBestValue: true
                )
            }

            Text("7-day free trial included")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func subscriptionCard(product: Product, title: String, subtitle: String, isBestValue: Bool) -> some View {
        Button {
            Task {
                isLoading = true
                _ = await subscription.purchase(product)
                isLoading = false
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(title)
                            .font(.headline)

                        if isBestValue {
                            Text("Best Value")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.orange, in: RoundedRectangle(cornerRadius: 4))
                        }
                    }

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isBestValue ? Color.orange : Color(.systemGray4), lineWidth: isBestValue ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }

    private var restoreSection: some View {
        Button {
            Task { await subscription.restorePurchases() }
        } label: {
            Text("Restore Purchases")
                .font(.subheadline)
                .foregroundStyle(.blue)
        }
    }

    private var termsSection: some View {
        VStack(spacing: 4) {
            Text("Payment will be charged to your Apple ID account at confirmation of purchase. Subscription automatically renews unless it is canceled at least 24 hours before the end of the current period.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 4) {
                Link("Privacy Policy", destination: URL(string: "https://asunnyboy861.github.io/Scrollit/privacy.html")!)
                Text("·")
                Link("Terms of Use", destination: URL(string: "https://asunnyboy861.github.io/Scrollit/terms.html")!)
            }
            .font(.caption2)
        }
        .padding(.horizontal, 16)
    }
}
