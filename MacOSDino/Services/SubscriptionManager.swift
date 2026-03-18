// SubscriptionManager.swift
// MacOS-Dino – Abonelik & IAP Yönetimi
// Freemium, Lifetime Pro, Content Pass modeli

import Foundation
import StoreKit
import Combine

@MainActor
final class SubscriptionManager: ObservableObject {

    static let shared = SubscriptionManager()

    // MARK: - Product IDs

    enum ProductID: String, CaseIterable {
        case lifetimePro = "com.macosdino.lifetime_pro"       // $9.99
        case contentPassMonthly = "com.macosdino.content_monthly" // $0.99/ay
        case contentPassYearly = "com.macosdino.content_yearly"   // $7.99/yıl
    }

    // MARK: - Published State

    @Published var currentPlan: SubscriptionPlan = .free
    @Published var isProUser: Bool = false
    @Published var hasContentPass: Bool = false
    @Published var products: [Product] = []
    @Published var purchaseInProgress: Bool = false
    @Published var errorMessage: String? = nil

    // MARK: - Limits (Free tier)

    static let freeWallpaperLimit = 15
    static let freeShaderAccess = false
    static let freeUploadQuotaMB = 0
    static let proUploadQuotaMB = 5120 // 5 GB

    private var transactionListener: Task<Void, Never>?

    private init() {
        transactionListener = listenToTransactions()
        Task { await loadProducts() }
        Task { await checkCurrentEntitlements() }
    }

    // MARK: - Load Products

    func loadProducts() async {
        do {
            let ids = ProductID.allCases.map { $0.rawValue }
            products = try await Product.products(for: ids)
            print("🛒 \(products.count) ürün yüklendi")
        } catch {
            print("❌ Ürün yükleme hatası: \(error)")
        }
    }

    // MARK: - Purchase

    func purchase(_ productID: ProductID) async {
        guard let product = products.first(where: { $0.id == productID.rawValue }) else {
            errorMessage = "Ürün bulunamadı"
            return
        }

        purchaseInProgress = true
        errorMessage = nil

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await handleVerifiedTransaction(transaction)
                    await transaction.finish()
                case .unverified(_, let error):
                    errorMessage = "Doğrulanamayan satın alma: \(error.localizedDescription)"
                }
            case .userCancelled:
                break
            case .pending:
                errorMessage = "Satın alma onay bekliyor"
            @unknown default:
                break
            }
        } catch {
            errorMessage = "Satın alma hatası: \(error.localizedDescription)"
        }

        purchaseInProgress = false
    }

    // MARK: - Restore Purchases

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await checkCurrentEntitlements()
        } catch {
            errorMessage = "Satın alma geri yükleme hatası: \(error.localizedDescription)"
        }
    }

    // MARK: - Check Entitlements

    func checkCurrentEntitlements() async {
        var hasPro = false
        var hasContent = false

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }

            switch transaction.productID {
            case ProductID.lifetimePro.rawValue:
                hasPro = true
            case ProductID.contentPassMonthly.rawValue,
                 ProductID.contentPassYearly.rawValue:
                hasContent = true
            default:
                break
            }
        }

        isProUser = hasPro
        hasContentPass = hasContent

        if hasPro && hasContent {
            currentPlan = .proWithContent
        } else if hasPro {
            currentPlan = .pro
        } else if hasContent {
            currentPlan = .contentOnly
        } else {
            currentPlan = .free
        }

        // Supabase'e sync et
        await syncSubscriptionToSupabase()
    }

    // MARK: - Transaction Listener

    private func listenToTransactions() -> Task<Void, Never> {
        Task.detached {
            for await result in Transaction.updates {
                guard case .verified(let transaction) = result else { continue }
                await self.handleVerifiedTransaction(transaction)
                await transaction.finish()
            }
        }
    }

    private func handleVerifiedTransaction(_ transaction: Transaction) async {
        await checkCurrentEntitlements()

        // Analytics
        await AnalyticsService.shared.trackEvent(.subscriptionStarted, properties: [
            "product_id": transaction.productID,
            "plan": currentPlan.rawValue
        ])
    }

    // MARK: - Supabase Sync

    private func syncSubscriptionToSupabase() async {
        guard let userId = try? await supabase.auth.session.user.id else { return }

        let subscriptionData: [String: String] = [
            "user_id": userId.uuidString,
            "plan": currentPlan.rawValue,
            "is_pro": isProUser ? "true" : "false",
            "has_content_pass": hasContentPass ? "true" : "false",
            "updated_at": ISO8601DateFormatter().string(from: Date())
        ]

        do {
            try await supabase
                .from(SupabaseConfig.Tables.subscriptions)
                .upsert(subscriptionData)
                .execute()
        } catch {
            print("⚠️ Abonelik Supabase sync hatası: \(error)")
        }
    }

    // MARK: - Access Control

    func canAccessWallpaper(_ wallpaper: Wallpaper) -> Bool {
        if isProUser { return true }
        if wallpaper.isFeatured { return false } // Featured = Pro only
        return true // Free wallpapers
    }

    func canUseShaders() -> Bool {
        return isProUser
    }

    func canUpload() -> Bool {
        return isProUser
    }

    var uploadQuotaMB: Int {
        return isProUser ? Self.proUploadQuotaMB : Self.freeUploadQuotaMB
    }

    deinit {
        transactionListener?.cancel()
    }
}

// MARK: - Subscription Plan

enum SubscriptionPlan: String, Codable {
    case free = "free"
    case pro = "pro"
    case contentOnly = "content_only"
    case proWithContent = "pro_with_content"

    var displayName: String {
        switch self {
        case .free: return "Ücretsiz"
        case .pro: return "Pro (Lifetime)"
        case .contentOnly: return "Content Pass"
        case .proWithContent: return "Pro + Content"
        }
    }
}
