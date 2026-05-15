import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false
    @State private var isLoadingApple = false
    @State private var error: String?
    @State private var appleError: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "person.badge.key.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.orange)

                Text("Sign In to Your Account")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Access voting, commenting, posting, and more")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                if let error {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                    .padding(.horizontal, 32)
                }

                if let appleError {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                        Text(appleError)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                    .padding(.horizontal, 32)
                }

                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    Task { await handleAppleSignIn(result) }
                }
                .frame(height: 50)
                .cornerRadius(12)
                .padding(.horizontal, 32)
                .disabled(isLoadingApple)

                Divider()
                    .padding(.horizontal, 32)

                Button {
                    Task { await performLogin() }
                } label: {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .controlSize(.small)
                                .tint(.white)
                        }
                        Text(isLoading ? "Signing In..." : "Continue with Reddit")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isLoading ? Color.orange.opacity(0.6) : Color.orange, in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(.white)
                }
                .padding(.horizontal, 32)
                .disabled(isLoading)

                Spacer()

                demoModeSection
            }
            .navigationTitle("Login")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isLoading || isLoadingApple)
                }
            }
            .interactiveDismissDisabled(isLoading || isLoadingApple)
        }
    }

    private var demoModeSection: some View {
        VStack(spacing: 8) {
            Text("Don't have a Reddit account?")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button {
                AuthService.shared.enableDemoMode()
                HapticManager.success()
                dismiss()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "play.circle.fill")
                    Text("Try Demo Mode")
                        .fontWeight(.medium)
                }
                .font(.subheadline)
                .foregroundStyle(.blue)
            }
        }
        .padding(.bottom, 24)
    }

    private func performLogin() async {
        isLoading = true
        error = nil

        do {
            _ = try await AuthService.shared.login()
            HapticManager.success()
            dismiss()
        } catch let authError as AuthService.AuthError {
            switch authError {
            case .cancelled:
                break
            case .sessionStartFailed:
                self.error = "Unable to open sign-in page. Please check your internet connection and try again."
            default:
                self.error = authError.errorDescription
            }
        } catch let webError as ASWebAuthenticationSessionError {
            if webError.code != .canceledLogin {
                self.error = webError.localizedDescription
            }
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) async {
        isLoadingApple = true
        appleError = nil

        switch result {
        case .success(let authorization):
            if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
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

                HapticManager.success()
                dismiss()
            }
        case .failure(let error):
            if let authError = error as? ASAuthorizationError, authError.code == .canceled {
                break
            } else {
                self.appleError = "Sign in with Apple failed: \(error.localizedDescription)"
            }
        }

        isLoadingApple = false
    }
}
