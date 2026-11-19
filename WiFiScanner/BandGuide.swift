import Foundation

/// 信道 → 频率 / 频段 对照。
/// 拿到任何一个 Wi-Fi 的信道号，用这张表就能反查它在哪个频段、中心频率多少。
struct ChannelInfo: Identifiable {
    let id = UUID()
    let channel: Int
    let frequencyMHz: Int
    let band: String
}

enum BandGuide {
    static func info(forChannel ch: Int) -> ChannelInfo? {
        all.first { $0.channel == ch }
    }

    static let all: [ChannelInfo] = {
        var list: [ChannelInfo] = []
        // 2.4 GHz：信道 1–13 每 5 MHz 一个，14 号特殊
        for ch in 1...13 {
            list.append(ChannelInfo(channel: ch, frequencyMHz: 2407 + ch * 5, band: "2.4 GHz"))
        }
        list.append(ChannelInfo(channel: 14, frequencyMHz: 2484, band: "2.4 GHz"))
        // 5 GHz 常用信道
        for ch in [36, 40, 44, 48, 52, 56, 60, 64,
                   100, 104, 108, 112, 116, 120, 124, 128, 132, 136, 140, 144,
                   149, 153, 157, 161, 165] {
            list.append(ChannelInfo(channel: ch, frequencyMHz: 5000 + ch * 5, band: "5 GHz"))
        }
        // 6 GHz（Wi-Fi 6E / 7）：信道 1–233，中心频率 5955 + ch*5
        for ch in stride(from: 1, through: 233, by: 4) {
            list.append(ChannelInfo(channel: ch, frequencyMHz: 5955 + ch * 5, band: "6 GHz"))
        }
        return list
    }()

    static func bandName(forChannel ch: Int) -> String {
        switch ch {
        case 1...14: return "2.4 GHz"
        case 32...177: return "5 GHz"
        default: return "6 GHz"
        }
    }
}
