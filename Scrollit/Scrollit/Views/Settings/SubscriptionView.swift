import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @State private var subscription = SubscriptionManager.shared
    @State private var isRestoring = false
    @State private var isPurchasing: String?
    @State private var showPurchaseMessage = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                if subscription.isPro {
                    proBanner
                }

                if subscription.isLoading {
                    loadingView
                } else if let errorMessage = subscription.errorMessage {
                    errorView(message: errorMessage)
                } else {
                    productListView
                }

                restoreButton
            }
        }
        .navigationTitle("Scrollit Pro")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await subscription.loadProducts()
        }
        .alert("Subscription", isPresented: $showPurchaseMessage) {
            Button("OK", role: .cancel) {
                subscription.purchaseMessage = nil
            }
        } message: {
            Text(subscription.purchaseMessage ?? "")
        }
        .onChange(of: subscription.purchaseMessage) {
            if subscription.purchaseMessage != nil {
                showPurchaseMessage = true
            }
        }
    }

    private var proBanner: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("You're a Pro!")
                    .font(.headline)
                    .foregroundStyle(.green)
            }

            Text("All premium features are unlocked. Manage your subscription below.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.vertical, 12)
        .background(Color.green.opacity(0.1))
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading subscription options...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundStyle(.orange)

            Text("Subscription Unavailable")
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Text("Please check your internet connection and try again, or tap Restore Purchases below.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.vertical, 40)
    }

    private var productListView: some View {
        VStack(spacing: 16) {
            if let monthly = subscription.monthlyProduct {
                productCard(product: monthly, isFeatured: false)
            }

            if let yearly = subscription.yearlyProduct {
                productCard(product: yearly, isFeatured: true)
            }

            if subscription.monthlyProduct == nil && subscription.yearlyProduct == nil {
                VStack(spacing: 12) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 30))
                        .foregroundStyle(.secondary)
                    Text("No subscription options available")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 40)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
    }

    private func productCard(product: Product, isFeatured: Bool) -> some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.displayName)
                        .font(.headline)

                    Text(product.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(product.displayPrice)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.orange)

                    if isFeatured {
                        Text("Best Value")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.orange, in: Capsule())
                    }
                }
            }

            Button {
                Task {
                    if subscription.isPro {
                        subscription.purchaseMessage = "You already have an active subscription. To manage or cancel it, go to Settings > Subscriptions in your device settings."
                        return
                    }
                    isPurchasing = product.id
                    let success = await subscription.purchase(product)
                    isPurchasing = nil
                    if success {
                        subscription.purchaseMessage = "Subscription activated successfully!"
                    }
                }
            } label: {
                HStack {
                    if isPurchasing == product.id {
                        ProgressView()
                            .controlSize(.small)
                            .tint(.white)
                    }
                    Text(isPurchasing == product.id ? "Processing..." : "Subscribe")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.orange, in: RoundedRectangle(cornerRadius: 10))
                .foregroundStyle(.white)
            }
            .disabled(isPurchasing != nil)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isFeatured ? Color.orange.opacity(0.3) : Color.gray.opacity(0.2), lineWidth: isFeatured ? 2 : 1)
        )
    }

    private var restoreButton: some View {
        Button {
            Task {
                isRestoring = true
                await subscription.restorePurchases()
                isRestoring = false
            }
        } label: {
            HStack {
                if isRestoring {
                    ProgressView()
                        .controlSize(.small)
                }
                Text(isRestoring ? "Restoring..." : "Restore Purchases")
                    .font(.subheadline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .disabled(isRestoring)
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
}
