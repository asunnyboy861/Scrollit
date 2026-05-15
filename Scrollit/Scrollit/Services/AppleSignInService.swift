import Foundation
import AuthenticationServices
import CryptoKit
import Security

@MainActor
final class AppleSignInService: NSObject {
    static let shared = AppleSignInService()
    
    private var currentNonce: String?
    private var continuation: CheckedContinuation<AppleSignInResult, Error>?
    
    private override init() {}
    
    func signIn() async throws -> AppleSignInResult {
        let nonce = randomNonceString()
        currentNonce = nonce
        
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            
            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]
            request.nonce = sha256(nonce)
            
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }
    
    func signOut() {
        UserDefaults.standard.removeObject(forKey: "apple_user_id")
        UserDefaults.standard.removeObject(forKey: "apple_email")
        UserDefaults.standard.removeObject(forKey: "apple_full_name")
    }
    
    var isLoggedIn: Bool {
        UserDefaults.standard.string(forKey: "apple_user_id") != nil
    }
    
    var userId: String? {
        UserDefaults.standard.string(forKey: "apple_user_id")
    }
    
    var email: String? {
        UserDefaults.standard.string(forKey: "apple_email")
    }
    
    var fullName: String? {
        UserDefaults.standard.string(forKey: "apple_full_name")
    }
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.map { String(format: "%02x", $0) }.joined()
    }
    
    private func handleSuccess(_ credential: ASAuthorizationAppleIDCredential) {
        let userId = credential.user
        
        UserDefaults.standard.set(userId, forKey: "apple_user_id")
        
        if let email = credential.email {
            UserDefaults.standard.set(email, forKey: "apple_email")
        }
        
        if let fullName = credential.fullName {
            let name = [fullName.givenName, fullName.familyName]
                .compactMap { $0 }
                .joined(separator: " ")
            if !name.isEmpty {
                UserDefaults.standard.set(name, forKey: "apple_full_name")
            }
        }
        
        let result = AppleSignInResult(
            userId: userId,
            email: credential.email,
            fullName: credential.fullName
        )
        
        continuation?.resume(returning: result)
        continuation = nil
        currentNonce = nil
    }
    
    private func handleError(_ error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
        currentNonce = nil
    }
}

extension AppleSignInService: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
            handleSuccess(credential)
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        handleError(error)
    }
}

extension AppleSignInService: ASAuthorizationControllerPresentationContextProviding {
    nonisolated func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            return UIWindow()
        }
        return window
    }
}

struct AppleSignInResult {
    let userId: String
    let email: String?
    let fullName: PersonNameComponents?
}
