import Foundation
import Darwin

public protocol SerialTransport: AnyObject, Sendable {
    func open() throws
    func close()
    func send(_ bytes: [UInt8], mode: ECUAccessMode) throws
    func receive(maxBytes: Int) throws -> [UInt8]
}

/// macOS serial transport. It intentionally does not contain ECU commands.
/// Protocol commands must be confirmed from captures before implementation.
public final class DarwinSerialTransport: SerialTransport, @unchecked Sendable {
    private let configuration: SerialConfiguration
    private var descriptor: Int32 = -1

    public init(configuration: SerialConfiguration) {
        self.configuration = configuration
    }

    deinit { close() }

    public func open() throws {
        guard descriptor == -1 else { return }
        descriptor = Darwin.open(configuration.path, O_RDWR | O_NOCTTY | O_NONBLOCK)
        guard descriptor >= 0 else {
            throw FreedomError.invalidConfiguration("Cannot open \(configuration.path): \(String(cString: strerror(errno)) )")
        }

        var options = termios()
        guard tcgetattr(descriptor, &options) == 0 else { throw POSIXError(.EIO) }
        cfmakeraw(&options)
        options.c_cflag |= tcflag_t(CLOCAL | CREAD)
        // Previously hard-coded to 8N1, ignoring the configuration. The Freedom link is 7E1,
        // so honour dataBits, parity and stopBits from SerialConfiguration.
        options.c_cflag &= ~tcflag_t(CSIZE)
        switch configuration.dataBits {
        case 7: options.c_cflag |= tcflag_t(CS7)
        case 8: options.c_cflag |= tcflag_t(CS8)
        default: throw FreedomError.invalidConfiguration("Unsupported data bits: \(configuration.dataBits)")
        }
        switch configuration.parity {
        case .none:
            options.c_cflag &= ~tcflag_t(PARENB)
        case .even:
            options.c_cflag |= tcflag_t(PARENB)
            options.c_cflag &= ~tcflag_t(PARODD)
        case .odd:
            options.c_cflag |= tcflag_t(PARENB | PARODD)
        }
        if configuration.stopBits == 2 {
            options.c_cflag |= tcflag_t(CSTOPB)
        } else {
            options.c_cflag &= ~tcflag_t(CSTOPB)
        }

        let speed = try Self.speed(configuration.baud)
        cfsetispeed(&options, speed)
        cfsetospeed(&options, speed)
        guard tcsetattr(descriptor, TCSANOW, &options) == 0 else { throw POSIXError(.EIO) }
    }

    public func close() {
        if descriptor >= 0 { Darwin.close(descriptor); descriptor = -1 }
    }

    public func send(_ bytes: [UInt8], mode: ECUAccessMode) throws {
        guard mode == .readOnly else {
            throw FreedomError.writeBlocked("The initial Mac port only permits read-only capture.")
        }
        guard descriptor >= 0 else { throw FreedomError.invalidConfiguration("Port is not open") }
        _ = bytes.withUnsafeBytes { Darwin.write(descriptor, $0.baseAddress, $0.count) }
    }

    public func receive(maxBytes: Int) throws -> [UInt8] {
        guard descriptor >= 0 else { throw FreedomError.invalidConfiguration("Port is not open") }
        var buffer = [UInt8](repeating: 0, count: maxBytes)
        let count = buffer.withUnsafeMutableBytes { Darwin.read(descriptor, $0.baseAddress, maxBytes) }
        if count < 0 { throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO) }
        return Array(buffer.prefix(count))
    }

    private static func speed(_ value: Int) throws -> speed_t {
        switch value {
        case 1200: return speed_t(B1200)
        case 2400: return speed_t(B2400)
        case 4800: return speed_t(B4800)
        case 9600: return speed_t(B9600)
        case 19200: return speed_t(B19200)
        case 38400: return speed_t(B38400)
        case 57600: return speed_t(B57600)
        case 115200: return speed_t(B115200)
        default: throw FreedomError.unsupportedBaudRate(value)
        }
    }
}
