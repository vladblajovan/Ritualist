import Foundation

#if ALL_FEATURES_ENABLED
print("✅ ALL_FEATURES_ENABLED detected")
#else
print("🔒 Subscription mode active")
#endif

#if SUBSCRIPTION_ENABLED  
print("💳 SUBSCRIPTION_ENABLED detected")
#else
print("🆓 No subscription flag")
#endif
