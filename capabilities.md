# Capabilities Configuration

## Analysis
Based on operation guide analysis:
- "订阅" / "购买" / "会员" / "premium" / "$1.99/月" → In-App Purchase required
- "登录" / "OAuth2" / "Reddit账户" → Network access required (outgoing connections)
- "深色模式" / "Dark Mode" → System appearance support (no capability needed)
- "匿名浏览" / "公开API" → Network access required (already covered)
- "Keychain" / "Token" → Keychain access (default entitlement)
- "缓存" / "本地存储" → Local file storage (default entitlement)

## Auto-Configured Capabilities
| Capability | Status | Method |
|------------|--------|--------|
| In-App Purchase | ✅ Configured | Xcode Signing & Capabilities (StoreKit 2) |
| Outgoing Network Connections | ✅ Configured | Default iOS entitlement |

## Manual Configuration Required
| Capability | Status | Steps |
|------------|--------|-------|
| In-App Purchase (App Store Connect) | ⏳ Pending | 1. Create app record in App Store Connect 2. Configure subscription group "Scrollit Pro" 3. Create monthly subscription $1.99 (Product ID: com.zzoutuo.Scrollit.pro.monthly) 4. Create yearly subscription $14.99 (Product ID: com.zzoutuo.Scrollit.pro.yearly) 5. Add 7-day free trial introductory offer 6. Submit for review |

## No Configuration Needed
- iCloud / CloudKit — no sync features
- Push Notifications — no notification features
- HealthKit — not a health app
- Location Services — no location features
- Apple Watch — no watch companion
- Background Modes — no background processing needed
- Camera / Photo Library — no photo capture
- Siri — no Siri integration
- Sign in with Apple — using Reddit OAuth2 instead

## Verification
- Build succeeded after configuration: ✅
- All entitlements correct: ✅
