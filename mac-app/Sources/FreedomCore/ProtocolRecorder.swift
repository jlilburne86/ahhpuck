import Foundation

public final class ProtocolRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var frames: [SerialFrame] = []

    public init() {}

    public func append(_ frame: SerialFrame) {
        lock.lock(); defer { lock.unlock() }
        frames.append(frame)
    }

    public func snapshot() -> [SerialFrame] {
        lock.lock(); defer { lock.unlock() }
        return frames
    }

    public func writeJSON(to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(snapshot()).write(to: url, options: .atomic)
    }
}

public enum PortDiscovery {
    public static func macOSSerialPorts() -> [String] {
        let urls = (try? FileManager.default.contentsOfDirectory(
            at: URL(fileURLWithPath: "/dev"), includingPropertiesForKeys: nil
        )) ?? []
        return urls.map(\.path).filter { $0.hasPrefix("/dev/cu.") }.sorted()
    }
}
