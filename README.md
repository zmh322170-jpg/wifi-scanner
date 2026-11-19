# Wi-Fi 数据（WiFiScanner）

一个 iOS 小工具，四个功能页：

1. **当前 Wi-Fi**：你现在连着的 Wi-Fi 的名称（SSID）、BSSID、信号强度、是否加密、本机 IP、子网掩码
2. **频段信道表**：2.4 / 5 / 6 GHz 全部常用信道和中心频率对照；输入信道号可反查频段
3. **局域网设备**：扫当前网段里在线的设备（IP + 开放端口）
4. **测速**：延迟 + 下行速度

## 先说清一个限制

iOS 不给第三方 App 扫描“附近所有 Wi-Fi 列表”的权限，这个功能只有苹果自家的
**AirPort 实用工具**（App Store 免费）有私有权限能做：
装好后去 设置 → AirPort 实用工具 → 打开“Wi-Fi 扫描”，回 App 点右上角“Wi-Fi 扫描”，
就能看到附近每个 Wi-Fi 的名字、信道和信号。本 App 做的是系统允许的其余部分。

## 怎么变成 IPA 装到 iPhone 上

IPA 必须在苹果的 Mac 构建机上编译 + 用 Apple ID 签名，我（Muse）的机器是 Linux，
没法直接编译 iOS 应用。所以最后一步二选一：

### 路线 A：GitHub 自动打包（不用自己有 Mac）
1. 把这个文件夹传到一个 GitHub 仓库
2. 打开仓库的 **Actions → Build IPA → Run workflow**
3. 跑完在页面底部 **Artifacts** 下载 `WiFiScanner-ipa`，解压得到 `WiFiScanner.ipa`（未签名）
4. 在 Windows/Mac 上用 **Sideloadly**（或 AltStore）选这个 IPA、填你自己的 Apple ID，
   它会自动签名并装进 iPhone；免费签名 7 天到期后重新签一次即可

### 路线 B：有 Mac
用 Xcode 打开 `WiFiScanner.xcodeproj`，插上 iPhone 点运行，
或 Product → Archive 导出 IPA。签名选你自己的 Apple ID 团队即可。

## 权限说明
- 定位权限：iOS 强制要求——不给定位权限，系统连当前 Wi-Fi 名字都不让读。本 App 不记录、不上传位置。
- 本地网络权限：局域网扫描要用。
- 首次打开请都点“允许”，否则对应页面读不到数据。

IPA 构建：打包完成后在 Releases 里下载 WiFiScanner.ipa。
