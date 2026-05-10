# Scrollit - iOS Development Guide

## Executive Summary

**Scrollit** is a minimalist Reddit client for iOS that delivers an ad-free, stable, and delightful browsing experience. The name combines "Scroll" (the most frequent Reddit user action) + "it" — implying "just scroll it" with zero learning curve. The app targets Reddit users frustrated by the official app's ad bombardment, frequent crashes, inconsistent video player gestures, and lost reading positions.

**Subtitle**: Reddit, Reimagined

**Key Differentiators**:
- Zero ads — third-party client inherently ad-free
- Anonymous browsing mode — browse without login, using Reddit's public API at zero cost
- Lowest subscription price — $1.99/month vs competitors' $3.99/month
- Unified gesture system — consistent swipe-down-to-dismiss for both images and videos
- Scroll position preservation — never lose your reading place when switching apps
- Native SwiftUI — lightweight, stable, low memory footprint

**Target Market**: US English-speaking Reddit users aged 18-45 who browse Reddit primarily on iPhone.

**App Category**: News / Social Networking

## Competitive Analysis

| App | Price | Ads | Anonymous Mode | SwiftUI Native | Crash Rate | Video Player | Our Advantage |
|-----|-------|-----|----------------|----------------|------------|--------------|---------------|
| Official Reddit | Free (with ads) | Heavy | No | No | High | Poor (inconsistent gestures) | Zero ads, stable, unified gestures |
| Narwhal 2 | $3.99/month | None | No | No | Low | Fair | Half price, anonymous mode, SwiftUI |
| Infinity iOS | $2.99-9.99/month | None | Yes | Yes | Low | Fair | Lower transparent price, simpler UI |
| Hydra | Free + IAP | None | No | Yes | Low | Good | Anonymous mode, lower price |
| Apollo (defunct) | Was freemium | None | No | Yes | Low | Good | Still alive, anonymous mode |

**Competitive Edge Summary**: Scrollit is the ONLY Reddit client combining free anonymous browsing + lowest subscription price + native SwiftUI + unified gesture system.

## Feature Inventory

### Primary Features

| # | Feature | User Operation Flow | Data Input | Processing | Data Output | Persistence | Acceptance Criteria |
|---|---------|--------------------|------------|------------|-------------|-------------|---------------------|
| 1 | Anonymous Browsing | 1. User opens app → 2. Hot feed loads immediately (no login wall) → 3. User scrolls to browse | None required | RedditAPIService fetches from www.reddit.com public API | Post list with title, thumbnail, score, comment count | GRDB local cache (5-min TTL for feed, 30-min for post detail) | User can browse all public subreddits without any login or account |
| 2 | Feed Sorting | 1. User taps sort icon in toolbar → 2. Selects Hot/New/Top/Rising → 3. Feed reloads with selected sort | Sort selection (enum) | FeedViewModel.loadFeed() with sort parameter | Sorted post list | ViewModel state + cache keyed by sort type | All 4 sort modes return correct post ordering; switching is instant from cache |
| 3 | Subreddit Feed | 1. User taps subreddit name → 2. Feed loads for that subreddit → 3. Back button returns to main feed | Subreddit name string | RedditAPIService.getFeed(subreddit:) | Subreddit-specific post list | Cache keyed by subreddit+sort | Subreddit feed loads correctly; navigation back preserves main feed state |
| 4 | OAuth2 Login | 1. User taps profile icon → 2. Taps "Login with Reddit" → 3. ASWebAuthenticationSession opens → 4. User authorizes → 5. Token exchanged and stored | Reddit OAuth2 authorization code | AuthService exchanges code via PKCE flow; TokenManager stores access+refresh tokens | Login success state; user profile data | Keychain (tokens); SwiftData (profile) | Login completes without error; tokens persist across app restarts; refresh works |
| 5 | Post Detail View | 1. User taps post row → 2. Post detail opens with shared-element transition → 3. Content + comments displayed | Post object (id, title, body, media URLs) | PostDetailViewModel loads comments via RedditAPIService | Full post content + threaded comments | Cache (30-min for post, 10-min for comments) | Post displays correctly with all content types (text, image, video, link); comments load in tree structure |
| 6 | Comment System | 1. User scrolls to comments → 2. Taps comment to expand/collapse → 3. Swipes left to vote → 4. Taps reply to respond | Comment interactions (vote direction, reply text, collapse toggle) | CommentViewModel handles vote (optimistic update + API call), reply submission | Updated vote count, new reply in thread | SwiftData (local vote state); API (authenticated actions) | Comments display in tree; collapse/expand works; voting shows instant feedback; reply appears after submission |
| 7 | Media Viewer (Image) | 1. User taps image in post → 2. Full-screen viewer opens → 3. Pinch to zoom → 4. Double-tap for full zoom → 5. Swipe down to dismiss | Image URL | Kingfisher loads from cache → disk → network | Full-resolution image display | Kingfisher 3-tier cache (memory → disk → network) | Image loads progressively; zoom is smooth; swipe-down dismiss works consistently |
| 8 | Media Viewer (Video) | 1. Video auto-plays muted in feed → 2. Tap to unmute → 3. Tap for fullscreen → 4. Swipe down to dismiss (same as image!) | Video URL (HLS) | AVPlayer with looper for GIF/short video; VideoPlayerView manages playback | Video playback with controls | No persistent cache (streaming only) | Video auto-plays muted; unmute on tap; swipe-down dismiss (consistent with image); progress bar works |
| 9 | Swipe Actions | 1. User swipes left on post row → 2. Action buttons appear (upvote, downvote, save, share) → 3. User taps action | Swipe gesture + action type | FeedViewModel.vote() with optimistic update; post.isSaved toggle | Updated vote count, saved state | SwiftData (local state); API (authenticated) | Swipe reveals 4 actions; vote shows instant color+count change; save toggles; share opens system sheet |
| 10 | Scroll Position Preservation | 1. User scrolls feed → 2. Switches to another app → 3. Returns to Scrollit → 4. Feed is at same position | ScrollView offset value | FeedViewModel.saveScrollPosition() records offset; restores on appear | Same scroll position as before leaving | UserDefaults (scroll offset per subreddit+sort) | Position preserved after app backgrounding; position preserved after tab switching |
| 11 | Search | 1. User taps Search tab → 2. Types query → 3. Results show subreddits and posts | Search query string | SearchViewModel calls Reddit API search endpoint | List of matching subreddits and posts | Cache (5-min TTL) | Search returns relevant results; both subreddits and posts shown; tapping result navigates correctly |
| 12 | Dark Mode | 1. User changes system appearance → 2. App adapts automatically | System appearance setting | SwiftUI automatic dark mode support | Themed UI with correct colors | System setting (no app-specific storage needed) | All views adapt to dark/light mode; colors match design spec; OLED-black background in dark mode |
| 13 | IAP Subscription (Scrollit Pro) | 1. User taps "Go Pro" → 2. Subscription sheet appears → 3. 7-day free trial offered → 4. User subscribes → 5. Pro features unlocked | Subscription selection (monthly/yearly) | StoreKit 2 handles purchase; SubscriptionManager verifies status | Pro feature access granted | StoreKit receipt + UserDefaults (cached status) | Free trial activates; monthly $1.99 and yearly $14.99 options work; pro features unlock immediately |
| 14 | Profile & Settings | 1. User taps Profile tab → 2. Views account info (if logged in) → 3. Accesses settings (theme, content filters, about) | Settings toggles, filter rules | SettingsViewModel manages UserDefaults; ContentFilter applies rules | Updated settings; filtered feed content | UserDefaults (settings); GRDB (filter rules) | Settings persist; content filters work; about page shows version + links |
| 15 | Content Filtering | 1. User opens Settings → 2. Adds keyword/subreddit filter → 3. Feed excludes matching posts | Filter rules (keyword, subreddit, NSFW toggle) | FeedViewModel applies filters before displaying posts | Filtered post list | GRDB (filter rules) | Filtered posts do not appear in feed; NSFW toggle works; keyword filter matches post titles |

### Sub-Features & Detail Interactions

| # | Parent Feature | Sub-Feature | Detail Description | Interaction Pattern |
|---|---------------|-------------|-------------------|--------------------|
| 1.1 | Anonymous Browsing | Local Subscription Management | User can add/remove subreddits to a local subscription list without Reddit account | Tap + button, type subreddit name, add to list |
| 1.2 | Anonymous Browsing | Local Vote Recording | Votes are recorded locally only (not sent to Reddit) when in anonymous mode | Swipe left, tap upvote/downvote |
| 2.1 | Feed Sorting | Sort Icon Display | Each sort has a unique SF Symbol: Hot=flame.fill, New=clock.fill, Top=chart.bar.fill, Rising=arrow.up.right | Menu selection |
| 4.1 | OAuth2 Login | Token Refresh | Access token auto-refreshes using refresh token when expired | Automatic, transparent to user |
| 4.2 | OAuth2 Login | Multi-Account Switching | Logged-in users can switch between multiple Reddit accounts | Profile tab → account selector |
| 5.1 | Post Detail | Cross-Subreddit Navigation | Tapping subreddit name in post detail navigates to that subreddit's feed | Tap on r/subreddit label |
| 5.2 | Post Detail | Share Post | Share button opens system share sheet with Reddit permalink | Tap share icon |
| 6.1 | Comment System | Comment Sort | Sort comments by Best/Top/New/Controversial/Old | Sort picker in comment header |
| 6.2 | Comment System | Comment Depth Limit | Only load comments up to depth 4 to reduce API usage | Automatic, configured in API call |
| 7.1 | Media Viewer (Image) | Image Preloading | Preload next 2 posts' images while scrolling for zero-wait experience | Automatic, triggered by scroll position |
| 8.1 | Media Viewer (Video) | GIF Loop | Short videos and GIFs auto-loop using AVPlayerLooper | Automatic playback |
| 8.2 | Media Viewer (Video) | Playback Speed | User can change video playback speed (0.5x, 1x, 1.5x, 2x) | Long-press or speed button |
| 9.1 | Swipe Actions | Vote Debouncing | Rapid consecutive votes only send the last one to API | Automatic, 0.5s debounce timer |
| 10.1 | Scroll Position | Post Read Marking | Posts that have been scrolled past are visually dimmed to indicate "read" | Automatic, based on scroll position |
| 13.1 | IAP Subscription | Free Tier Limits | Anonymous users see occasional "Go Pro" banner; no hard paywall for browsing | Non-intrusive banner |
| 13.2 | IAP Subscription | Subscription Restore | User can restore previous purchases on new device | Settings → Restore Purchases |
| 15.1 | Content Filtering | NSFW Blur | NSFW content is blurred by default with tap-to-reveal | Toggle in settings + tap to reveal |

### Cross-Feature Dependencies

| Dependency | Source Feature | Target Feature | Data Passed | Trigger Condition |
|------------|---------------|----------------|-------------|-------------------|
| Login enables voting | OAuth2 Login | Swipe Actions | Auth token | User is logged in |
| Login enables commenting | OAuth2 Login | Comment System | Auth token | User is logged in |
| Login enables posting | OAuth2 Login | Post Detail | Auth token | User is logged in |
| Subscription gates Pro | IAP Subscription | OAuth2 Login | Subscription status | User attempts login (Pro feature) |
| Filters affect feed | Content Filtering | Feed Sorting | Filter rules | Feed loads or refreshes |
| Cache serves offline | Anonymous Browsing | Feed Sorting | Cached post data | Network unavailable |
| Scroll position per feed | Scroll Position | Feed Sorting | Offset per sort+subreddit | User switches sort or subreddit |
| Read marks from scroll | Scroll Position | Feed Sorting | Read post IDs | User scrolls past posts |

## Apple Design Guidelines Compliance

- **Tab Bar (HIG)**: 3-tab design (Home, Search, Profile) follows Apple's recommendation for concise tab labels and SF Symbol icons. No overflow tabs.
- **Navigation (HIG)**: Uses NavigationStack for hierarchical navigation; back gesture via right-edge swipe (iOS native).
- **Gestures (HIG)**: Unified swipe-down-to-dismiss for media viewers ensures consistency — addresses Apple's guideline that similar operations should use similar gestures.
- **Dark Mode (HIG)**: Full support with semantic colors; OLED-black (#000000) background for dark mode.
- **Accessibility (HIG)**: All interactive elements have accessibility labels; VoiceOver support for post content and vote actions.
- **Privacy (HIG)**: Privacy manifest required for Kingfisher SDK; app collects minimal data (only Reddit OAuth tokens in Keychain).
- **App Store Review 5.2.2**: Third-party service — app uses Reddit's public and OAuth2 APIs with proper attribution. Not affiliated with Reddit Inc.
- **App Store Review 3.1.1**: IAP subscription for Pro features (login, vote, comment) follows Apple's in-app purchase requirements.
- **App Store Review 4.7**: App is a native iOS app (not HTML5 wrapper), so mini-app guidelines do not apply.

## Technical Architecture

- **Language**: Swift 5.9+
- **Framework**: SwiftUI (primary), UIKit (ASWebAuthenticationSession only)
- **Architecture**: MVVM (Model-View-ViewModel) with @Observable
- **Data Persistence**: SwiftData (primary), GRDB.swift (anonymous mode local data), Keychain (tokens)
- **Networking**: URLSession native (primary), Alamofire (complex scenarios)
- **Image Loading**: Kingfisher (3-tier cache + preloading + GIF support)
- **Video**: AVKit/AVPlayer with AVPlayerLooper for GIF/short video
- **Authentication**: ASWebAuthenticationSession with OAuth2 PKCE flow
- **IAP**: StoreKit 2
- **Concurrency**: async/await + Actor (no Combine)
- **State Management**: @Observable + @State (SwiftUI Observation framework)
- **Minimum iOS**: 17.0

## Module Structure

```
Scrollit/
├── ScrollitApp.swift
├── Models/
│   ├── Post.swift
│   ├── Comment.swift
│   ├── Subreddit.swift
│   ├── UserProfile.swift
│   └── FilterRule.swift
├── Services/
│   ├── RedditAPIService.swift
│   ├── AuthService.swift
│   ├── TokenManager.swift
│   ├── RateLimiter.swift
│   ├── CacheManager.swift
│   ├── SubscriptionManager.swift
│   └── ContentFilterService.swift
├── ViewModels/
│   ├── FeedViewModel.swift
│   ├── PostDetailViewModel.swift
│   ├── CommentViewModel.swift
│   ├── SearchViewModel.swift
│   ├── ProfileViewModel.swift
│   └── SettingsViewModel.swift
├── Views/
│   ├── MainTabView.swift
│   ├── Feed/
│   │   ├── FeedView.swift
│   │   ├── PostRowView.swift
│   │   └── PostSwipeActions.swift
│   ├── Detail/
│   │   ├── PostDetailView.swift
│   │   ├── CommentView.swift
│   │   └── CommentRowView.swift
│   ├── Media/
│   │   ├── ImageViewer.swift
│   │   ├── VideoPlayerView.swift
│   │   └── GIFPlayerView.swift
│   ├── Search/
│   │   └── SearchView.swift
│   ├── Profile/
│   │   ├── ProfileView.swift
│   │   └── LoginView.swift
│   ├── Settings/
│   │   ├── SettingsView.swift
│   │   ├── FilterSettingsView.swift
│   │   └── SubscriptionView.swift
│   └── Components/
│       ├── LoadingView.swift
│       ├── ErrorView.swift
│       └── EmptyStateView.swift
├── Helpers/
│   ├── Constants.swift
│   ├── Extensions.swift
│   └── ErrorHandler.swift
└── Resources/
    ├── Assets.xcassets
    └── Localizable.xcstrings
```

## Data Flow Diagrams

### Feature 1: Anonymous Browsing
```
User Input
└── App opens (no action required)
     │
ViewModel Processing
└── FeedViewModel.loadFeed() → RedditAPIService.getFeed() → public API (www.reddit.com)
     │
Model/Persistence
└── Post objects created from JSON → GRDB cache (5-min TTL)
     │
Display Output
└── FeedView renders LazyVStack of PostRowView items
     │
Cross-Feature Output
└── Cached posts available for offline access; read marks tracked
```

### Feature 2: OAuth2 Login
```
User Input
└── User taps "Login with Reddit" button
     │
ViewModel Processing
└── AuthService.login() → ASWebAuthenticationSession → PKCE code exchange → TokenManager.saveTokens()
     │
Model/Persistence
└── Access token + refresh token → Keychain (secure storage)
     │
Display Output
└── Profile tab shows user avatar + username; Pro features unlocked
     │
Cross-Feature Output
└── Token available to RedditAPIService for authenticated requests (vote, comment, post)
```

### Feature 3: Feed with Swipe Actions
```
User Input
└── User swipes left on post row → taps vote/save/share
     │
ViewModel Processing
└── FeedViewModel.vote() → optimistic UI update → RedditAPIService.vote() → on failure: rollback
     │
Model/Persistence
└── Post.isLiked + Post.score updated in memory → SwiftData sync
     │
Display Output
└── Vote count animates with spring; arrow changes color (orange up, blue down)
     │
Cross-Feature Output
└── Vote state synced to Reddit servers; local state preserved for anonymous mode
```

### Feature 4: Media Viewer
```
User Input
└── User taps image/video in post → views media → swipes down to dismiss
     │
ViewModel Processing
└── Image: Kingfisher loads (memory cache → disk cache → network)
    Video: AVPlayer initializes with HLS URL → auto-play muted
     │
Model/Persistence
└── Image: Kingfisher disk cache (7-day retention)
    Video: No persistent cache (streaming)
     │
Display Output
└── Image: progressive load, pinch-zoom, double-tap fullscreen
    Video: muted autoplay, tap unmute, progress bar, speed control
     │
Cross-Feature Output
└── Preloaded next 2 images for smooth scrolling; unified swipe-down dismiss gesture
```

### Feature 5: Comment System
```
User Input
└── User taps comment to expand/collapse → swipes to vote → taps reply
     │
ViewModel Processing
└── CommentViewModel loads tree → parseCommentTree() builds hierarchy
    Vote: optimistic update + API call
    Reply: submit via API → insert into tree
     │
Model/Persistence
└── Comment objects with depth + replies relationship → SwiftData
     │
Display Output
└── Threaded comment view with indentation; collapse hides children; vote shows instant feedback
     │
Cross-Feature Output
└── New reply appears in thread; vote state synced; sort order applied
```

### Feature 6: IAP Subscription
```
User Input
└── User taps "Go Pro" or attempts Pro feature → subscribes via StoreKit sheet
     │
ViewModel Processing
└── SubscriptionManager.purchase() → StoreKit 2 API → verify transaction → update status
     │
Model/Persistence
└── Subscription status → UserDefaults (cached); StoreKit receipt (server-verified)
     │
Display Output
└── Pro badge appears; login/vote/comment features unlocked; banner removed
     │
Cross-Feature Output
└── All Pro features check SubscriptionManager.isPro before enabling; restore purchases available
```

## Implementation Flow

1. Create Xcode project with SwiftUI App template, configure bundle ID `com.zzoutuo.Scrollit`, minimum iOS 17.0
2. Add Swift Package dependencies: Kingfisher, GRDB.swift
3. Implement data models: Post, Comment, Subreddit, UserProfile, FilterRule (SwiftData + GRDB)
4. Implement service layer: RedditAPIService (URLSession), AuthService (OAuth2 PKCE), TokenManager (Keychain), RateLimiter, CacheManager, SubscriptionManager (StoreKit 2), ContentFilterService
5. Implement FeedViewModel with anonymous browsing + authenticated mode + optimistic updates
6. Build FeedView with LazyVStack, PostRowView, swipe actions, pull-to-refresh, infinite scroll
7. Build PostDetailView with content display + comment tree
8. Build Media viewers: ImageViewer (Kingfisher + zoom) + VideoPlayerView (AVPlayer + unified gestures)
9. Build SearchView with subreddit + post search
10. Build ProfileView + LoginView (OAuth2 flow)
11. Build SettingsView with filters, subscription, about
12. Implement scroll position preservation (UserDefaults per feed context)
13. Implement IAP subscription flow with StoreKit 2
14. Implement MainTabView with 3 tabs (Home, Search, Profile)
15. Add dark mode support with semantic colors
16. Add accessibility labels to all interactive elements
17. Test on iPhone and iPad simulators
18. Prepare App Store metadata and submit

## UI/UX Design Specifications

### Color Scheme

**Light Mode**:
- Background: #FFFFFF (pure white)
- Surface: #F2F2F7 (iOS system gray)
- Text Primary: #000000 (pure black)
- Text Secondary: #8E8E93 (iOS system gray)
- Accent: #FF4500 (Reddit orange)
- Upvote: #FF4500 (Reddit orange)
- Downvote: #7193FF (Reddit blue)

**Dark Mode**:
- Background: #000000 (OLED-friendly pure black)
- Surface: #1C1C1E (iOS system dark gray)
- Text Primary: #FFFFFF (pure white)
- Text Secondary: #8E8E93 (iOS system gray)
- Accent: #FF6B35 (bright Reddit orange for dark backgrounds)
- Upvote: #FF6B35 (bright Reddit orange)
- Downvote: #7193FF (Reddit blue)

### Typography

| Usage | Font | Size | Weight |
|-------|------|------|--------|
| Post title | SF Pro | 17pt | Semibold |
| Post body | SF Pro | 15pt | Regular |
| Comment content | SF Pro | 15pt | Regular |
| Meta info (score/time) | SF Pro | 13pt | Regular |
| Subreddit name | SF Pro | 13pt | Medium |
| Tab label | SF Pro | 10pt | Medium |
| Large title | SF Pro | 34pt | Bold |

### Layout

- Navigation bar: 44pt height, inline title style
- Tab bar: 49pt height, 3 tabs (Home, Search, Profile)
- Card spacing: 1pt separator lines (not large gaps)
- Card horizontal padding: 16pt
- Card internal spacing: 8pt
- Image corner radius: 12pt
- Card corner radius: 0pt (full-width, borderless cards)
- Image max height in feed: 300pt
- Safe area respected on all edges

### Animations

| Interaction | Animation | Duration | Curve |
|-------------|-----------|----------|-------|
| Post tap | Shared element transition (title + image) | 0.35s | spring |
| Swipe actions | Action buttons slide in from left | 0.2s | easeOut |
| Vote | Number bounce + color change | 0.15s | spring |
| Pull-to-refresh | Custom rotation animation | 0.3s | linear |
| Tab switch | Fade in/out | 0.2s | easeInOut |
| Comment collapse | Height animation | 0.25s | easeInOut |
| Media dismiss | Swipe-down scale + fade | 0.3s | spring |

### App Icon

- Design concept: "Flowing S" — a white S-shaped scroll curve on Reddit orange gradient background (#FF4500 → #FF6B35)
- iOS standard rounded rectangle
- No text, pure graphic for internationalization
- Dark mode variant: dark background + bright S curve

## Code Generation Rules

- Strict MVVM: View → ViewModel → Service → API/Cache
- Concurrency: async/await + Actor, no callback hell, no Combine
- State: @Observable + @State (SwiftUI Observation framework)
- Persistence: SwiftData (primary) + GRDB (anonymous local data) + Keychain (tokens)
- Networking: URLSession native (preferred), Alamofire only for complex scenarios
- Images: Kingfisher (3-tier cache + preloading + GIF)
- Errors: Unified Error enum with user-friendly descriptions
- Naming: English, camelCase, Service suffix, ViewModel suffix
- UI: Pure SwiftUI, no UIKit mixing (except ASWebAuthenticationSession)
- Minimum iOS: 17.0
- Localization: LocalizedStringKey for all user-visible strings
- Accessibility: Accessibility labels on all interactive elements
- No code comments unless explicitly requested

## Build & Deployment Checklist

1. Verify Xcode project builds without errors for iPhone + iPad
2. Test anonymous browsing flow end-to-end
3. Test OAuth2 login flow with Reddit sandbox
4. Test IAP subscription flow with StoreKit testing
5. Verify scroll position preservation after backgrounding
6. Verify dark mode on all views
7. Verify VoiceOver on critical flows
8. Run on iPhone 15 Pro simulator (primary target)
9. Run on iPad simulator (verify layout adaptation)
10. Archive for App Store distribution
11. Submit with App Store metadata
12. Monitor TestFlight feedback before public release

## GitHub Reference Projects

| Project | URL | Reusable Components | License |
|---------|-----|-------------------|---------|
| Infinity for Reddit iOS | https://github.com/foxanastudio/Infinity-For-Reddit-iOS | Alamofire networking, GRDB persistence, anonymous mode, filtering | GPL-3.0 |
| Winston | https://github.com/lo-cafe/winston | SwiftUI component patterns, multi-platform architecture, i18n | GPL-3.0 |
| reddit-swiftui | https://github.com/carson-katri/reddit-swiftui | Cross-platform architecture reference | Unconfirmed |
