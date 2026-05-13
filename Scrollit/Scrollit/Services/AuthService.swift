import Foundation
import AuthenticationServices
import SwiftUI
import CommonCrypto

@MainActor
@Observable
final class AuthService {
    static let shared = AuthService()

    private let clientId = "scrollit_app"
    private let redirectURI = "scrollit://oauth/callback"
    private let scope = "identity read vote submit save history"
    private let tokenManager = TokenManager.shared

    var isLoggedIn: Bool { tokenManager.accessToken != nil }
    var currentToken: String? { tokenManager.accessToken }

    private var continuation: CheckedContinuation<URL, Error>?
    private var webAuthSession: ASWebAuthenticationSession?

    private init() {}

    func login() async throws -> String {
        let codeVerifier = generateCodeVerifier()
        let codeChallenge = generateCodeChallenge(from: codeVerifier)

        let state = UUID().uuidString
        var components = URLComponents(string: "https://www.reddit.com/api/v2/authorize")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "duration", value: "permanent"),
            URLQueryItem(name: "scope", value: scope),
            URLQueryItem(name: "code_challenge", value: codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: "S256")
        ]

        guard let authURL = components.url else {
            throw AuthError.invalidURL
        }

        let callbackURL: URL = try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation

            let session = ASWebAuthenticationSession(
                url: authURL,
                callbackURLScheme: "scrollit"
            ) { [weak self] url, error in
                Task { @MainActor [weak self] in
                    guard let self, let currentContinuation = self.continuation else { return }
                    self.continuation = nil

                    if let error {
                        if let asError = error as? ASWebAuthenticationSessionError,
                           asError.code == .canceledLogin {
                            currentContinuation.resume(throwing: AuthError.cancelled)
                        } else {
                            currentContinuation.resume(throwing: error)
                        }
                    } else if let url {
                        currentContinuation.resume(returning: url)
                    } else {
                        currentContinuation.resume(throwing: AuthError.cancelled)
                    }
                }
            }

            session.prefersEphemeralWebBrowserSession = false

            let provider = PresentationAnchorProvider()
            session.presentationContextProvider = provider

            self.webAuthSession = session

            guard session.start() else {
                self.continuation = nil
                continuation.resume(throwing: AuthError.sessionStartFailed)
                return
            }
        }

        guard let callbackComponents = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
              let codeItem = callbackComponents.queryItems?.first(where: { $0.name == "code" }),
              let code = codeItem.value else {
            throw AuthError.invalidCallback
        }

        if let stateItem = callbackComponents.queryItems?.first(where: { $0.name == "state" }),
           stateItem.value != state {
            throw AuthError.invalidCallback
        }

        return try await exchangeCode(code: code, codeVerifier: codeVerifier)
    }

    private func exchangeCode(code: String, codeVerifier: String) async throws -> String {
        var request = URLRequest(url: URL(string: "https://www.reddit.com/api/v2/access_token")!)
        request.httpMethod = "POST"

        let credentials = (clientId + ":").data(using: .utf8)?.base64EncodedString() ?? ""
        request.setValue("Basic \(credentials)", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = "grant_type=authorization_code&code=\(code)&redirect_uri=\(redirectURI.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? redirectURI)&code_verifier=\(codeVerifier)"
        request.httpBody = body.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.tokenExchangeFailed
        }

        guard httpResponse.statusCode == 200 else {
            throw AuthError.tokenExchangeFailed
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let accessToken = json["access_token"] as? String,
              let refreshToken = json["refresh_token"] as? String else {
            throw AuthError.tokenExchangeFailed
        }

        let expiresIn = json["expires_in"] as? Int ?? 3600

        tokenManager.saveTokens(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresIn: TimeInterval(expiresIn)
        )

        return accessToken
    }

    func refreshToken() async throws -> String {
        guard let refreshToken = tokenManager.refreshToken else {
            throw AuthError.noRefreshToken
        }

        var request = URLRequest(url: URL(string: "https://www.reddit.com/api/v2/access_token")!)
        request.httpMethod = "POST"

        let credentials = (clientId + ":").data(using: .utf8)?.base64EncodedString() ?? ""
        request.setValue("Basic \(credentials)", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = "grant_type=refresh_token&refresh_token=\(refreshToken)"
        request.httpBody = body.data(using: .utf8)

        let (data, _) = try await URLSession.shared.data(for: request)

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let accessToken = json["access_token"] as? String else {
            throw AuthError.refreshFailed
        }

        let expiresIn = json["expires_in"] as? Int ?? 3600
        tokenManager.saveTokens(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresIn: TimeInterval(expiresIn)
        )

        return accessToken
    }

    func logout() {
        tokenManager.clearTokens()
    }

    private func generateCodeVerifier() -> String {
        var buffer = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, buffer.count, &buffer)
        return Data(buffer).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
            .trimmingCharacters(in: .whitespaces)
    }

    private func generateCodeChallenge(from verifier: String) -> String {
        guard let data = verifier.data(using: .utf8) else { return "" }
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes { pointer in
            _ = CC_SHA256(pointer.baseAddress, CC_LONG(data.count), &hash)
        }
        return Data(hash).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    enum AuthError: LocalizedError {
        case invalidURL
        case cancelled
        case invalidCallback
        case tokenExchangeFailed
        case noRefreshToken
        case refreshFailed
        case sessionStartFailed

        var errorDescription: String? {
            switch self {
            case .invalidURL: return "Invalid authorization URL"
            case .cancelled: return "Login was cancelled"
            case .invalidCallback: return "Invalid callback response"
            case .tokenExchangeFailed: return "Failed to exchange authorization code"
            case .noRefreshToken: return "No refresh token available"
            case .refreshFailed: return "Failed to refresh access token"
            case .sessionStartFailed: return "Unable to start authentication session"
            }
        }
    }
}

final class PresentationAnchorProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            return UIWindow()
        }
        return window
    }
}
