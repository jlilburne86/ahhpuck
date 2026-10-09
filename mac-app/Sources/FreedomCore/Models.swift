import Foundation

public struct FCSTSettings: Codable, Sendable {
    public var defaultPort: String = ""
    public var learningRate: Int = 40
    public var switchThresholdRPM: Int = 740
    public var latency: Double = 0
    public var stableGain: Double = 0.03
    public var accelerationStableGain: Double = 0.8

    public init() {}
}

public struct SerialConfiguration: Sendable {
    public let path: String
    public let baud: Int
    public let dataBits: Int
    public let stopBits: Int
    public let parity: Parity

    public enum Parity: Sendable { case none, even, odd }

    /// Defaults match the Freedom/FCSS link: 9600 bps, 7 data bits, even parity, 1 stop bit.
    /// Evidence: documented (hiro0719jp FCSS article). Not yet observed on this project's own captures.
    public init(path: String, baud: Int = 9600, dataBits: Int = 7, stopBits: Int = 1, parity: Parity = .even) {
        self.path = path
        self.baud = baud
        self.dataBits = dataBits
        self.stopBits = stopBits
        self.parity = parity
    }

    /// The documented Freedom FC-03 serial setting.
    public static func freedom(path: String) -> SerialConfiguration {
        SerialConfiguration(path: path, baud: 9600, dataBits: 7, stopBits: 1, parity: .even)
    }
}

public struct SerialFrame: Codable, Sendable, Equatable {
    public let timestamp: Date
    public let bytes: [UInt8]
    public let direction: Direction

    public enum Direction: String, Codable, Sendable { case rx, tx }

    public init(timestamp: Date = Date(), bytes: [UInt8], direction: Direction) {
        self.timestamp = timestamp
        self.bytes = bytes
        self.direction = direction
    }
}

public enum ECUAccessMode: Sendable { case offline, readOnly, writeArmed }

public enum FreedomError: Error, LocalizedError {
    case unsupportedBaudRate(Int)
    case invalidConfiguration(String)
    case writeBlocked(String)
    case protocolUnknown

    public var errorDescription: String? {
        switch self {
        case .unsupportedBaudRate(let value): return "Unsupported baud rate: \(value)"
        case .invalidConfiguration(let value): return "Invalid configuration: \(value)"
        case .writeBlocked(let value): return "ECU write blocked: \(value)"
        case .protocolUnknown: return "FC-03 command protocol has not yet been verified."
        }
    }
}
