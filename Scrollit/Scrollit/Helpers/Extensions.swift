import SwiftUI

extension Date {
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

extension Color {
    static let redditOrange = Color(red: 255/255, green: 69/255, blue: 0/255)
    static let redditBlue = Color(red: 0/255, green: 121/255, blue: 222/255)
}

extension View {
    func onAppearOnce(perform action: @escaping () -> Void) -> some View {
        onAppear {
            Task { @MainActor in action() }
        }
    }
}
