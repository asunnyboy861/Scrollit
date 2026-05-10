import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = SettingsViewModel()

    var body: some View {
        List {
            appearanceSection
            contentSection
            filterSection
            aboutSection
            legalSection
        }
        .navigationTitle("Settings")
        .task {
            viewModel.loadFilterRules(modelContext: modelContext)
        }
    }

    private var appearanceSection: some View {
        Section("Appearance") {
            Toggle("Hide NSFW Content", isOn: $viewModel.hideNSFW)
        }
    }

    private var contentSection: some View {
        Section("Content") {
            NavigationLink {
                SubscriptionView()
            } label: {
                HStack {
                    Label("Scrollit Pro", systemImage: "crown.fill")
                        .foregroundStyle(.orange)
                    Spacer()
                    if viewModel.isPro {
                        Text("Active")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
            }

            Button {
                Task { await viewModel.restorePurchases() }
            } label: {
                Label("Restore Purchases", systemImage: "arrow.uturn.down")
            }
        }
    }

    private var filterSection: some View {
        Section("Content Filters") {
            NavigationLink {
                FilterSettingsView()
            } label: {
                Label("Filter Rules", systemImage: "line.3.horizontal.decrease")
            }
        }
    }

    private var aboutSection: some View {
        Section("About") {
            NavigationLink {
                ContactSupportView()
            } label: {
                Label("Contact Support", systemImage: "envelope")
            }

            HStack {
                Text("Version")
                Spacer()
                Text("\(viewModel.appVersion) (\(viewModel.buildNumber))")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var legalSection: some View {
        Section("Legal") {
            Link("Support", destination: URL(string: viewModel.supportURL)!)
            Link("Privacy Policy", destination: URL(string: viewModel.privacyURL)!)
            Link("Terms of Use", destination: URL(string: viewModel.termsURL)!)
        }
    }
}
