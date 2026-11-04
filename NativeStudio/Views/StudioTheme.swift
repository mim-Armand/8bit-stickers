import SwiftUI
import UIKit

// Shared appearance for the Messages extension and its local test host.
enum StudioTheme {
    static let ink = Color(red: 0.19, green: 0.14, blue: 0.23)
    static let purple = Color(red: 0.40, green: 0.27, blue: 0.65)
    static let cream = Color(red: 0.98, green: 0.97, blue: 0.94)
    static let lavender = Color(red: 0.94, green: 0.91, blue: 0.98)
    static let border = Color(red: 0.85, green: 0.81, blue: 0.90)
    static let secondary = Color(red: 0.39, green: 0.35, blue: 0.43)
}

extension View {
    /// Studio uses a fixed light palette. Apply it to each presentation root:
    /// sheets do not inherit their presenter's foreground color, and otherwise
    /// dark appearance can put white system text on our cream and white cards.
    func studioAppearance() -> some View {
        foregroundColor(StudioTheme.ink)
            .accentColor(StudioTheme.purple)
            .preferredColorScheme(.light)
    }
}

struct StudioPrimaryButton: ButtonStyle {
    @Environment(\.isEnabled) private var enabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.body, design: .rounded).weight(.semibold))
            .frame(maxWidth: .infinity, minHeight: 46)
            .padding(.horizontal, 16)
            .foregroundColor(.white)
            .background(StudioTheme.purple.opacity(enabled ? (configuration.isPressed ? 0.78 : 1) : 0.4))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct StudioQuietButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.subheadline, design: .rounded).weight(.semibold))
            .padding(.horizontal, 14).frame(minHeight: 42)
            .foregroundColor(StudioTheme.purple)
            .background(StudioTheme.lavender.opacity(configuration.isPressed ? 0.7 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct StudioNotice: View {
    let text: String
    var symbol = "info.circle"
    var isError = false
    var body: some View {
        Label(text, systemImage: symbol)
            .font(.footnote)
            .foregroundColor(isError ? Color.red : StudioTheme.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(isError ? Color.red.opacity(0.07) : StudioTheme.lavender)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .accessibilityElement(children: .combine)
    }
}

struct StudioEmptyState: View {
    let symbol: String
    let title: String
    let detail: String
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: symbol).font(.system(size: 30)).foregroundColor(StudioTheme.purple)
            Text(title).font(.system(.headline, design: .rounded)).foregroundColor(StudioTheme.ink)
            Text(detail).font(.subheadline).foregroundColor(StudioTheme.secondary).multilineTextAlignment(.center)
        }.frame(maxWidth: .infinity).padding(.vertical, 30).padding(.horizontal, 20)
    }
}

struct PixelHeartMark: View {
    private let rows = ["01100110", "11111111", "11111111", "01111110", "00111100", "00011000"]
    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 0) {
                    ForEach(Array(row.enumerated()), id: \.offset) { _, character in
                        Rectangle().fill(character == "1" ? Color(red: 0.95, green: 0.30, blue: 0.43) : Color.clear)
                    }
                }
            }
        }.frame(width: 64, height: 48).accessibilityHidden(true)
    }
}

struct StudioSharePayload: Identifiable {
    let id = UUID()
    let url: URL
}

struct StudioShareSheet: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
