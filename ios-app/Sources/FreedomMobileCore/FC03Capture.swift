import Foundation

/// Metadata recorded beside every desk session. It makes a capture reproducible
/// without pretending that an adapter or ECU profile is already verified.
public struct FC03CaptureMetadata: Codable, Equatable, Sendable {
    public let startedAt: Date
    public let ecuLabel: String
    public let ecuProfile: String
    public let adapter: String
    public let cableNotes: String
    public let serialProfile: FC03SerialProfile
    public let sessionKind: FC03SessionKind
    public let vehicleProfile: [String: String]
    public let modifications: [String]
    public let captureSources: [FC03CaptureSource]

    public init(startedAt: Date = Date(), ecuLabel: String, ecuProfile: String,
                adapter: String, cableNotes: String,
                serialProfile: FC03SerialProfile = .documented,
                sessionKind: FC03SessionKind = .observation,
                vehicleProfile: [String: String] = [:],
                modifications: [String] = [],
                captureSources: [FC03CaptureSource] = [.ecu]) {
        self.startedAt = startedAt
        self.ecuLabel = ecuLabel
        self.ecuProfile = ecuProfile
        self.adapter = adapter
        self.cableNotes = cableNotes
        self.serialProfile = serialProfile
        self.sessionKind = sessionKind
        self.vehicleProfile = vehicleProfile
        self.modifications = modifications
        self.captureSources = captureSources
    }
}

public enum FC03SessionKind: String, Codable, Equatable, Sendable {
    case observation
    case baseline
    case candidate
    case repeatRun
}

public enum FC03CaptureSource: String, Codable, Equatable, Sendable {
    case ecu
    case gps
    case motion
    case wideband
    case oilPressure
    case fuelPressure
}

/// One request/reply exchange. Raw bytes are retained even when validation or
/// field decoding fails, so later protocol work can replay the original evidence.
public struct FC03RawExchange: Codable, Equatable, Sendable {
    public let sequence: Int
    public let request: Data
    public let response: Data
    public let requestedAt: Date
    public let receivedAt: Date
    public let responseLength: Int
    public let shapeValid: Bool
    public let fieldDecoded: Bool
    public let note: String

    public init(sequence: Int, request: Data, response: Data,
                requestedAt: Date, receivedAt: Date,
                shapeValid: Bool, fieldDecoded: Bool = false,
                note: String) {
        self.sequence = sequence
        self.request = request
        self.response = response
        self.requestedAt = requestedAt
        self.receivedAt = receivedAt
        self.responseLength = response.count
        self.shapeValid = shapeValid
        self.fieldDecoded = fieldDecoded
        self.note = note
    }

    public var roundTripMilliseconds: Int {
        max(0, Int((receivedAt.timeIntervalSince(requestedAt) * 1_000).rounded()))
    }
}

public struct FC03CaptureSession: Codable, Equatable, Sendable {
    public let metadata: FC03CaptureMetadata
    public let exchanges: [FC03RawExchange]

    public init(metadata: FC03CaptureMetadata, exchanges: [FC03RawExchange] = []) {
        self.metadata = metadata
        self.exchanges = exchanges
    }

    public var validExchangeCount: Int { exchanges.filter(\.shapeValid).count }
    public var invalidExchangeCount: Int { exchanges.count - validExchangeCount }
    public var hasDecodedFields: Bool { exchanges.contains(where: \.fieldDecoded) }

    /// Issues are descriptive only. Raw evidence remains exportable even when a
    /// session is incomplete or contains an unexpected request/response.
    public var validationIssues: [String] {
        var issues: [String] = []
        if exchanges.isEmpty { issues.append("no_exchanges") }
        if exchanges.contains(where: { $0.request != FC03ReadOnlyProtocol.makeDATRequest() }) {
            issues.append("unexpected_request")
        }
        if exchanges.contains(where: { !$0.shapeValid }) { issues.append("invalid_response_shape") }
        if exchanges.contains(where: { $0.fieldDecoded }) { issues.append("decoded_mapping_present") }
        return issues
    }

    public var isSafeForReplay: Bool {
        !exchanges.isEmpty && !validationIssues.contains("unexpected_request")
    }

    public func jsonData(prettyPrinted: Bool = true) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if prettyPrinted { encoder.outputFormatting = [.prettyPrinted, .sortedKeys] }
        return try encoder.encode(self)
    }
}

/// Actor-backed recorder used by the live transport and replay harness.
/// It has no write-to-ECU operation and can only append captured evidence.
public actor FC03CaptureRecorder {
    private let metadata: FC03CaptureMetadata
    private var exchanges: [FC03RawExchange] = []

    public init(metadata: FC03CaptureMetadata) {
        self.metadata = metadata
    }

    @discardableResult
    public func record(request: Data, response: Data,
                       requestedAt: Date = Date(), receivedAt: Date = Date()) -> FC03RawExchange {
        let valid: Bool
        let note: String
        do {
            let parsed = try FC03ReadOnlyProtocol.parseDATResponse(response)
            valid = true
            note = parsed.evidence
        } catch {
            valid = false
            note = "raw FC-03 exchange retained; response shape rejected: \(error.localizedDescription)"
        }
        let exchange = FC03RawExchange(sequence: exchanges.count + 1,
                                        request: request,
                                        response: response,
                                        requestedAt: requestedAt,
                                        receivedAt: receivedAt,
                                        shapeValid: valid,
                                        note: note)
        exchanges.append(exchange)
        return exchange
    }

    public func snapshot() -> FC03CaptureSession {
        FC03CaptureSession(metadata: metadata, exchanges: exchanges)
    }
}
