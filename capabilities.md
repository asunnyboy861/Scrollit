# Scrollit — 配置文档

生成时间：2026-05-10

---

## 一、⚠️ 手动配置（需你操作才能生效）

### 🔴 Reddit OAuth2 Client ID 配置

**影响功能**：不配置则用户无法登录 Reddit 账户，无法使用投票、评论、发帖等 Pro 功能

**已自动配置部分**：
- ✅ AuthService.swift 中 OAuth2 PKCE 流程代码已完整实现
- ✅ Constants.swift 中 `redditClientId` 字段已预留（当前值为占位符 `scrollit_app`）

**仍需手动配置**：
1. 打开 [Reddit App Preferences](https://www.reddit.com/prefs/apps)
2. 登录你的 Reddit 账号
3. 点击 **"create another app..."** 按钮
4. 填写以下信息：
   - **name**: `Scrollit`
   - **App type**: 选择 **"installed app"**
   - **description**: `Minimalist Reddit client for iOS`
   - **about url**: `https://asunnyboy861.github.io/Scrollit/`
   - **redirect uri**: `scrollit://oauth/callback`
5. 点击 **"create app"**
6. 复制生成的 Client ID（在 app 名称下方的一串字符）
7. 打开文件 `Scrollit/Scrollit/Helpers/Constants.swift`
8. 将第 10 行 `static let redditClientId = "scrollit_app"` 中的 `"scrollit_app"` 替换为你复制的 Client ID
9. 同步修改 `Scrollit/Scrollit/Services/AuthService.swift` 第 8 行 `private let clientId = "scrollit_app"` 中的值
10. ⚠️ 配置完成后需要重新 Build 验证

---

### 🔵 IAP StoreKit 配置

**影响功能**：不创建 IAP 产品则用户无法完成订阅购买，Pro 功能无法解锁

**配置步骤**：
1. 打开 [App Store Connect](https://appstoreconnect.apple.com)
2. 进入 **我的 App** → 点击 **"+"** 创建新 App（如尚未创建）
   - **平台**: iOS
   - **名称**: Scrollit
   - **主要语言**: English
   - **Bundle ID**: `com.zzoutuo.Scrollit`
   - **SKU**: `scrollit`
3. 进入 App → **功能** → **App 内购买项目**
4. 点击 **"+"** → 选择 **"自动续期订阅"**
5. 创建订阅组：
   - **组参考名称**: `Scrollit Pro`
6. 在组内创建两个订阅产品：

| 产品 | Reference Name | Product ID | 价格 |
|------|---------------|-----------|------|
| 月付 | Scrollit Pro Monthly | `com.zzoutuo.Scrollit.pro.monthly` | $1.99/月 |
| 年付 | Scrollit Pro Yearly | `com.zzoutuo.Scrollit.pro.yearly` | $14.99/年 |

7. 为每个产品填写：
   - **Subscription Display Name**: Scrollit Pro Monthly / Scrollit Pro Yearly
   - **Description**: Full Reddit access: login, vote, comment, post, and save
8. 为月付产品添加 **免费试用介绍优惠**：
   - **类型**: 免费
   - **时长**: 7 天
9. ⚠️ 创建后需要等待 Apple 审核（通常1-2小时）
10. 在 Xcode 中创建 StoreKit Configuration File 用于本地测试：
    - File → New → File → StoreKit Configuration File
    - 命名为 `StoreKitConfig.storekit`
    - 添加上述两个 Product ID
11. 在 SettingsView 中点击 **"Restore Purchases"** 验证流程

---

## 二、✅ 自动配置记录（已由系统完成，无需操作）

### Capabilities 自动配置

| Capability | 说明 | 状态 |
|------------|------|------|
| In-App Purchase | Xcode Signing & Capabilities 中已启用 StoreKit 2 | ✅ 已配置 |
| Outgoing Network Connections | Reddit API 访问和联系客服需要，默认 iOS 权限 | ✅ 已配置 |

### 后端服务

| 服务 | 说明 | 状态 |
|------|------|------|
| 联系客服后端 | Cloudflare Workers 部署，地址：`https://feedback-board.iocompile67692.workers.dev` | ✅ 已部署 |
| 政策页面 | GitHub Pages 部署，地址：`https://asunnyboy861.github.io/Scrollit/` | ✅ 已部署 |

### 代码生成

| 模块 | 说明 | 状态 |
|------|------|------|
| 核心功能 | MVVM 架构，所有功能模块已生成 | ✅ 已完成 |
| AuthService | OAuth2 PKCE 流程完整实现 | ✅ 已完成 |
| RedditAPIService | 公开 API + OAuth2 API 双通道 | ✅ 已完成 |
| SubscriptionManager | StoreKit 2 集成，Product ID 已配置 | ✅ 已完成 |
| ContactSupportView | 7 主题选择、API 对接、网络权限 | ✅ 已完成 |
| SettingsView | 政策页面链接、客服入口 | ✅ 已完成 |
| FeedView | 无限滚动、多排序、内容过滤 | ✅ 已完成 |
| PostDetailView | 评论线程、投票、内联回复 | ✅ 已完成 |
| SearchView | 搜索 subreddit 和帖子 | ✅ 已完成 |
| ProfileView | 用户资料、登录/登出 | ✅ 已完成 |
| Media Views | 图片/视频/GIF 播放器 | ✅ 已完成 |

### 部署

| 项目 | 说明 | 状态 |
|------|------|------|
| GitHub 仓库 | 代码已推送至 `asunnyboy861/Scrollit` | ✅ 已完成 |
| GitHub Pages | 政策页面已部署（从 /docs 目录） | ✅ 已完成 |
| Landing Page | 已部署（App Store ID 为占位符，上架后替换） | ✅ 已完成 |
| App Store 元数据 | keytext1.md 已生成并验证 | ✅ 已完成 |
| 定价配置 | price.md 已生成 | ✅ 已完成 |

---

## 三、能力检测详情

### Analysis

Based on operation guide analysis:
- "订阅" / "购买" / "会员" / "premium" / "$1.99/月" → In-App Purchase required
- "登录" / "OAuth2" / "Reddit账户" → Network access required (outgoing connections)
- "深色模式" / "Dark Mode" → System appearance support (no capability needed)
- "匿名浏览" / "公开API" → Network access required (already covered)
- "Keychain" / "Token" → Keychain access (default entitlement)
- "缓存" / "本地存储" → Local file storage (default entitlement)

### No Configuration Needed

- iCloud / CloudKit — no sync features
- Push Notifications — no notification features
- HealthKit — not a health app
- Location Services — no location features
- Apple Watch — no watch companion
- Background Modes — no background processing needed
- Camera / Photo Library — no photo capture
- Siri — no Siri integration
- Sign in with Apple — using Reddit OAuth2 instead

### Verification

- Build succeeded after configuration: ✅
- All entitlements correct: ✅
