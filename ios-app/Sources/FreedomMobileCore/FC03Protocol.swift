import Foundation

/// Serial settings recovered from the FCSS/FCST research bundle.
/// The values describe the transport only; they do not prove compatibility
/// with every FC-03 firmware revision.
public struct FC03SerialProfile: Sendable, Equatable, Codable {
    public let baudRate: Int
    public let dataBits: Int
    public let parity: Parity
    public let stopBits: Int
    public let flowControl: FlowControl

    public enum Parity: String, Sendable, Equatable, Codable { case even }
    public enum FlowControl: String, Sendable, Equatable, Codable { case none }

    public static let documented = FC03SerialProfile(
        baudRate: 9_600,
        dataBits: 7,
        parity: .even,
        stopBits: 1,
        flowControl: .none
    )

    public init(baudRate: Int, dataBits: Int, parity: Parity, stopBits: Int, flowControl: FlowControl) {
        self.baudRate = baudRate
        self.dataBits = dataBits
        self.parity = parity
        self.stopBits = stopBits
        self.flowControl = flowControl
    }
}

public enum FC03ProtocolError: Error, LocalizedError, Sendable, Equatable {
    case invalidResponseLength(actual: Int, expected: Int)
    case missingTerminator

    public var errorDescription: String? {
        switch self {
        case let .invalidResponseLength(actual, expected):
            return "FC-03 response length was \(actual) bytes; expected \(expected)."
        case .missingTerminator:
            return "FC-03 response terminator has not been verified."
        }
    }
}

/// The first read-only FCST/FCSS exchange we can safely reproduce.
/// No write command is exposed here.
public enum FC03ReadOnlyProtocol {
    public static let serialProfile = FC03SerialProfile.documented
    public static let datCommand = Data([0x3F, 0x44, 0x41, 0x54]) // "?DAT"
    public static let documentedResponsePayloadLength = 55

    public static func makeDATRequest() -> Data { datCommand }

    /// Validates the documented payload size while retaining the raw bytes.
    /// A trailing byte is accepted as a candidate terminator, but is not
    /// interpreted until a real FC-03 capture proves its value.
    public static func parseDATResponse(_ bytes: Data) throws -> FC03DATResponse {
        let payload: Data
        let terminator: UInt8?
        switch bytes.count {
        case documentedResponsePayloadLength:
            payload = bytes
            terminator = nil
        case documentedResponsePayloadLength + 1:
            payload = bytes.prefix(documentedResponsePayloadLength)
            terminator = bytes.last
        default:
            throw FC03ProtocolError.invalidResponseLength(
                actual: bytes.count,
                expected: documentedResponsePayloadLength
            )
        }
        return FC03DATResponse(raw: bytes, payload: payload, candidateTerminator: terminator)
    }
}

public struct FC03DATResponse: Sendable, Equatable {
    public let raw: Data
    public let payload: Data
    public let candidateTerminator: UInt8?

    public var isFieldDecoded: Bool { false }
    public var evidence: String { "raw FC-03 ?DAT payload; field offsets unverified" }
}
