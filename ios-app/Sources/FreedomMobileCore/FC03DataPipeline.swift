import Foundation

/// The recovered FCSS/FCST surface is represented as capability metadata rather
/// than guessed write commands. This lets the UI explain what exists while the
/// app only enables the read-only path that has evidence behind it.
public struct FC03Capability: Codable, Equatable, Sendable {
    public enum Area: String, Codable, Equatable, Sendable { case monitor, setup, map, learning, safety }
    public enum State: String, Codable, Equatable, Sendable { case documented, observed, unverified, locked }

    public let id: String
    public let area: Area
    public let title: String
    public let state: State
    public let detail: String

    public init(id: String, area: Area, title: String, state: State, detail: String) {
        self.id = id; self.area = area; self.title = title; self.state = state; self.detail = detail
    }
}

public enum FC03CapabilityCatalog {
    public static let all: [FC03Capability] = [
        .init(id: "dat", area: .monitor, title: "Read live data", state: .documented, detail: "?DAT request; retain raw response before decoding."),
        .init(id: "monitor", area: .monitor, title: "Monitor channels", state: .observed, detail: "RPM, throttle, MAP, temperatures, voltage, O₂ and ignition are candidates; offsets remain unverified."),
        .init(id: "maps", area: .map, title: "Fuel and ignition maps", state: .documented, detail: "FCP map and LOG artifacts are retained as reference evidence."),
        .init(id: "vvt", area: .map, title: "VVT maps", state: .unverified, detail: "Recovered controls exist; live semantics and scaling are not proven."),
        .init(id: "learning", area: .learning, title: "Learning and corrections", state: .documented, detail: "Learning, temperature, transient, latency and start/idle controls are catalogued."),
        .init(id: "limits", area: .safety, title: "Limits and protection", state: .observed, detail: "Rev limit and safety observations inform readiness; they never authorize writes."),
        .init(id: "write", area: .safety, title: "ECU writes", state: .locked, detail: "Disabled in AhhPuck regardless of recovered FCSS/FCST controls.")
    ]
}

public enum FC03FieldDecodeError: Error, LocalizedError, Sendable, Equatable {
    case mappingUnverified

    public var errorDescription: String? {
        "FC-03 field offsets and scaling are unverified; raw bytes were retained instead."
    }
}

/// Deliberately conservative decoder boundary. A future verified mapping can be
/// inserted here without changing storage, safety assessment, or UI contracts.
public struct FC03VerifiedTelemetryDecoder: Sendable {
    public init() {}

    public func decode(_ response: FC03DATResponse) throws -> MobileTelemetryFrame {
        _ = response
        throw FC03FieldDecodeError.mappingUnverified
    }
}

/// Local archive for raw sessions. It is intentionally file-backed and portable
/// so a bench capture can be exported before any cloud sync exists.
public final class FC03CaptureFileStore: @unchecked Sendable {
    public let directory: URL
    private let fileManager: FileManager

    public init(directory: URL? = nil, fileManager: FileManager = .default) {
        self.fileManager = fileManager
        self.directory = directory ?? fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("AhhPuck/FC03Captures", isDirectory: true)
    }

    @discardableResult
    public func save(_ session: FC03CaptureSession) throws -> URL {
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let name = "fc03-\(Int(session.metadata.startedAt.timeIntervalSince1970)).json"
        let url = directory.appendingPathComponent(name)
        try session.jsonData().write(to: url, options: .atomic)
        return url
    }

    public func loadLatest() throws -> FC03CaptureSession? {
        guard fileManager.fileExists(atPath: directory.path) else { return nil }
        let urls = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.contentModificationDateKey])
            .filter { $0.pathExtension == "json" }
            .sorted { $0.lastPathComponent > $1.lastPathComponent }
        guard let url = urls.first else { return nil }
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(FC03CaptureSession.self, from: data)
    }

    public func loadAll() throws -> [FC03CaptureSession] {
        guard fileManager.fileExists(atPath: directory.path) else { return [] }
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
        return try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "json" }
            .compactMap { try? decoder.decode(FC03CaptureSession.self, from: Data(contentsOf: $0)) }
            .sorted { $0.metadata.startedAt > $1.metadata.startedAt }
    }
}

/// Bench-facing read-only coordinator. The serial adapter owns bytes; this
/// coordinator owns evidence, validation and persistence. It always emits the
/// documented `?DAT` request and has no write operation.
public actor FC03CaptureCoordinator {
    private let recorder: FC03CaptureRecorder
    private let store: FC03CaptureFileStore

    public init(metadata: FC03CaptureMetadata, store: FC03CaptureFileStore = FC03CaptureFileStore()) {
        self.recorder = FC03CaptureRecorder(metadata: metadata)
        self.store = store
    }

    @discardableResult
    public func ingestDAT(response: Data, requestedAt: Date = Date(), receivedAt: Date = Date()) async -> FC03RawExchange {
        await recorder.record(request: FC03ReadOnlyProtocol.makeDATRequest(), response: response,
                              requestedAt: requestedAt, receivedAt: receivedAt)
    }

    public func finish() async throws -> URL {
        try store.save(await recorder.snapshot())
    }
}
