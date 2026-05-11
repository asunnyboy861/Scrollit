import Foundation
import StoreKit

@MainActor
@Observable
final class SubscriptionManager {
    static let shared = SubscriptionManager()

    var isPro = false
    var monthlyProduct: Product?
    var yearlyProduct: Product?
    var isLoading = false

    private let monthlyID = "com.zzoutuo.Scrollit.pro.monthly"
    private let yearlyID = "com.zzoutuo.Scrollit.pro.yearly"

    private var updateTask: Task<Void, Never>?

    private init() {
        updateTask = Task {
            await updateSubscriptionStatus()
            await loadProducts()
            await listenForTransactions()
        }
    }

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let storeProducts = try await Product.products(for: [monthlyID, yearlyID])
            for product in storeProducts {
                switch product.id {
                case monthlyID: monthlyProduct = product
                case yearlyID: yearlyProduct = product
                default: break
                }
            }
        } catch {
            print("Failed to load products: \(error)")
        }
    }

    func purchase(_ product: Product) async -> Bool {
        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                isPro = true
                await transaction.finish()
                return true
            case .userCancelled:
                return false
            case .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            print("Purchase failed: \(error)")
            return false
        }
    }

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await updateSubscriptionStatus()
        } catch {
            print("Restore failed: \(error)")
        }
    }

    func updateSubscriptionStatus() async {
        var hasActiveSubscription = false

        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productID == monthlyID || transaction.productID == yearlyID {
                    hasActiveSubscription = true
                    break
                }
            }
        }

        isPro = hasActiveSubscription
    }

    private func listenForTransactions() async {
        for await result in Transaction.updates {
            if case .verified(let transaction) = result {
                if transaction.productID == monthlyID || transaction.productID == yearlyID {
                    isPro = true
                }
                await transaction.finish()
            }
        }
    }

    private func checkVerified(_ result: VerificationResult<Transaction>) throws -> Transaction {
        switch result {
        case .verified(let transaction):
            return transaction
        case .unverified:
            throw SubscriptionError.verificationFailed
        }
    }

    enum SubscriptionError: LocalizedError {
        case verificationFailed

        var errorDescription: String? {
            switch self {
            case .verificationFailed: return "Purchase verification failed"
            }
        }
    }
}
