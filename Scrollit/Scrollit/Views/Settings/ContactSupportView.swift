import SwiftUI

struct ContactSupportView: View {
    @State private var name = ""
    @State private var email = ""
    @State private var message = ""
    @State private var selectedSubject = "General"
    @State private var customSubject = ""
    @State private var isSubmitting = false
    @State private var submitResult: SubmitResult?

    private let subjects = ["General", "Feature Suggestion", "Bug Report", "Usage Question", "Performance Issue", "UI Improvement", "Other"]
    private let backendURL = "https://feedback-board.iocompile67692.workers.dev"

    private var effectiveSubject: String {
        selectedSubject == "Other" ? customSubject : selectedSubject
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                subjectSection
                nameField
                emailField
                messageField
                submitButton
                resultMessage
            }
            .padding()
        }
        .navigationTitle("Contact Support")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var subjectSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Subject")
                .font(.subheadline)
                .fontWeight(.medium)

            FlowLayout(spacing: 8) {
                ForEach(subjects, id: \.self) { subject in
                    subjectChip(subject)
                }
            }

            if selectedSubject == "Other" {
                TextField("Enter your subject", text: $customSubject)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }

    private func subjectChip(_ subject: String) -> some View {
        Button {
            selectedSubject = subject
        } label: {
            Text(subject)
                .font(.caption)
                .fontWeight(selectedSubject == subject ? .semibold : .regular)
                .foregroundStyle(selectedSubject == subject ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    selectedSubject == subject ? Color.orange : Color(.systemGray5),
                    in: RoundedRectangle(cornerRadius: 8)
                )
        }
        .buttonStyle(.plain)
    }

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Name")
                .font(.subheadline)
                .fontWeight(.medium)

            TextField("Your name", text: $name)
                .textFieldStyle(.roundedBorder)
        }
    }

    private var emailField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Email")
                .font(.subheadline)
                .fontWeight(.medium)

            TextField("your@email.com", text: $email)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .autocapitalization(.none)
        }
    }

    private var messageField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Message")
                .font(.subheadline)
                .fontWeight(.medium)

            TextField("Tell us what's on your mind...", text: $message, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(5...10)
        }
    }

    private var submitButton: some View {
        Button {
            Task { await submitFeedback() }
        } label: {
            HStack {
                if isSubmitting {
                    ProgressView()
                        .controlSize(.small)
                        .tint(.white)
                }
                Text("Submit")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(canSubmit ? Color.orange : Color.gray, in: RoundedRectangle(cornerRadius: 12))
            .foregroundStyle(.white)
        }
        .disabled(!canSubmit || isSubmitting)
    }

    private var canSubmit: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !email.trimmingCharacters(in: .whitespaces).isEmpty &&
        !message.trimmingCharacters(in: .whitespaces).isEmpty &&
        (selectedSubject != "Other" || !customSubject.trimmingCharacters(in: .whitespaces).isEmpty)
    }

    @ViewBuilder
    private var resultMessage: some View {
        if let result = submitResult {
            HStack(spacing: 8) {
                Image(systemName: result.isSuccess ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundStyle(result.isSuccess ? .green : .red)

                Text(result.message)
                    .font(.subheadline)
                    .foregroundStyle(result.isSuccess ? .green : .red)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background((result.isSuccess ? Color.green : Color.red).opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
        }
    }

    private func submitFeedback() async {
        isSubmitting = true
        submitResult = nil

        let request = FeedbackRequest(
            name: name.trimmingCharacters(in: .whitespaces),
            email: email.trimmingCharacters(in: .whitespaces),
            subject: effectiveSubject,
            message: message.trimmingCharacters(in: .whitespaces),
            app_name: "Scrollit"
        )

        do {
            let url = URL(string: "\(backendURL)/api/feedback")!
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "POST"
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.httpBody = try JSONEncoder().encode(request)

            let (_, response) = try await URLSession.shared.data(for: urlRequest)

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                submitResult = SubmitResult(isSuccess: true, message: "Thank you! Your feedback has been sent.")
                name = ""
                email = ""
                message = ""
                customSubject = ""
                selectedSubject = "General"
            } else {
                submitResult = SubmitResult(isSuccess: false, message: "Failed to send. Please try again.")
            }
        } catch {
            submitResult = SubmitResult(isSuccess: false, message: "Network error. Please check your connection.")
        }

        isSubmitting = false
    }
}

struct FeedbackRequest: Codable {
    let name: String
    let email: String
    let subject: String
    let message: String
    let app_name: String
}

struct SubmitResult {
    let isSuccess: Bool
    let message: String
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxY: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxY = y + rowHeight
        }

        return (positions, CGSize(width: maxWidth, height: maxY))
    }
}
