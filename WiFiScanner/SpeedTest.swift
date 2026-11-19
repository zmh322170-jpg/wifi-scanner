import Foundation

/// 简易测速：从 Cloudflare 的测速端点下载 10MB 数据，按耗时算下行速率；
/// 再测一次到 cloudflare.com 的往返延迟。
@MainActor
final class SpeedTester: ObservableObject {
    @Published var running = false
    @Published var downloadMbps: Double?
    @Published var latencyMs: Double?
    @Published var note = ""

    func run() async {
        running = true
        note = "测速中…"
        downloadMbps = nil
        latencyMs = nil

        // 延迟
        if let url = URL(string: "https://www.cloudflare.com") {
            let start = Date()
            _ = try? await URLSession.shared.data(from: url)
            latencyMs = Date().timeIntervalSince(start) * 1000
        }

        // 下行：10 MB
        let bytes = 10_000_000
        if let url = URL(string: "https://speed.cloudflare.com/__down?bytes=\(bytes)") {
            let start = Date()
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let seconds = Date().timeIntervalSince(start)
                if seconds > 0 {
                    downloadMbps = Double(data.count) * 8 / seconds / 1_000_000
                }
                note = "测速完成"
            } catch {
                note = "测速失败：\(error.localizedDescription)"
            }
        }
        running = false
    }
}
