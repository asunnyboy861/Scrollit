import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var hasAcceptedEULA = UserDefaults.standard.bool(forKey: "eula_accepted")
    @State private var showEULA = false

    var body: some View {
        Group {
            if hasAcceptedEULA {
                tabContent
            } else {
                Color(.systemBackground)
                    .ignoresSafeArea()
                    .onAppear {
                        showEULA = true
                    }
            }
        }
        .fullScreenCover(isPresented: $showEULA) {
            EULAConsentView {
                hasAcceptedEULA = true
                showEULA = false
            }
        }
    }

    private var tabContent: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                FeedView()
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(0)

            NavigationStack {
                SearchView()
            }
            .tabItem {
                Label("Search", systemImage: "magnifyingglass")
            }
            .tag(1)

            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label("Profile", systemImage: "person.fill")
            }
            .tag(2)
        }
    }
}
