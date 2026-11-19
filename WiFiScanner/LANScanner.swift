import Foundation
import Network

struct LANDevice: Identifiable, Equatable {
    let id = UUID()
    let ip: String
    let openPorts: [Int]
}

/// 局域网设备扫描：在当前 /24 网段内逐个试探常见端口，
/// 有回应的就是在线设备。iOS 读不到 ARP 表、也拿不到对方 MAC 地址，
/// 所以这里只能给出 IP 和开放端口。
@MainActor
final class LANScanner: ObservableObject {
    @Published var devices: [LANDevice] = []
    @Published var scanning = false
    @Published var progress: Double = 0

    private var connections: [NWConnection] = []
    private let probePorts = [80, 443, 22, 62078, 5000, 7000, 8080]

    func start(baseIP: String) {
        // baseIP 形如 192.168.1.23 → 扫 192.168.1.1–254
        let parts = baseIP.split(separator: ".")
        guard parts.count == 4 else { return }
        let prefix = parts.prefix(3).joined(separator: ".")
        devices = []
        scanning = true
        progress = 0
        var finished = 0
        let total = 254

        for host in 1...254 {
            let ip = "\(prefix).\(host)"
            probe(ip: ip) { [weak self] ports in
                Task { @MainActor in
                    guard let self else { return }
                    finished += 1
                    self.progress = Double(finished) / Double(total)
                    if !ports.isEmpty {
                        self.devices.append(LANDevice(ip: ip, openPorts: ports.sorted()))
                        self.devices.sort { $0.ip < $1.ip }
                    }
                    if finished == total { self.scanning = false }
                }
            }
        }
    }

    private func probe(ip: String, done: @escaping ([Int]) -> Void) {
        var found: [Int] = []
        var remaining = probePorts.count
        for port in probePorts {
            let conn = NWConnection(
                host: NWEndpoint.Host(ip),
                port: NWEndpoint.Port(rawValue: UInt16(port))!,
                using: .tcp)
            connections.append(conn)
            var settled = false
            let settle: ([Int]) -> Void = { _ in }
            _ = settle
            conn.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    if !settled { settled = true; found.append(port) }
                    conn.cancel()
                    remaining -= 1
                    if remaining == 0 { done(found) }
                case .failed, .cancelled:
                    if case .failed = state, !settled { settled = true }
                    remaining -= 1
                    if remaining == 0 { done(found) }
                default:
                    break
                }
            }
            conn.start(queue: .global())
            // 1.2 秒没连上就算这个端口不通
            DispatchQueue.global().asyncAfter(deadline: .now() + 1.2) {
                if !settled {
                    settled = true
                    conn.cancel()
                    remaining -= 1
                    if remaining == 0 { done(found) }
                }
            }
        }
    }

    func stop() {
        connections.forEach { $0.cancel() }
        connections = []
        scanning = false
    }
}
