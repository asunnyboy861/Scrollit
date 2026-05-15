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
    var errorMessage: String?
    var purchaseMessage: String?

    var isRealPro: Bool { isPro && !AuthService.shared.isDemoMode }

    private let monthlyID = "com.zzoutuo.Scrollit.pro.monthly"
    private let yearlyID = "com.zzoutuo.Scrollit.pro.yearly"

    private var updateTask: Task<Void, Never>?

    private init() {
        updateTask = Task {
            await loadProducts()
            await updateSubscriptionStatus()
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

            if storeProducts.isEmpty {
                errorMessage = "Unable to load subscription products. Please check your internet connection and try again."
            } else {
                errorMessage = nil
            }
        } catch {
            errorMessage = "Failed to load products: \(error.localizedDescription)"
        }
    }

    func purchase(_ product: Product) async -> Bool {
        errorMessage = nil

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
                errorMessage = "Your purchase is pending approval. You will get access once it is approved."
                return false
            @unknown default:
                errorMessage = "Unknown purchase result. Please try again."
                return false
            }
        } catch {
            errorMessage = "Purchase failed: \(error.localizedDescription)"
            return false
        }
    }

    func restorePurchases() async {
        errorMessage = nil

        do {
            try await AppStore.sync()
            await updateSubscriptionStatus()

            if !isPro {
                errorMessage = "No active subscriptions found to restore."
            }
        } catch {
            errorMessage = "Restore failed: \(error.localizedDescription)"
        }
    }

    func updateSubscriptionStatus() async {
        var hasActiveSubscription = false

        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productID == monthlyID || transaction.productID == yearlyID {
                    hasActiveSubscription = true
                }
                await transaction.finish()
            }
        }

        isPro = hasActiveSubscription
    }

    func handlePurchaseCompletion(result: Result<Product.PurchaseResult, Error>) {
        switch result {
        case .success(let purchaseResult):
            switch purchaseResult {
            case .success(let verification):
                do {
                    let transaction = try checkVerified(verification)
                    isPro = true
                    Task { await transaction.finish() }
                } catch {
                    errorMessage = error.localizedDescription
                }
            case .userCancelled:
                break
            case .pending:
                errorMessage = "Your purchase is pending approval."
            @unknown default:
                errorMessage = "Unknown purchase result."
            }
        case .failure(let error):
            errorMessage = "Purchase failed: \(error.localizedDescription)"
        }
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
        case .unverified(let transaction, let error):
            throw SubscriptionError.verificationFailed(error.localizedDescription)
        }
    }

    enum SubscriptionError: LocalizedError {
        case verificationFailed(String)

        var errorDescription: String? {
            switch self {
            case .verificationFailed(let reason): return "Purchase verification failed: \(reason)"
            }
        }
    }
}
