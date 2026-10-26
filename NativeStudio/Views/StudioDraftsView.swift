import SwiftUI

@MainActor
struct StudioDraftsView: View {
    @ObservedObject var drafts: DraftStore
    let isUnlocked: Bool
    let onNew: () -> Void
    let onOpen: (PixelDocument) -> Void
    let onUnlock: () -> Void
    @State private var deleting: PixelDocument?
    @State private var confirmDelete = false
    @State private var renaming: PixelDocument?
    @State private var share: StudioSharePayload?
    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your tiny ideas").font(.system(.title2, design: .rounded).weight(.bold))
                        Text("Saved here. Ready for another message.").font(.subheadline).foregroundColor(StudioTheme.secondary)
                    }
                    Spacer()
                }
                if !isUnlocked {
                    StudioNotice(text: "Your drawings are safe. Restore or unlock Studio to keep editing.", symbol: "lock")
                    Button("Unlock Studio", action: onUnlock).buttonStyle(StudioPrimaryButton()).accessibilityIdentifier("studio.unlock")
                }
                if isUnlocked {
                    Button(action: onNew) { Label("New drawing", systemImage: "plus") }
                        .buttonStyle(StudioPrimaryButton()).accessibilityIdentifier("studio.newDrawing")
                }
                if drafts.drafts.isEmpty {
                    StudioEmptyState(symbol: "square.and.pencil", title: "Your first sticker starts here", detail: "Make something tiny. We'll save it as you draw.")
                } else {
                    ForEach(drafts.drafts.sorted { $0.updatedAt > $1.updatedAt }) { document in
                        draftRow(document)
                    }
                }
                Text("Drawings stay on this device. Export any you want to keep before deleting the app.")
                    .font(.footnote).foregroundColor(StudioTheme.secondary).padding(.top, 6)
            }.padding(18).frame(maxWidth: 680).frame(maxWidth: .infinity)
        }
        .sheet(item: $renaming) { document in
            DraftNameSheet(document: document) { updated in
                try drafts.save(updated)
                renaming = nil
            }
        }
        .sheet(item: $share) { payload in StudioShareSheet(url: payload.url) }
        .alert("Delete this drawing?", isPresented: $confirmDelete) {
            Button("Keep drawing", role: .cancel) { deleting = nil }
            Button("Delete", role: .destructive) { deleteSelected() }
        } message: { Text("“\(deleting?.title ?? "This drawing")” will be removed from this device.") }
        .alert("Couldn't complete that", isPresented: $showError) { Button("OK", role: .cancel) {} } message: { Text(errorMessage ?? "Please try again.") }
    }

    private func draftRow(_ document: PixelDocument) -> some View {
        HStack(spacing: 12) {
            Button { onOpen(document) } label: {
                HStack(spacing: 13) {
                    Image(uiImage: PixelRenderer.image(for: document)).interpolation(.none).resizable().scaledToFit()
                        .frame(width: 70, height: 70).background(StudioTheme.lavender).clipShape(RoundedRectangle(cornerRadius: 12))
                    VStack(alignment: .leading, spacing: 6) {
                        Text(document.title).font(.system(.headline, design: .rounded)).foregroundColor(StudioTheme.ink)
                        HStack(spacing: 4) { Text("Edited"); Text(document.updatedAt, style: .relative) }
                            .font(.caption).foregroundColor(StudioTheme.secondary)
                    }
                    Spacer(minLength: 0)
                }
            }.buttonStyle(PlainButtonStyle())
                .accessibilityLabel("Open drawing \(document.title)")
                .accessibilityIdentifier("studio.draft.\(document.id.uuidString)")
            Menu {
                if isUnlocked {
                    Button { renaming = document } label: { Label("Rename", systemImage: "pencil") }
                    Button { duplicate(document) } label: { Label("Duplicate", systemImage: "plus.square.on.square") }
                }
                Button { export(document) } label: { Label("Export PNG", systemImage: "square.and.arrow.up") }
                Button(role: .destructive) { deleting = document; confirmDelete = true } label: { Label("Delete", systemImage: "trash") }
            } label: { Image(systemName: "ellipsis").font(.title3).frame(width: 44, height: 44).foregroundColor(StudioTheme.purple) }
                .accessibilityLabel("Options for \(document.title)")
        }.padding(12).background(Color.white).clipShape(RoundedRectangle(cornerRadius: 17))
    }

    private func duplicate(_ document: PixelDocument) {
        do { let duplicate = try drafts.duplicate(document); onOpen(duplicate) }
        catch { presentError(error) }
    }
    private func export(_ document: PixelDocument) {
        do { share = StudioSharePayload(url: try PixelRenderer.exportURL(for: document)) }
        catch { presentError(error) }
    }
    private func deleteSelected() {
        guard let document = deleting else { return }
        do { try drafts.delete(id: document.id); deleting = nil }
        catch { presentError(error) }
    }
    private func presentError(_ error: Error) { errorMessage = error.localizedDescription; showError = true }
}

private struct DraftNameSheet: View {
    let document: PixelDocument
    let onSave: (PixelDocument) throws -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var saveError: String?
    init(document: PixelDocument, onSave: @escaping (PixelDocument) throws -> Void) {
        self.document = document; self.onSave = onSave
        _title = State(initialValue: document.title)
    }
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Drawing name")) {
                    TextField("A tiny masterpiece", text: $title).submitLabel(.done)
                        .onChange(of: title) { title = String($0.prefix(PixelDocument.maximumTitleLength)); saveError = nil }
                        .onSubmit(save)
                        .accessibilityIdentifier("studio.renameName")
                }
                if let saveError = saveError {
                    Section {
                        StudioNotice(text: saveError, symbol: "exclamationmark.circle", isError: true)
                            .accessibilityIdentifier("studio.renameError")
                        Button("Try saving again", action: save)
                            .accessibilityIdentifier("studio.renameRetry")
                    }
                }
            }
            .navigationTitle("Name your drawing").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save", action: save).accessibilityIdentifier("studio.renameSave") }
            }
        }.navigationViewStyle(StackNavigationViewStyle())
    }
    private func save() {
        var updated = document
        updated.title = title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Untitled sticker" : title.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.updatedAt = Date()
        do { try onSave(updated); saveError = nil }
        catch { saveError = error.localizedDescription }
    }
}
