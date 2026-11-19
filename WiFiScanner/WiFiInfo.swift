import Foundation
import NetworkExtension
import CoreLocation
import Network

/// 当前连接的 Wi-Fi 信息。
/// 说明：iOS 只允许 App 读取“自己当前连着的”这一个 Wi-Fi，
/// 附近其他 Wi-Fi 的列表被系统锁死，第三方 App 拿不到（苹果自家的
/// AirPort 实用工具除外，它有私有权限）。
struct CurrentWiFi: Equatable {
    var ssid: String = "—"
    var bssid: String = "—"
    var signalPercent: Int = 0      // 0–100，由系统给的 0.0–1.0 换算
    var isSecure: Bool = false
    var ipAddress: String = "—"
    var subnetMask: String = "—"
    var interfaceName: String = "en0"
}

@MainActor
final class WiFiInfoModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var wifi = CurrentWiFi()
    @Published var statusText = "点“刷新”读取当前 Wi-Fi"

    private let locationManager = CLLocationManager()

    override init() {
        super.init()
        locationManager.delegate = self
    }

    /// 读取 SSID/BSSID 需要定位权限（这是 iOS 的硬性要求，不是本 App 想定位你）。
    func refresh() {
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
        NEHotspotNetwork.fetchCurrent { [weak self] network in
            Task { @MainActor in
                guard let self else { return }
                if let network {
                    self.wifi.ssid = network.ssid
                    self.wifi.bssid = network.bssid
                    self.wifi.signalPercent = Int((network.signalStrength * 100).rounded())
                    self.wifi.isSecure = network.isSecure
                    self.statusText = "已读取 · \(Date().formatted(date: .omitted, time: .standard))"
                } else {
                    self.statusText = "没读到：请确认已连上 Wi-Fi，并允许本 App 使用定位权限"
                }
                let (ip, mask) = Self.en0Address()
                self.wifi.ipAddress = ip
                self.wifi.subnetMask = mask
            }
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse
            || manager.authorizationStatus == .authorizedAlways {
            refresh()
        }
    }

    /// 读 en0（Wi-Fi 网卡）的 IPv4 地址和子网掩码
    static func en0Address() -> (ip: String, mask: String) {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let first = ifaddr else { return ("—", "—") }
        defer { freeifaddrs(ifaddr) }
        var ip = "—", mask = "—"
        for ptr in sequence(first: first, next: { $0.pointee.ifa_next }) {
            let iface = ptr.pointee
            guard let addr = iface.ifa_addr, addr.pointee.sa_family == UInt8(AF_INET) else { continue }
            let name = String(cString: iface.ifa_name)
            guard name == "en0" else { continue }
            var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            getnameinfo(addr, socklen_t(addr.pointee.sa_len),
                        &host, socklen_t(host.count), nil, 0, NI_NUMERICHOST)
            ip = String(cString: host)
            if let netmask = iface.ifa_netmask {
                var mhost = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                getnameinfo(netmask, socklen_t(netmask.pointee.sa_len),
                            &mhost, socklen_t(mhost.count), nil, 0, NI_NUMERICHOST)
                mask = String(cString: mhost)
            }
        }
        return (ip, mask)
    }
}
