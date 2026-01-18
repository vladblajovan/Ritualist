import Foundation

// MARK: - Premium & Subscription Strings

extension Strings {
    // MARK: - Paywall
    public enum Paywall {
        public static let unlockAdvancedStats = String(localized: "paywall.unlock_advanced_stats")
        public static let statsBlockedMessage = String(localized: "paywall.stats_blocked_message")
        public static let proLabel = String(localized: "paywall.pro_label")
        public static let upgrade = String(localized: "paywall.upgrade")
        public static let title = String(localized: "paywall.title")
        public static let loadingPlans = String(localized: "paywall.loadingPlans")
        public static let loadingPro = String(localized: "paywall.loadingPro")
        public static let unableToLoad = String(localized: "paywall.unableToLoad")
        public static let unableToLoadMessage = String(localized: "paywall.unableToLoadMessage")
        public static let headerTitle = String(localized: "paywall.header.title")
        public static let headerSubtitle = String(localized: "paywall.header.subtitle")
        public static let whatsIncluded = String(localized: "paywall.whatsIncluded")
        public static let choosePlan = String(localized: "paywall.choosePlan")
        public static let popular = String(localized: "paywall.popular")
        public static let havePromoCode = String(localized: "paywall.havePromoCode")
        public static let redeemOfferCode = String(localized: "paywall.redeemOfferCode")
        public static let processing = String(localized: "paywall.processing")
        public static let purchase = String(localized: "paywall.purchase")
        public static let startFreeTrial = String(localized: "paywall.startFreeTrial")
        public static let selectPlan = String(localized: "paywall.selectPlan")
        public static let productsError = String(localized: "paywall.productsError")
        public static let restorePurchases = String(localized: "paywall.restorePurchases")
        public static func trialInfo(_ price: String) -> String { String(format: String(localized: "paywall.trialInfo"), price) }
        public static let subscriptionTerms = String(localized: "paywall.subscriptionTerms")
        public static func discountSavePercent(_ percent: Int) -> String { String(format: String(localized: "paywall.discount.savePercent"), percent) }
        public static let discountFallback = String(localized: "paywall.discount.fallback")
    }

    // MARK: - Subscription
    public enum Subscription {
        public static let sectionHeader = String(localized: "subscription.section")
        public static let mode = String(localized: "subscription.mode")
        public static let allFeaturesUnlocked = String(localized: "subscription.all_features_unlocked")
        public static let renews = String(localized: "subscription.renews")
        public static let billingStarts = String(localized: "subscription.billing_starts")
        public static let trial = String(localized: "subscription.trial")
        public static let trialEndsOn = String(localized: "subscription.trial_ends_on")
        public static let restoring = String(localized: "subscription.restoring")
        public static let restorePurchases = String(localized: "subscription.restore_purchases")
        public static let manageSubscription = String(localized: "subscription.manage_subscription")
        public static func restoredPurchases(_ count: Int) -> String { String(format: String(localized: "subscription.restored_purchases"), count) }
        public static let noPurchasesToRestore = String(localized: "subscription.no_purchases_to_restore")
        public static let restoreFailed = String(localized: "subscription.restore_failed")
        public static let billingIssueTitle = String(localized: "subscription.billing_issue_title")
        public static let billingIssueSubtitle = String(localized: "subscription.billing_issue_subtitle")
    }

    // MARK: - Personality Insights
    public enum PersonalityInsights {
        public static let title = String(localized: "personality.title")
        public static let settingsTitle = String(localized: "personality.settings.title")
        public static let analysisFrequency = String(localized: "personality.analysisFrequency")
        public static let aboutBigFive = String(localized: "personality.aboutBigFive")
        public static let tapToViewInsights = String(localized: "personality.tapToViewInsights")
        public static let personalityAnalysis = String(localized: "personality.analysis")
    }
}
