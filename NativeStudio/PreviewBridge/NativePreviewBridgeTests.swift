import Foundation
import CoreFoundation
import Network
import XCTest

/// A development-only mirror of the native local test app. This is a UI test runner,
/// not code included in the Messages extension or the release app.
@MainActor
final class NativePreviewBridgeTests: XCTestCase {
    func testLocalNativePreview() throws {
        guard ProcessInfo.processInfo.environment["STUDIO_NATIVE_PREVIEW_BRIDGE"] == "1" else {
            throw XCTSkip("Native preview bridge runs only when explicitly requested locally.")
        }
        executionTimeAllowance = 3_600
        continueAfterFailure = false
        let app = XCUIApplication(bundleIdentifier: "eu.armand.pixelstudio.local")
        app.launch()
        let jobs = NativePreviewJobs()
        let server = try NativePreviewHTTPServer(jobs: jobs)
        defer { jobs.stop(); server.stop() }
        try server.start()
        print("Native preview ready: http://127.0.0.1:8792")
        let stopAt = Date().addingTimeInterval(3_600)
        while Date() < stopAt {
            guard let job = jobs.next(before: min(stopAt, Date().addingTimeInterval(1))) else { continue }
            switch (job.request.method, job.request.path) {
            case ("GET", "/"):
                if let url = Bundle(for: Self.self).url(forResource: "NativePreview", withExtension: "html"),
                   let html = try? Data(contentsOf: url) {
                    job.complete(.init(status: 200, mime: "text/html; charset=utf-8", body: html))
                } else {
                    job.complete(.text(500, "NativePreview.html is missing from the UI test bundle."))
                }
            case ("GET", "/screenshot"):
                guard app.state == .runningForeground else {
                    job.complete(.text(409, "The local Studio app is not in the foreground. Relaunch it."))
                    continue
                }
                job.complete(.init(status: 200, mime: "image/png", body: app.screenshot().pngRepresentation))
            case ("POST", "/action"):
                handleAction(job, app: app)
            default:
                job.complete(.text(404, "Not found"))
            }
        }
    }

    private func handleAction(_ job: NativePreviewJob, app: XCUIApplication) {
        guard let object = try? JSONSerialization.jsonObject(with: job.request.body),
              let action = object as? [String: Any], let type = action["type"] as? String else {
            job.complete(.text(400, "Expected a JSON action.")); return
        }
        if type == "relaunch" {
            app.terminate()
            app.launch()
            job.complete(.text(200, "OK"))
            return
        }
        guard app.state == .runningForeground else {
            job.complete(.text(409, "Only the foreground local Studio app can receive actions.")); return
        }
        if type == "text" {
            guard let text = action["text"] as? String, text.count <= 500,
                  !text.unicodeScalars.contains(where: {
                      CharacterSet.controlCharacters.contains($0) && $0.value != 10
                  }),
                  let replace = boolean(action["replace"], defaultValue: true),
                  let submit = boolean(action["submit"], defaultValue: true) else {
                job.complete(.text(400, "Text must contain at most 500 characters without unsupported controls; replace and submit must be booleans.")); return
            }
            guard app.keyboards.firstMatch.exists,
                  let field = app.textFields.allElementsBoundByIndex.first(where: {
                      $0.exists && $0.isHittable
                  }) else {
                job.complete(.text(409, "Tap the native search or name field first, then enter text.")); return
            }
            field.tap()
            if replace, let currentValue = field.value as? String {
                let count = min(currentValue.count, 500)
                if count > 0 {
                    app.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: count))
                }
            }
            let entry = text + (submit ? "\n" : "")
            if !entry.isEmpty { app.typeText(entry) }
            job.complete(.text(200, "OK"))
            return
        }
        guard let x = normalized(action["x"]), let y = normalized(action["y"]) else {
            job.complete(.text(400, "x and y must be numbers between 0 and 1.")); return
        }
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: x, dy: y))
        // The bridge never addresses Messages or another app. Also refuse any Send
        // control if a future version of the local harness happens to add one.
        let point = CGPoint(x: app.frame.minX + app.frame.width * x,
                            y: app.frame.minY + app.frame.height * y)
        if app.buttons.matching(identifier: "Send").allElementsBoundByIndex.contains(where: {
            $0.exists && $0.frame.contains(point)
        }) {
            job.complete(.text(400, "Sending messages is not supported by the local preview.")); return
        }
        switch type {
        case "tap":
            start.tap()
        case "drag":
            guard let endX = normalized(action["toX"]), let endY = normalized(action["toY"]) else {
                job.complete(.text(400, "toX and toY must be numbers between 0 and 1.")); return
            }
            let end = app.coordinate(withNormalizedOffset: CGVector(dx: endX, dy: endY))
            start.press(forDuration: 0.05, thenDragTo: end)
        default:
            job.complete(.text(400, "Supported actions are tap, drag, text and relaunch.")); return
        }
        job.complete(.text(200, "OK"))
    }

    private func normalized(_ value: Any?) -> CGFloat? {
        guard let number = value as? NSNumber,
              CFGetTypeID(number) != CFBooleanGetTypeID() else { return nil }
        let value = number.doubleValue
        guard value.isFinite, (0...1).contains(value) else { return nil }
        return CGFloat(value)
    }

    private func boolean(_ value: Any?, defaultValue: Bool) -> Bool? {
        guard let value else { return defaultValue }
        guard let number = value as? NSNumber,
              CFGetTypeID(number) == CFBooleanGetTypeID() else { return nil }
        return number.boolValue
    }
}

private struct NativePreviewRequest {
    let method: String
    let path: String
    let body: Data
}

private struct NativePreviewResponse {
    let status: Int
    let mime: String
    let body: Data

    static func text(_ status: Int, _ text: String) -> Self {
        .init(status: status, mime: "text/plain; charset=utf-8", body: Data(text.utf8))
    }

    var bytes: Data {
        let reason: String
        switch status {
        case 200: reason = "OK"
        case 400: reason = "Bad Request"
        case 403: reason = "Forbidden"
        case 404: reason = "Not Found"
        case 409: reason = "Conflict"
        case 413: reason = "Payload Too Large"
        case 503: reason = "Service Unavailable"
        default: reason = "Internal Server Error"
        }
        let head = "HTTP/1.1 \(status) \(reason)\r\nContent-Type: \(mime)\r\nContent-Length: \(body.count)\r\nConnection: close\r\nCache-Control: no-store\r\nX-Content-Type-Options: nosniff\r\n\r\n"
        return Data(head.utf8) + body
    }
}

private struct NativePreviewJob {
    let request: NativePreviewRequest
    let complete: (NativePreviewResponse) -> Void
}

/// Network callbacks only enqueue work; all XCUI actions execute serially on the test thread.
private final class NativePreviewJobs {
    private let condition = NSCondition()
    private var jobs: [NativePreviewJob] = []
    private var stopped = false

    func append(_ job: NativePreviewJob) {
        condition.lock()
        if stopped {
            condition.unlock()
            job.complete(.text(503, "The native preview has stopped."))
            return
        }
        jobs.append(job)
        condition.signal()
        condition.unlock()
    }

    func next(before deadline: Date) -> NativePreviewJob? {
        condition.lock()
        defer { condition.unlock() }
        while jobs.isEmpty && !stopped {
            if !condition.wait(until: deadline) { return nil }
        }
        return jobs.isEmpty ? nil : jobs.removeFirst()
    }

    func stop() {
        condition.lock()
        stopped = true
        let remaining = jobs
        jobs.removeAll()
        condition.broadcast()
        condition.unlock()
        remaining.forEach { $0.complete(.text(503, "The native preview has stopped.")) }
    }
}

private final class NativePreviewHTTPServer {
    private let queue = DispatchQueue(label: "art.8bit.native-preview.http")
    private let ready = NSCondition()
    private let listener: NWListener
    private let jobs: NativePreviewJobs
    private var isReady = false
    private var startupError: Error?
    private var connections: [UUID: NWConnection] = [:]

    init(jobs: NativePreviewJobs) throws {
        self.jobs = jobs
        let parameters = NWParameters.tcp
        parameters.requiredLocalEndpoint = .hostPort(host: "127.0.0.1", port: 8792)
        listener = try NWListener(using: parameters)
    }

    func start() throws {
        listener.stateUpdateHandler = { [weak self] state in
            guard let self else { return }
            self.ready.lock()
            switch state {
            case .ready: self.isReady = true
            case .failed(let error): self.startupError = error
            default: break
            }
            self.ready.broadcast()
            self.ready.unlock()
        }
        listener.newConnectionHandler = { [weak self] connection in self?.accept(connection) }
        listener.start(queue: queue)
        ready.lock()
        defer { ready.unlock() }
        let deadline = Date().addingTimeInterval(10)
        while !isReady && startupError == nil {
            if !ready.wait(until: deadline) { break }
        }
        if let startupError { throw startupError }
        guard isReady else {
            throw NSError(domain: "NativePreview", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Local preview listener did not become ready."])
        }
    }

    func stop() {
        listener.cancel()
        queue.async {
            self.connections.values.forEach { $0.cancel() }
            self.connections.removeAll()
        }
    }

    private func accept(_ connection: NWConnection) {
        let id = UUID()
        connections[id] = connection
        connection.stateUpdateHandler = { [weak self] state in
            switch state {
            case .cancelled, .failed: self?.connections[id] = nil
            default: break
            }
        }
        connection.start(queue: queue)
        receive(connection, collected: Data())
    }

    private func receive(_ connection: NWConnection, collected: Data) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65_536) { [weak self] data, _, complete, error in
            guard let self else { connection.cancel(); return }
            var bytes = collected
            if let data { bytes.append(data) }
            guard bytes.count <= 32_768 else {
                self.send(.text(413, "Request too large"), on: connection); return
            }
            switch self.parse(bytes) {
            case .request(let request):
                self.jobs.append(.init(request: request, complete: { [weak self] response in
                    self?.queue.async { self?.send(response, on: connection) }
                }))
            case .failure(let response):
                self.send(response, on: connection)
            case .incomplete:
                if complete || error != nil { connection.cancel() }
                else { self.receive(connection, collected: bytes) }
            }
        }
    }

    private enum ParseResult {
        case incomplete
        case request(NativePreviewRequest)
        case failure(NativePreviewResponse)
    }

    private func parse(_ data: Data) -> ParseResult {
        guard let separator = data.range(of: Data("\r\n\r\n".utf8)) else {
            return data.count > 16_384 ? .failure(.text(400, "Headers too large")) : .incomplete
        }
        guard separator.lowerBound <= 16_384,
              let header = String(data: data[..<separator.lowerBound], encoding: .utf8) else {
            return .failure(.text(400, "Invalid headers"))
        }
        let lines = header.components(separatedBy: "\r\n")
        let first = (lines.first ?? "").split(separator: " ")
        guard first.count == 3, ["GET", "POST"].contains(String(first[0])),
              first[2] == "HTTP/1.1" || first[2] == "HTTP/1.0" else {
            return .failure(.text(400, "Invalid request"))
        }
        let method = String(first[0])
        let path = String(first[1].split(separator: "?", maxSplits: 1).first ?? "")
        guard path.hasPrefix("/") else { return .failure(.text(400, "Invalid path")) }
        var headers: [String: String] = [:]
        for line in lines.dropFirst() {
            guard let colon = line.firstIndex(of: ":") else { return .failure(.text(400, "Invalid header")) }
            let name = line[..<colon].lowercased()
            let value = line[line.index(after: colon)...].trimmingCharacters(in: .whitespaces)
            guard headers[name] == nil else { return .failure(.text(400, "Duplicate header")) }
            headers[name] = value
        }
        guard ["127.0.0.1:8792", "localhost:8792"].contains(headers["host"]?.lowercased() ?? "") else {
            return .failure(.text(403, "Local host only"))
        }
        let origins = ["http://127.0.0.1:8792", "http://localhost:8792"]
        if let origin = headers["origin"], !origins.contains(origin) {
            return .failure(.text(403, "Local origin only"))
        }
        if method == "POST", !origins.contains(headers["origin"] ?? "") {
            return .failure(.text(403, "A same-origin action is required"))
        }
        guard headers["transfer-encoding"] == nil else {
            return .failure(.text(400, "Chunked requests are not supported"))
        }
        let length: Int
        if let rawLength = headers["content-length"] {
            guard let parsed = Int(rawLength), (0...8_192).contains(parsed) else {
                return .failure(.text(400, "Invalid content length"))
            }
            length = parsed
        } else { length = 0 }
        if method == "POST", headers["content-type"]?.lowercased().hasPrefix("application/json") != true {
            return .failure(.text(400, "Actions require application/json"))
        }
        let available = data.count - separator.upperBound
        guard available >= length else { return .incomplete }
        guard available == length else { return .failure(.text(400, "Unexpected request body")) }
        return .request(.init(method: method, path: path, body: Data(data[separator.upperBound...])))
    }

    private func send(_ response: NativePreviewResponse, on connection: NWConnection) {
        connection.send(content: response.bytes, completion: .contentProcessed { _ in connection.cancel() })
    }
}
