# Pricing Configuration

## Monetization Model: Subscription (IAP)

## Subscription Group
- **Group Name**: Scrollit Pro
- **Group ID**: 21590149

## Subscription Tiers

### 1. Monthly Subscription
- **Reference Name**: Scrollit Pro Monthly
- **Product ID**: `com.zzoutuo.Scrollit.pro.monthly`
- **Price**: $1.99 per month
- **Display Name**: Scrollit Pro Monthly
- **Description**: Full Reddit access: login, vote, comment
- **Localization**: English (US)

### 2. Yearly Subscription
- **Reference Name**: Scrollit Pro Yearly
- **Product ID**: `com.zzoutuo.Scrollit.pro.yearly`
- **Price**: $14.99 per year (37% savings vs monthly)
- **Display Name**: Scrollit Pro Yearly
- **Description**: Full Reddit access: login, vote, comment
- **Localization**: English (US)

## Free Tier (Anonymous Browsing)
- Browse all public subreddits (Hot/New/Top/Rising)
- Search subreddits and posts
- View posts and comments
- Image/video/GIF playback
- Dark mode
- Zero ads
- Local subscription management
- No login required

## Pro Features (Requires Subscription)
- Reddit account login (OAuth2)
- Vote (upvote/downvote)
- Comment and reply
- Post (text/image/link)
- Save posts synced to account
- Subscription sync
- Messages/notifications
- Multi-account switching
- Advanced content filters

## Free Trial
- **Duration**: 7 days
- **Type**: Free trial (auto-converts to paid)
- **Access**: All Pro features during trial

## Policy Pages Required
- Support Page: ✅ (Must include subscription management info)
- Privacy Policy: ✅
- Terms of Use: ✅ (REQUIRED for subscription apps)

## Apple IAP Compliance Checklist
- [x] Auto-renewal terms included in Terms
- [x] Cancellation instructions included
- [x] Pricing clearly stated
- [x] Free trial terms included
- [x] Restore purchases functionality implemented

## API Cost Optimization Strategy
- Anonymous users: Public API (www.reddit.com) — zero API cost
- Pro users: OAuth2 API (oauth.reddit.com) — $0.10/100 requests
- Smart caching reduces 50% of requests
- Public API分流 reduces 40% of OAuth2 usage
- Batch submission reduces 30% of write requests
- Optimized monthly API cost per Pro user: ~$1.50
- Gross margin: ($1.99 - $1.50) / $1.99 = 24.6%

## Competitive Pricing Comparison
| App | Monthly | Yearly | Free Tier | Free Trial |
|-----|---------|--------|-----------|------------|
| Scrollit | **$1.99** | **$14.99** | Full browsing | **7 days** |
| Narwhal 2 | $3.99 | N/A | None | None |
| Infinity iOS | $2.99+ | N/A | None | None |
| Hydra | $3.99 | N/A | Limited | None |
| Official Reddit | Free (ads) | N/A | Full (with ads) | N/A |
