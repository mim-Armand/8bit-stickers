import SwiftUI

@MainActor
struct StudioEditorView: View {
    @StateObject private var editor: PixelEditor
    @ObservedObject var drafts: DraftStore
    let isUnlocked: Bool
    let isExpanded: Bool
    let onExpand: () -> Void
    let onBack: () -> Void
    let onInsert: (URL, String) -> Void
    let onUnlock: () -> Void
    @State private var name: String
    @State private var saveError: String?
    @State private var showClear = false
    @State private var showLeave = false
    @State private var showError = false
    @State private var operationError = ""
    @State private var share: StudioSharePayload?
    @State private var preciseControls = false
    @State private var cursorX = 0
    @State private var cursorY = 0
    @State private var viewportHeight: CGFloat = 700
    @FocusState private var nameFocused: Bool

    init(document: PixelDocument, drafts: DraftStore, isUnlocked: Bool, isExpanded: Bool, onExpand: @escaping () -> Void, onBack: @escaping () -> Void, onInsert: @escaping (URL, String) -> Void, onUnlock: @escaping () -> Void) {
        _editor = StateObject(wrappedValue: PixelEditor(document: document))
        _name = State(initialValue: document.title)
        self.drafts = drafts; self.isUnlocked = isUnlocked; self.isExpanded = isExpanded
        self.onExpand = onExpand; self.onBack = onBack; self.onInsert = onInsert; self.onUnlock = onUnlock
    }

    var body: some View {
        VStack(spacing: 0) {
            editorHeader
            if isExpanded {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        nameField
                        if !isUnlocked {
                            StudioNotice(text: "Your drawing is safe. Restore or unlock Studio to edit it again.", symbol: "lock")
                            Button("Unlock Studio", action: onUnlock).buttonStyle(StudioPrimaryButton())
                        }
                        canvas
                        tools
                        palette
                        precision
                        HStack {
                            Spacer()
                            Button("Clear canvas", role: .destructive) { showClear = true }
                                .font(.subheadline).frame(minHeight: 44).disabled(!isUnlocked)
                                .accessibilityIdentifier("studio.clear")
                        }
                        if let saveError = saveError {
                            StudioNotice(text: saveError, symbol: "exclamationmark.circle", isError: true)
                            Button("Try saving again") { _ = persist() }.buttonStyle(StudioQuietButton())
                        }
                        Text("Your work saves on this device as you draw.")
                            .font(.footnote).foregroundColor(StudioTheme.secondary)
                    }.padding(18).frame(maxWidth: 640).frame(maxWidth: .infinity)
                }
                footer
            } else {
                VStack(spacing: 12) {
                    Text("A little more room to draw.").font(.system(.headline, design: .rounded))
                    Text("Expand Studio to continue. Your current drawing stays here.")
                        .font(.subheadline).foregroundColor(StudioTheme.secondary).multilineTextAlignment(.center)
                    Button(action: onExpand) { Label("Expand editor", systemImage: "arrow.up.left.and.arrow.down.right") }
                        .buttonStyle(StudioPrimaryButton()).accessibilityIdentifier("studio.expand")
                }.padding(20)
                Spacer(minLength: 0)
            }
        }
        .background(GeometryReader { geometry in
            Color.clear.onAppear { viewportHeight = geometry.size.height }
                .onChange(of: geometry.size.height) { viewportHeight = $0 }
        })
        .onChange(of: editor.document) { _ in if !editor.isDrawingStroke { _ = persist() } }
        .onChange(of: editor.isDrawingStroke) { active in if !active { _ = persist() } }
        .onChange(of: isUnlocked) { unlocked in if !unlocked { editor.endStroke(); _ = persist() } }
        .onChange(of: editor.tool) { _ in commitName(); nameFocused = false }
        .onChange(of: nameFocused) { focused in if !focused { commitName() } }
        .onChange(of: editor.document.title) { title in if !nameFocused { name = title } }
        .onDisappear { commitName(); editor.endStroke(); _ = persist() }
        .sheet(item: $share) { payload in StudioShareSheet(url: payload.url) }
        .confirmationDialog("Clear this drawing?", isPresented: $showClear, titleVisibility: .visible) {
            Button("Clear canvas", role: .destructive) { editor.clear() }
            Button("Keep drawing", role: .cancel) {}
        } message: { Text("You can undo this while the editor stays open.") }
        .confirmationDialog("Your latest changes haven't saved.", isPresented: $showLeave, titleVisibility: .visible) {
            Button("Keep drawing", role: .cancel) {}
            Button("Leave without saving", role: .destructive, action: onBack)
        } message: { Text("You can stay here to retry saving or export a PNG first.") }
        .alert("Couldn't complete that", isPresented: $showError) { Button("OK", role: .cancel) {} } message: { Text(operationError) }
    }

    private var editorHeader: some View {
        HStack {
            Button {
                commitName(); nameFocused = false
                editor.endStroke()
                if persist() { onBack() } else { showLeave = true }
            } label: { Label("Drafts", systemImage: "chevron.left").font(.subheadline.weight(.semibold)).frame(minHeight: 44) }
                .accessibilityIdentifier("studio.backToDrafts")
            Spacer()
            HStack(spacing: 5) {
                Image(systemName: saveError == nil ? "checkmark.circle" : "exclamationmark.circle")
                Text(saveStatus)
            }.font(.caption).foregroundColor(saveError == nil ? StudioTheme.secondary : .red)
                .accessibilityElement(children: .combine).accessibilityIdentifier("studio.saveStatus")
        }.padding(.horizontal, 18)
    }

    private var saveStatus: String {
        if saveError != nil { return "Not saved" }
        if editor.isDrawingStroke { return "Drawing…" }
        if drafts.document(id: editor.document.id) != nil { return "Saved on this device" }
        return "Autosaves as you draw"
    }

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("DRAWING NAME").font(.caption2.weight(.bold)).foregroundColor(StudioTheme.secondary)
            TextField("Untitled sticker", text: $name)
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .padding(12).background(Color.white).clipShape(RoundedRectangle(cornerRadius: 12))
                .focused($nameFocused).submitLabel(.done).disabled(!isUnlocked)
                .accessibilityLabel("Drawing name").accessibilityIdentifier("studio.drawingName")
                .onChange(of: name) { value in
                    let limited = String(value.prefix(PixelDocument.maximumTitleLength))
                    if limited != value { name = limited }
                }
                .onSubmit { commitName(); nameFocused = false; _ = persist() }
        }
    }

    private var canvas: some View {
        VStack(spacing: 8) {
            PixelCanvasView(editor: editor, isEditable: isUnlocked, cursorX: $cursorX, cursorY: $cursorY, showCursor: preciseControls, onBeginDrawing: { commitName(); nameFocused = false })
                .frame(maxWidth: min(352, max(192, floor((viewportHeight - 400) / 16) * 16)))
                .frame(maxWidth: .infinity)
            HStack {
                Text("16 × 16 pixels").font(.caption.weight(.semibold))
                Spacer()
                Text("Transparent background").font(.caption)
            }.foregroundColor(StudioTheme.secondary)
        }
    }

    private var tools: some View {
        HStack(spacing: 6) {
            ForEach(PixelTool.allCases) { tool in
                Button { editor.tool = tool } label: {
                    VStack(spacing: 4) {
                        Image(systemName: toolIcon(tool)).font(.body.weight(.semibold))
                        Text(tool.rawValue.capitalized).font(.caption)
                    }.frame(maxWidth: .infinity, minHeight: 50)
                        .foregroundColor(editor.tool == tool ? .white : StudioTheme.purple)
                        .background(editor.tool == tool ? StudioTheme.purple : StudioTheme.lavender)
                        .clipShape(RoundedRectangle(cornerRadius: 11))
                }.disabled(!isUnlocked)
                    .accessibilityLabel(tool.rawValue.capitalized)
                    .accessibilityAddTraits(editor.tool == tool ? [.isSelected] : [])
                    .accessibilityIdentifier("studio.tool.\(tool.rawValue)")
            }
            Button { editor.undo() } label: { Image(systemName: "arrow.uturn.backward").frame(width: 44, height: 50) }
                .disabled(!isUnlocked || !editor.canUndo).accessibilityLabel("Undo").accessibilityIdentifier("studio.undo")
            Button { editor.redo() } label: { Image(systemName: "arrow.uturn.forward").frame(width: 44, height: 50) }
                .disabled(!isUnlocked || !editor.canRedo).accessibilityLabel("Redo").accessibilityIdentifier("studio.redo")
        }.foregroundColor(StudioTheme.purple)
    }

    private var palette: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("COLOR").font(.caption2.weight(.bold)).foregroundColor(StudioTheme.secondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 3) {
                    ForEach(Array(editor.document.palette.enumerated()), id: \.offset) { index, color in
                        if color.a > 0 {
                            Button { editor.selectedColor = index; if editor.tool == .eraser { editor.tool = .pencil } } label: {
                                Circle().fill(Color(color.uiColor)).frame(width: 29, height: 29)
                                    .overlay(Circle().stroke(Color.black.opacity(0.18), lineWidth: 1))
                                    .padding(5)
                                    .overlay(Circle().stroke(editor.selectedColor == index ? StudioTheme.purple : Color.clear, lineWidth: 2))
                                    .frame(width: 44, height: 44)
                            }.disabled(!isUnlocked)
                                .accessibilityLabel(colorDescription(color))
                                .accessibilityAddTraits(editor.selectedColor == index ? [.isSelected] : [])
                                .accessibilityIdentifier("studio.color.\(index)")
                        }
                    }
                }.padding(2)
            }
        }
    }

    private var precision: some View {
        DisclosureGroup(isExpanded: $preciseControls) {
            VStack(spacing: 9) {
                Text("Row \(cursorY + 1), column \(cursorX + 1)").font(.subheadline.monospacedDigit())
                    .accessibilityIdentifier("studio.cursorPosition")
                HStack(spacing: 9) {
                    cursorButton("Left", "arrow.left", enabled: cursorX > 0) { cursorX -= 1 }
                    cursorButton("Up", "arrow.up", enabled: cursorY > 0) { cursorY -= 1 }
                    cursorButton("Down", "arrow.down", enabled: cursorY < 15) { cursorY += 1 }
                    cursorButton("Right", "arrow.right", enabled: cursorX < 15) { cursorX += 1 }
                }
                Button(editor.tool == .eraser ? "Erase selected pixel" : editor.tool == .fill ? "Fill selected area" : "Paint selected pixel") { paintCursor() }
                    .buttonStyle(StudioQuietButton()).disabled(!isUnlocked)
                    .accessibilityIdentifier("studio.paintCursor")
            }.padding(.vertical, 10)
        } label: { Label("Precise pixel controls", systemImage: "scope").font(.subheadline.weight(.semibold)) }
        .foregroundColor(StudioTheme.purple)
    }

    private var footer: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 10) {
                Button { export() } label: { Label("Export", systemImage: "square.and.arrow.up") }
                    .buttonStyle(StudioQuietButton()).disabled(editor.document.isEmpty)
                    .accessibilityIdentifier("studio.export")
                Button { insert() } label: { Label("Insert sticker", systemImage: "arrow.up.message") }
                    .buttonStyle(StudioPrimaryButton()).disabled(!isUnlocked || editor.document.isEmpty)
                    .accessibilityIdentifier("studio.insert")
            }.padding(.horizontal, 16).padding(.vertical, 10)
        }.background(StudioTheme.cream)
    }

    private func cursorButton(_ label: String, _ icon: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) { Image(systemName: icon).frame(width: 44, height: 40).background(Color.white).clipShape(RoundedRectangle(cornerRadius: 9)) }
            .disabled(!enabled).accessibilityLabel("Move cursor \(label.lowercased())")
    }
    private func paintCursor() {
        guard isUnlocked else { return }
        editor.beginStroke(); editor.paint(x: cursorX, y: cursorY); editor.endStroke()
    }
    @discardableResult
    private func persist() -> Bool {
        // Saving existing work remains available if an entitlement is revoked mid-stroke.
        let document = editor.document
        if document.isEmpty && drafts.document(id: document.id) == nil && document.title == "Untitled sticker" { return true }
        do { try drafts.save(document); saveError = nil; return true }
        catch { saveError = error.localizedDescription; return false }
    }
    private func export() {
        commitName(); nameFocused = false; editor.endStroke()
        do { share = StudioSharePayload(url: try PixelRenderer.exportURL(for: editor.document)) }
        catch { operationError = error.localizedDescription; showError = true }
    }
    private func insert() {
        guard isUnlocked else { onUnlock(); return }
        commitName(); nameFocused = false; editor.endStroke()
        guard persist() else { return }
        do { onInsert(try PixelRenderer.exportURL(for: editor.document), editor.document.title) }
        catch { operationError = error.localizedDescription; showError = true }
    }
    private func commitName() {
        guard isUnlocked else { return }
        editor.rename(name)
        name = editor.document.title
    }
    private func toolIcon(_ tool: PixelTool) -> String {
        switch tool { case .pencil: return "pencil.tip"; case .eraser: return "eraser"; case .fill: return "drop.fill" }
    }
    private func colorDescription(_ color: PixelColor) -> String {
        let rgb = (Int(color.r) << 16) | (Int(color.g) << 8) | Int(color.b)
        let names: [Int: String] = [0x17151C: "Ink", 0xFFFDF3: "Cream", 0xFFD52A: "Yellow", 0xEBA427: "Gold", 0xFF7A23: "Orange", 0xF54D66: "Coral", 0xFF9BB9: "Pink", 0x458AFF: "Blue", 0x7ADFFF: "Cyan", 0x3DCA6B: "Green", 0x228E42: "Dark green", 0x8DE6A7: "Mint", 0xEBAA70: "Tan", 0xA76640: "Brown"]
        return names[rgb] ?? "Color red \(color.r), green \(color.g), blue \(color.b)"
    }
}

@MainActor
private struct PixelCanvasView: View {
    @ObservedObject var editor: PixelEditor
    let isEditable: Bool
    @Binding var cursorX: Int
    @Binding var cursorY: Int
    let showCursor: Bool
    let onBeginDrawing: () -> Void
    @State private var strokeActive = false

    var body: some View {
        GeometryReader { proxy in
            let side = floor(min(proxy.size.width, proxy.size.height) / 16) * 16
            Canvas { context, size in
                let cell = size.width / 16
                for y in 0..<16 {
                    for x in 0..<16 {
                        let rect = CGRect(x: CGFloat(x) * cell, y: CGFloat(y) * cell, width: cell, height: cell)
                        let background = (x + y).isMultiple(of: 2) ? Color.white : Color(red: 0.91, green: 0.89, blue: 0.94)
                        context.fill(Path(rect), with: .color(background), style: FillStyle(antialiased: false))
                        let index = editor.document.pixels[y * 16 + x]
                        if editor.document.palette.indices.contains(index) {
                            context.fill(Path(rect), with: .color(Color(editor.document.palette[index].uiColor)), style: FillStyle(antialiased: false))
                        }
                    }
                }
                var grid = Path()
                for position in 0...16 {
                    let offset = CGFloat(position) * cell
                    grid.move(to: CGPoint(x: offset, y: 0)); grid.addLine(to: CGPoint(x: offset, y: size.height))
                    grid.move(to: CGPoint(x: 0, y: offset)); grid.addLine(to: CGPoint(x: size.width, y: offset))
                }
                context.stroke(grid, with: .color(StudioTheme.ink.opacity(0.16)), lineWidth: 0.5)
                if showCursor {
                    let rect = CGRect(x: CGFloat(cursorX) * cell + 1, y: CGFloat(cursorY) * cell + 1, width: cell - 2, height: cell - 2)
                    context.stroke(Path(rect), with: .color(.white), lineWidth: 4)
                    context.stroke(Path(rect), with: .color(StudioTheme.purple), lineWidth: 2)
                }
            }
            .frame(width: side, height: side)
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0).onChanged { value in
                guard isEditable, side > 0 else { return }
                let isFirst = !strokeActive
                if isFirst { onBeginDrawing(); editor.beginStroke(); strokeActive = true }
                if editor.tool != .fill || isFirst {
                    let cell = side / 16
                    let x = min(15, max(0, Int(value.location.x / cell)))
                    let y = min(15, max(0, Int(value.location.y / cell)))
                    cursorX = x; cursorY = y; editor.paint(x: x, y: y)
                }
            }.onEnded { _ in editor.endStroke(); strokeActive = false })
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("16 by 16 pixel canvas")
            .accessibilityValue("Row \(cursorY + 1), column \(cursorX + 1)")
            .accessibilityHint("Draw with your finger, or open Precise pixel controls below.")
            .accessibilityIdentifier("studio.canvas")
            .accessibilityAdjustableAction { direction in
                let current = cursorY * 16 + cursorX
                let next: Int
                switch direction { case .increment: next = min(255, current + 1); case .decrement: next = max(0, current - 1); @unknown default: next = current }
                cursorX = next % 16; cursorY = next / 16
            }
            .accessibilityAction(named: Text("Paint selected pixel")) {
                guard isEditable else { return }
                editor.beginStroke(); editor.paint(x: cursorX, y: cursorY); editor.endStroke()
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .padding(8).background(Color.white).clipShape(RoundedRectangle(cornerRadius: 15))
        .overlay(RoundedRectangle(cornerRadius: 15).stroke(StudioTheme.border, lineWidth: 1))
        .onDisappear { editor.endStroke(); strokeActive = false }
    }
}
