import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false
    @State private var error: String?

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

                Button {
                    Task { await performLogin() }
                } label: {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .controlSize(.small)
                                .tint(.white)
                        }
                        Text(isLoading ? "Signing In..." : "Continue")
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
            }
            .navigationTitle("Login")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isLoading)
                }
            }
            .interactiveDismissDisabled(isLoading)
        }
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
}
