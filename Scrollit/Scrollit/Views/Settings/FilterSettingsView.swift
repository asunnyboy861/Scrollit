import SwiftUI
import SwiftData

struct FilterSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var newKeyword = ""
    @State private var newSubreddit = ""
    @State private var viewModel = SettingsViewModel()

    var body: some View {
        List {
            addRuleSection
            existingRulesSection
        }
        .navigationTitle("Content Filters")
        .task {
            viewModel.loadFilterRules(modelContext: modelContext)
        }
    }

    private var addRuleSection: some View {
        Section("Add Filter") {
            TextField("Keyword to filter", text: $newKeyword)

            TextField("Subreddit (optional)", text: $newSubreddit)

            Button("Add Filter") {
                guard !newKeyword.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                viewModel.addFilterRule(
                    keyword: newKeyword.trimmingCharacters(in: .whitespaces),
                    subreddit: newSubreddit.trimmingCharacters(in: .whitespaces).isEmpty ? nil : newSubreddit.trimmingCharacters(in: .whitespaces),
                    modelContext: modelContext
                )
                newKeyword = ""
                newSubreddit = ""
            }
            .disabled(newKeyword.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }

    private var existingRulesSection: some View {
        Section("Active Filters") {
            if ContentFilterService.shared.filterRules.isEmpty {
                Text("No filters added")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(ContentFilterService.shared.filterRules, id: \.keyword) { rule in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(rule.keyword)
                                .font(.subheadline)

                            if let sub = rule.targetSubreddit {
                                Text("r/\(sub)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()

                        Image(systemName: rule.isEnabled ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(rule.isEnabled ? .green : .secondary)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            viewModel.removeFilterRule(rule, modelContext: modelContext)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }
}
