import SwiftUI

struct ReportContentView: View {
    let postId: String
    let postAuthor: String
    let postTitle: String
    @Environment(\.dismiss) private var dismiss
    @State private var selectedReason: ReportReason?
    @State private var additionalDetails = ""
    @State private var isSubmitting = false
    @State private var didSubmit = false

    enum ReportReason: String, CaseIterable {
        case sexualContent = "Sexual Content or Nudity"
        case hateSpeech = "Hate Speech or Discrimination"
        case harassment = "Harassment or Bullying"
        case violence = "Violence or Threats"
        case illegalContent = "Illegal Content"
        case spam = "Spam or Misleading"
        case other = "Other"

        var icon: String {
            switch self {
            case .sexualContent: return "hand.raised"
            case .hateSpeech: return "exclamationmark.triangle"
            case .harassment: return "person.crop.circle.badge.xmark"
            case .violence: return "flame"
            case .illegalContent: return "lock.shield"
            case .spam: return "trash"
            case .other: return "questionmark.circle"
            }
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if didSubmit {
                    submittedView
                } else {
                    reportForm
                }
            }
            .navigationTitle("Report Content")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var reportForm: some View {
        Form {
            Section("Post by u/\(postAuthor)") {
                Text(postTitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Section("Select a Reason") {
                ForEach(ReportReason.allCases, id: \.self) { reason in
                    Button {
                        selectedReason = reason
                    } label: {
                        HStack {
                            Image(systemName: reason.icon)
                                .foregroundStyle(.secondary)
                                .frame(width: 24)
                            Text(reason.rawValue)
                                .foregroundStyle(.primary)
                            Spacer()
                            if selectedReason == reason {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
            }

            Section("Additional Details (Optional)") {
                TextField("Tell us more...", text: $additionalDetails, axis: .vertical)
                    .lineLimit(3...6)
            }

            Section {
                Button {
                    submitReport()
                } label: {
                    HStack {
                        if isSubmitting {
                            ProgressView()
                                .controlSize(.small)
                        }
                        Text("Submit Report")
                    }
                    .frame(maxWidth: .infinity)
                }
                .disabled(selectedReason == nil || isSubmitting)
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
        }
    }

    private var submittedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 50))
                .foregroundStyle(.green)

            Text("Report Submitted")
                .font(.title3)
                .fontWeight(.bold)

            Text("Thank you for reporting this content. We review all reports within 24 hours and will take appropriate action.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button("Done") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
        }
        .padding()
    }

    private func submitReport() {
        isSubmitting = true

        guard let reason = selectedReason else { return }

        let report: [String: String] = [
            "post_id": postId,
            "post_author": postAuthor,
            "post_title": postTitle,
            "reason": reason.rawValue,
            "details": additionalDetails,
            "app_name": "Scrollit",
            "reported_at": ISO8601DateFormatter().string(from: Date())
        ]

        Task {
            do {
                let url = URL(string: "\(Constants.feedbackBackendURL)/api/report")!
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = try JSONEncoder().encode(report)

                let (_, response) = try await URLSession.shared.data(for: request)
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    didSubmit = true
                } else {
                    saveReportLocally(report)
                    didSubmit = true
                }
            } catch {
                saveReportLocally(report)
                didSubmit = true
            }

            isSubmitting = false
        }
    }

    private func saveReportLocally(_ report: [String: String]) {
        var reports = UserDefaults.standard.array(forKey: "pending_reports") as? [[String: String]] ?? []
        reports.append(report)
        UserDefaults.standard.set(reports, forKey: "pending_reports")
    }
}
