import SwiftUI

@MainActor
struct StudioCollectionView: View {
    @ObservedObject var catalog: CatalogStore
    @ObservedObject var drafts: DraftStore
    let onInsert: (URL, String) -> Void
    let onRemix: (StickerItem) -> Void
    @State private var query = ""
    @FocusState private var searchFocused: Bool
    @State private var category = "All"
    @State private var favoritesOnly = false
    @State private var selected: StickerItem?
    @State private var pendingRemix: StickerItem?
    @State private var pendingInsert: StickerItem?

    private var categories: [String] { ["All"] + Set(catalog.items.map(\.category)).sorted() }
    private var visibleItems: [StickerItem] {
        let search = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return catalog.items.filter { item in
            (category == "All" || item.category == category) &&
            (!favoritesOnly || drafts.favorites.contains(item.id)) &&
            (search.isEmpty || ([item.title, item.category] + item.tags).joined(separator: " ")
                .localizedStandardContains(search))
        }
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass").foregroundColor(StudioTheme.secondary)
                    TextField("Find a feeling…", text: $query)
                        .font(.body).disableAutocorrection(true)
                        .textInputAutocapitalization(.never)
                        .accessibilityIdentifier("studio.search")
                        .focused($searchFocused).submitLabel(.search)
                        .onSubmit { searchFocused = false }
                    if !query.isEmpty {
                        Button { query = "" } label: { Image(systemName: "xmark.circle.fill") }
                            .foregroundColor(StudioTheme.secondary).accessibilityLabel("Clear search")
                    }
                }.padding(11).background(Color.white).clipShape(RoundedRectangle(cornerRadius: 12))
                Button { favoritesOnly.toggle() } label: {
                    Image(systemName: favoritesOnly ? "heart.fill" : "heart")
                        .font(.title3).frame(width: 44, height: 44)
                }
                .foregroundColor(StudioTheme.purple)
                .background(favoritesOnly ? StudioTheme.lavender : Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .accessibilityLabel(favoritesOnly ? "Show all stickers" : "Show favorites")
                .accessibilityValue(favoritesOnly ? "Favorites only" : "All stickers")
                .accessibilityIdentifier("favorites-filter")
            }.padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 7) {
                    ForEach(categories, id: \.self) { name in
                        Button { category = name } label: {
                            Text(name).font(.subheadline.weight(.semibold))
                                .padding(.horizontal, 13).padding(.vertical, 9)
                                .foregroundColor(category == name ? .white : StudioTheme.secondary)
                                .background(category == name ? StudioTheme.purple : Color.white)
                                .clipShape(Capsule())
                        }
                        .accessibilityAddTraits(category == name ? [.isSelected] : [])
                        .accessibilityIdentifier("category-\(name)")
                    }
                }.padding(.horizontal, 16)
            }

            HStack {
                Text("\(visibleItems.count) \(visibleItems.count == 1 ? "sticker" : "stickers")")
                    .font(.caption.weight(.semibold)).accessibilityIdentifier("catalog-count")
                Spacer()
                Text("Always free to use").font(.caption)
            }.foregroundColor(StudioTheme.secondary).padding(.horizontal, 18)

            ScrollView {
                if let error = catalog.errorMessage {
                    StudioNotice(text: error, symbol: "exclamationmark.circle", isError: true)
                        .padding(.horizontal, 16)
                }
                if visibleItems.isEmpty {
                    StudioEmptyState(symbol: favoritesOnly ? "heart" : "magnifyingglass", title: favoritesOnly ? "Your favorites go here" : "No matching feelings yet", detail: favoritesOnly ? "Tap the heart on a sticker to keep it close." : "Try “cat”, “67”, or a different category.")
                    Button("Show all stickers") { query = ""; category = "All"; favoritesOnly = false }
                        .buttonStyle(StudioQuietButton())
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 112, maximum: 170), spacing: 10)], spacing: 10) {
                        ForEach(visibleItems) { item in
                            StickerCard(item: item, isFavorite: drafts.favorites.contains(item.id), onFavorite: { drafts.toggleFavorite(item.id) }, onPreview: { selected = item })
                        }
                    }.padding(.horizontal, 16).padding(.bottom, 18)
                }
            }
        }
        .sheet(item: $selected, onDismiss: finishSelection) { item in
            StickerDetailView(item: item, isFavorite: drafts.favorites.contains(item.id), onFavorite: { drafts.toggleFavorite(item.id) }, onInsert: { pendingInsert = item; selected = nil }, onRemix: { pendingRemix = item; selected = nil })
        }
    }

    private func finishSelection() {
        if let item = pendingRemix { pendingRemix = nil; onRemix(item) }
        if let item = pendingInsert { pendingInsert = nil; onInsert(item.resourceURL, item.title) }
    }
}

private struct StickerCard: View {
    let item: StickerItem
    let isFavorite: Bool
    let onFavorite: () -> Void
    let onPreview: () -> Void
    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topTrailing) {
                NativeStickerView(url: item.resourceURL, title: item.title, animate: item.animated)
                    .frame(height: 105).padding(.top, 7)
                Button(action: onFavorite) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: 40, height: 40)
                        .background(Color.white.opacity(0.92)).clipShape(Circle())
                }
                .foregroundColor(StudioTheme.purple)
                .accessibilityLabel("\(isFavorite ? "Unsave" : "Save") \(item.title)")
                .accessibilityIdentifier("favorite-\(item.id)")
            }.background(StudioTheme.lavender.opacity(0.65))
            Button(action: onPreview) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title).font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .lineLimit(2).foregroundColor(StudioTheme.ink)
                    Text(item.animated ? "Animated · Details" : item.logicalSize == [16, 16] ? "Details & remix" : "Details")
                        .font(.caption2).foregroundColor(StudioTheme.secondary)
                }.frame(maxWidth: .infinity, minHeight: 45, alignment: .leading).padding(10)
            }.accessibilityLabel("Preview \(item.title)").accessibilityIdentifier("preview-\(item.id)")
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 15).stroke(StudioTheme.border.opacity(0.5), lineWidth: 1))
    }
}

private struct StickerDetailView: View {
    let item: StickerItem
    let isFavorite: Bool
    let onFavorite: () -> Void
    let onInsert: () -> Void
    let onRemix: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    NativeStickerView(url: item.resourceURL, title: item.title, animate: item.animated)
                        .frame(width: 220, height: 220).padding(20)
                        .background(StudioTheme.lavender).clipShape(RoundedRectangle(cornerRadius: 24))
                    VStack(spacing: 6) {
                        Text(item.title).font(.system(.title2, design: .rounded).weight(.bold))
                        Text(item.animated ? "Included animated sticker" : "Included sticker · free to use")
                            .font(.subheadline).foregroundColor(StudioTheme.secondary)
                    }
                    Button(action: onInsert) { Label("Insert sticker", systemImage: "arrow.up.message") }
                        .buttonStyle(StudioPrimaryButton()).accessibilityIdentifier("insert-included-sticker")
                    HStack {
                        Button(action: onFavorite) { Label(isFavorite ? "Saved" : "Favorite", systemImage: isFavorite ? "heart.fill" : "heart") }
                            .buttonStyle(StudioQuietButton())
                        if item.logicalSize == [16, 16] {
                            Button(action: onRemix) { Label("Make it yours", systemImage: "pencil.tip") }
                                .buttonStyle(StudioQuietButton()).accessibilityIdentifier("remix-sticker")
                        }
                    }
                    Text("In Messages, insertion adds the sticker to your composer. Tap Send when you're ready.")
                        .font(.footnote).foregroundColor(StudioTheme.secondary).multilineTextAlignment(.center)
                }.padding(24)
            }
            .background(StudioTheme.cream)
            .navigationTitle("Your sticker").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }.navigationViewStyle(StackNavigationViewStyle()).studioAppearance()
    }
}
