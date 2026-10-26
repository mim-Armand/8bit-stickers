import Foundation
import Combine

enum PixelTool: String, CaseIterable, Identifiable {
    case pencil, eraser, fill
    var id: String { rawValue }
}

@MainActor
final class PixelEditor: ObservableObject {
    @Published var document: PixelDocument
    @Published var tool: PixelTool = .pencil
    @Published var selectedColor: Int = 1
    @Published private(set) var canUndo = false
    @Published private(set) var canRedo = false
    @Published private(set) var isDrawingStroke = false

    private var undoStack: [PixelDocument] = []
    private var redoStack: [PixelDocument] = []
    private var strokeStart: PixelDocument?
    private var lastPoint: (x: Int, y: Int)?
    private let historyLimit = 50

    init(document: PixelDocument) {
        self.document = document
    }

    func beginStroke() {
        if isDrawingStroke { endStroke() }
        strokeStart = document
        lastPoint = nil
        isDrawingStroke = true
    }

    func paint(x: Int, y: Int) {
        guard (0..<16).contains(x), (0..<16).contains(y), document.pixels.count == 256 else { return }
        let color = tool == .eraser ? 0 : selectedColor
        guard document.palette.indices.contains(color) else { return }
        if !isDrawingStroke { beginStroke() }
        if tool == .fill {
            floodFill(x: x, y: y, color: color)
        } else if let previous = lastPoint {
            drawLine(from: previous, to: (x, y), color: color)
        } else {
            document.pixels[y * 16 + x] = color
        }
        lastPoint = (x, y)
    }

    func endStroke() {
        guard let previous = strokeStart else { return }
        strokeStart = nil
        lastPoint = nil
        isDrawingStroke = false
        guard document != previous else { return }
        pushUndo(previous)
        // Publish a final document change after the gesture ends, so callers can
        // autosave one atomic document per completed stroke instead of every cell.
        document.updatedAt = Date()
    }

    func undo() {
        endStroke()
        guard let previous = undoStack.popLast() else { return }
        redoStack.append(document)
        document = previous
        document.updatedAt = Date()
        updateHistoryFlags()
    }

    func redo() {
        endStroke()
        guard let next = redoStack.popLast() else { return }
        undoStack.append(document)
        document = next
        document.updatedAt = Date()
        updateHistoryFlags()
    }

    func clear() {
        endStroke()
        guard document.pixels.contains(where: { $0 != 0 }) else { return }
        pushUndo(document)
        document.pixels = Array(repeating: 0, count: PixelDocument.cellCount)
        document.updatedAt = Date()
    }

    func rename(_ title: String) {
        endStroke()
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalized = String((trimmed.isEmpty ? "Untitled sticker" : trimmed).prefix(PixelDocument.maximumTitleLength))
        guard normalized != document.title else { return }
        pushUndo(document)
        document.title = normalized
        document.updatedAt = Date()
    }

    private func pushUndo(_ previous: PixelDocument) {
        undoStack.append(previous)
        if undoStack.count > historyLimit { undoStack.removeFirst(undoStack.count - historyLimit) }
        redoStack.removeAll()
        updateHistoryFlags()
    }

    private func updateHistoryFlags() {
        canUndo = !undoStack.isEmpty
        canRedo = !redoStack.isEmpty
    }

    private func drawLine(from start: (x: Int, y: Int), to end: (x: Int, y: Int), color: Int) {
        var x = start.x
        var y = start.y
        let dx = abs(end.x - x)
        let dy = -abs(end.y - y)
        let sx = x < end.x ? 1 : -1
        let sy = y < end.y ? 1 : -1
        var error = dx + dy
        while true {
            document.pixels[y * 16 + x] = color
            if x == end.x && y == end.y { break }
            let doubled = error * 2
            if doubled >= dy { error += dy; x += sx }
            if doubled <= dx { error += dx; y += sy }
        }
    }

    private func floodFill(x: Int, y: Int, color: Int) {
        let target = document.pixels[y * 16 + x]
        guard target != color else { return }
        var queue = [y * 16 + x]
        var cursor = 0
        document.pixels[queue[0]] = color
        while cursor < queue.count {
            let index = queue[cursor]
            cursor += 1
            let x = index % 16
            let y = index / 16
            let neighbors = [(x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)]
            for (nx, ny) in neighbors where (0..<16).contains(nx) && (0..<16).contains(ny) {
                let next = ny * 16 + nx
                if document.pixels[next] == target {
                    document.pixels[next] = color
                    queue.append(next)
                }
            }
        }
    }
}
