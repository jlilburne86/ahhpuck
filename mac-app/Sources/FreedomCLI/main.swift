import Foundation
import FreedomCore

let arguments = CommandLine.arguments.dropFirst()

switch arguments.first {
case "ports":
    let ports = PortDiscovery.macOSSerialPorts()
    if ports.isEmpty { print("No macOS serial ports found.") }
    else { ports.forEach { print($0) } }
case "settings":
    var settings = FCSTSettings()
    settings.defaultPort = ""
    let data = try JSONEncoder().encode(settings)
    print(String(decoding: data, as: UTF8.self))
case "help", nil:
    print("freedom-cli ports       List /dev/cu.* serial ports")
    print("freedom-cli settings    Print the recovered FCST defaults")
    print("\nWrite operations are intentionally unavailable until the FC-03 protocol is verified.")
default:
    print("Unknown command. Use: ports, settings, or help")
}
