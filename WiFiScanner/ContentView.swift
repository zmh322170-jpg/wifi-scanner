import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            CurrentWiFiView()
                .tabItem { Label("当前 Wi-Fi", systemImage: "wifi") }
            BandGuideView()
                .tabItem { Label("频段信道表", systemImage: "waveform.path.ecg") }
            LANScanView()
                .tabItem { Label("局域网设备", systemImage: "network") }
            SpeedTestView()
                .tabItem { Label("测速", systemImage: "gauge.with.dots.needle.67percent") }
        }
    }
}

// MARK: - 当前 Wi-Fi

struct CurrentWiFiView: View {
    @StateObject private var model = WiFiInfoModel()

    var body: some View {
        NavigationStack {
            List {
                Section {
                    LabeledContent("网络名称 SSID", value: model.wifi.ssid)
                    LabeledContent("BSSID", value: model.wifi.bssid)
                    LabeledContent("信号强度", value: "\(model.wifi.signalPercent)%")
                    LabeledContent("加密", value: model.wifi.isSecure ? "是" : "否 / 未知")
                    LabeledContent("本机 IP", value: model.wifi.ipAddress)
                    LabeledContent("子网掩码", value: model.wifi.subnetMask)
                } header: {
                    Text("你当前连着的 Wi-Fi")
                } footer: {
                    Text("iOS 只允许读取当前连接的这一个 Wi-Fi。附近其他 Wi-Fi 的列表被系统锁死，请用苹果官方“AirPort 实用工具”里的 Wi-Fi 扫描查看。读取 SSID 需要定位权限，系统强制要求，本 App 不记录你的位置。")
                }
                Section {
                    Button("刷新") { model.refresh() }
                    Text(model.statusText).font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Wi-Fi 数据")
            .onAppear { model.refresh() }
        }
    }
}

// MARK: - 频段信道表

struct BandGuideView: View {
    @State private var channelText = ""

    var body: some View {
        NavigationStack {
            List {
                Section("信道反查") {
                    TextField("输入信道号，如 36", text: $channelText)
                        .keyboardType(.numberPad)
                    if let ch = Int(channelText), let info = BandGuide.info(forChannel: ch) {
                        LabeledContent("频段", value: info.band)
                        LabeledContent("中心频率", value: "\(info.frequencyMHz) MHz")
                    } else if !channelText.isEmpty {
                        Text("没查到这个信道").foregroundStyle(.secondary)
                    }
                }
                ForEach(["2.4 GHz", "5 GHz", "6 GHz"], id: \.self) { band in
                    Section(band) {
                        ForEach(BandGuide.all.filter { $0.band == band }) { info in
                            HStack {
                                Text("信道 \(info.channel)")
                                Spacer()
                                Text("\(info.frequencyMHz) MHz")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("频段 / 信道")
        }
    }
}

// MARK: - 局域网设备

struct LANScanView: View {
    @StateObject private var scanner = LANScanner()
    @StateObject private var wifiModel = WiFiInfoModel()

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if scanner.scanning {
                        ProgressView(value: scanner.progress) {
                            Text("扫描中… \(Int(scanner.progress * 100))%")
                        }
                        Button("停止", role: .destructive) { scanner.stop() }
                    } else {
                        Button("开始扫描当前局域网") {
                            wifiModel.refresh()
                            scanner.start(baseIP: wifiModel.wifi.ipAddress)
                        }
                        .disabled(wifiModel.wifi.ipAddress == "—")
                    }
                    Text("先在“当前 Wi-Fi”页刷新一次拿到本机 IP，再回这里扫描。只能看到 IP 和开放端口，iOS 不给读对方 MAC 地址。")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section("在线设备（\(scanner.devices.count) 台）") {
                    ForEach(scanner.devices) { device in
                        HStack {
                            Text(device.ip)
                            Spacer()
                            Text(device.openPorts.map(String.init).joined(separator: ", "))
                                .foregroundStyle(.secondary)
                                .font(.footnote)
                        }
                    }
                }
            }
            .navigationTitle("局域网设备")
            .onAppear { wifiModel.refresh() }
        }
    }
}

// MARK: - 测速

struct SpeedTestView: View {
    @StateObject private var tester = SpeedTester()

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if let ms = tester.latencyMs {
                        LabeledContent("延迟", value: String(format: "%.0f ms", ms))
                    }
                    if let mbps = tester.downloadMbps {
                        LabeledContent("下行速度", value: String(format: "%.1f Mbps", mbps))
                    }
                    Text(tester.note).font(.footnote).foregroundStyle(.secondary)
                    Button(tester.running ? "测速中…" : "开始测速") {
                        Task { await tester.run() }
                    }
                    .disabled(tester.running)
                } footer: {
                    Text("下载 10MB 测试数据，会消耗少量流量。")
                }
            }
            .navigationTitle("测速")
        }
    }
}
