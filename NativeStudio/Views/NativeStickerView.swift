import SwiftUI
import Messages

/// Keeps the system's real sticker tap/hold/peel behavior instead of emulating it with an image.
struct NativeStickerView: UIViewRepresentable {
    let url: URL
    let title: String
    var animate = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeUIView(context: Context) -> MSStickerView {
        let view = MSStickerView(frame: .zero)
        view.contentMode = .scaleAspectFit
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ view: MSStickerView, context: Context) {
        if context.coordinator.url != url {
            view.sticker = try? MSSticker(contentsOfFileURL: url, localizedDescription: String(title.prefix(150)))
            context.coordinator.url = url
        }
        view.accessibilityLabel = title
        view.accessibilityHint = "Tap to add this sticker. Touch and hold to place it in Messages."
        if animate && !reduceMotion { view.startAnimating() } else { view.stopAnimating() }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }
    final class Coordinator { var url: URL? }
}
