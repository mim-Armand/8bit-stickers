import SwiftUI

@MainActor
struct StudioCollectionView: View {
    @ObservedObject var catalog: CatalogStore
    @ObservedObject var drafts: DraftStore
    let isExpanded: Bool
    let onExpand: () -> Void
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
        catalog.stickers(matching: query).filter { item in
            (category == "All" || item.category == category) &&
            (!favoritesOnly || drafts.favorites.contains(item.id))
        }
    }

    var body: some View {
        let results = visibleItems
        return VStack(spacing: isExpanded ? 10 : 4) {
            HStack(spacing: 8) {
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
                if isExpanded {
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
                } else {
                    compactFilters
                }
            }.padding(.horizontal, 16)

            if isExpanded {
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
            }

            HStack {
                Text("\(results.count) \(results.count == 1 ? "sticker" : "stickers")")
                    .font(.caption.weight(.semibold)).accessibilityIdentifier("catalog-count")
                Spacer()
                if isExpanded {
                    Text("Always free to use").font(.caption)
                } else if category != "All" || favoritesOnly {
                    Text([favoritesOnly ? "Favorites" : "", category == "All" ? "" : category].filter { !$0.isEmpty }.joined(separator: " · "))
                        .font(.caption)
                } else {
                    Text("Tap to add. Hold and drag to place.").font(.caption)
                }
            }.foregroundColor(StudioTheme.secondary).padding(.horizontal, 18)

            ScrollView {
                if let error = catalog.errorMessage {
                    StudioNotice(text: error, symbol: "exclamationmark.circle", isError: true)
                        .padding(.horizontal, 16)
                }
                if results.isEmpty {
                    StudioEmptyState(symbol: favoritesOnly ? "heart" : "magnifyingglass", title: favoritesOnly && drafts.favorites.isEmpty ? "Your favorites go here" : "No matching feelings yet", detail: favoritesOnly && drafts.favorites.isEmpty ? "Choose Favorite on a sticker to keep it here." : "Try “cat”, “67”, or a different category.")
                    Button("Show all stickers") { query = ""; category = "All"; favoritesOnly = false }
                        .buttonStyle(StudioQuietButton())
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: isExpanded ? 112 : 94, maximum: 170), spacing: 10)], spacing: 10) {
                        ForEach(results) { item in
                            StickerCard(item: item, isExpanded: isExpanded, isFavorite: drafts.favorites.contains(item.id), onFavorite: { drafts.toggleFavorite(item.id) }, onPreview: { selected = item })
                        }
                    }.padding(.horizontal, 16).padding(.bottom, 18)
                }
            }
        }
        .onChange(of: searchFocused) { focused in
            if focused && !isExpanded { onExpand() }
        }
        .sheet(item: $selected, onDismiss: finishSelection) { item in
            StickerDetailView(item: item, isFavorite: drafts.favorites.contains(item.id), onFavorite: { drafts.toggleFavorite(item.id) }, onInsert: { pendingInsert = item; selected = nil }, onRemix: { pendingRemix = item; selected = nil })
        }
    }

    private var compactFilters: some View {
        Menu {
            Toggle("Favorites only", isOn: $favoritesOnly)
            Picker("Category", selection: $category) {
                ForEach(categories, id: \.self) { name in Text(name).tag(name) }
            }
        } label: {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .font(.title3).frame(width: 44, height: 44)
                .background(category != "All" || favoritesOnly ? StudioTheme.lavender : Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .foregroundColor(StudioTheme.purple)
        .accessibilityLabel("Sticker filters")
        .accessibilityValue(favoritesOnly ? "Favorites, \(category)" : category)
        .accessibilityIdentifier("studio.filters")
    }

    private func finishSelection() {
        if let item = pendingRemix { pendingRemix = nil; onRemix(item) }
        if let item = pendingInsert { pendingInsert = nil; onInsert(item.resourceURL, item.title) }
    }
}

private struct StickerCard: View {
    let item: StickerItem
    let isExpanded: Bool
    let isFavorite: Bool
    let onFavorite: () -> Void
    let onPreview: () -> Void
    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topTrailing) {
                NativeStickerView(url: item.resourceURL, title: item.title, animate: item.animated)
                    .frame(height: isExpanded ? 105 : 66).padding(.top, isExpanded ? 7 : 2)
                if isExpanded {
                    Button(action: onFavorite) {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(width: 44, height: 44)
                            .background(Color.white.opacity(0.92)).clipShape(Circle())
                    }
                    .foregroundColor(StudioTheme.purple)
                    .accessibilityLabel("\(isFavorite ? "Unsave" : "Save") \(item.title)")
                    .accessibilityIdentifier("favorite-\(item.id)")
                }
            }.frame(maxWidth: .infinity).background(StudioTheme.lavender.opacity(0.65))
            if isExpanded {
                Button(action: onPreview) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title).font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .lineLimit(2).foregroundColor(StudioTheme.ink)
                        Text(item.animated ? "Animated · Details" : item.template != nil ? "Details & remix" : "Details")
                            .font(.caption2).foregroundColor(StudioTheme.secondary)
                    }.frame(maxWidth: .infinity, minHeight: 45, alignment: .leading).padding(10)
                }.accessibilityLabel("Preview \(item.title)").accessibilityIdentifier("preview-\(item.id)")
            } else {
                HStack(spacing: 0) {
                    Text(item.title).font(.caption.weight(.semibold))
                        .lineLimit(2).frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 6).accessibilityHidden(true)
                    Menu {
                        Button(action: onFavorite) {
                            Label(isFavorite ? "Remove from favorites" : "Favorite", systemImage: isFavorite ? "heart.slash" : "heart")
                        }
                        Button(action: onPreview) {
                            Label(item.template == nil ? "Details" : "Details & remix", systemImage: "info.circle")
                        }
                    } label: {
                        Image(systemName: "ellipsis").foregroundColor(StudioTheme.purple)
                            .frame(width: 44, height: 44).contentShape(Rectangle())
                    }
                    .accessibilityLabel("Options for \(item.title)")
                    .accessibilityIdentifier("options-\(item.id)")
                }
            }
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
