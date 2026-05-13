import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @State private var subscription = SubscriptionManager.shared

    private let groupID = "21590149"

    var body: some View {
        SubscriptionStoreView(groupID: groupID)
            .storeButton(.visible, for: .redeemCode)
            .storeButton(.visible, for: .policies)
            .onInAppPurchaseCompletion { _, _ in
                Task { await subscription.updateSubscriptionStatus() }
            }
            .navigationTitle("Scrollit Pro")
            .navigationBarTitleDisplayMode(.inline)
    }
}
