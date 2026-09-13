<p align="center">
  <img src="logo.png" width="120" height="120" alt="QRFlux Logo" style="border-radius: 24px;" />
</p>

<h1 align="center">QRFlux ⚡</h1>

<p align="center">
  <strong>Transfer Freely • High-speed, private, offline file transfer between PC and Android using embedded FTP & QR pairing.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.38.8-02569B?logo=flutter" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-3.10.7-0175C2?logo=dart" alt="Dart" />
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20Web%20%7C%20Desktop-green" alt="Platform" />
  <img src="https://img.shields.io/badge/Vercel-Ready-black?logo=vercel" alt="Vercel" />
  <img src="https://img.shields.io/badge/License-MIT-blue" alt="License" />
</p>

---

## 📖 Overview

**QRFlux** is a consumer-grade, offline-first file transfer app built with Flutter. It is designed primarily as a high-speed mobile app enabling direct, ultra-fast transfers between Android devices over local Wi-Fi or Personal Hotspots without routing any data through third-party cloud servers or the internet.

For users who also want to beam files from their **PC or Laptop to their Android Phone**, QRFlux includes a lightweight local desktop companion server that runs right from this repository!

### Core Philosophy
- **Mobile First**: Optimized for rapid, intuitive Android-to-Android file sharing.
- **100% Offline**: Operates completely without cellular data or external cloud servers.
- **Zero Accounts**: No registration, login, or tracking.
- **Sandboxed & Private**: Only files selected for the active session are exposed to the local network.
- **Consumer Simplicity**: Networking complexity (IP addresses, ports, FTP commands) is hidden behind a simple UX: **Select → Scan → Stream**.
- **Desktop Companion**: Easily send files from any PC/Mac to Android by running the local host daemon.

---

## 🚀 How It Works

```text
┌──────────────┐                               ┌──────────────┐
│  SENDER      │                               │   RECEIVER   │
├──────────────┤                               ├──────────────┤
│ 1. Pick files│                               │              │
│ 2. Start FTP ├──────────────┐                │              │
│ 3. Show QR   │   Wi-Fi /    │  4. Scan QR    │ 5. Review &  │
│    & Code    │   Hotspot    ├───────────────►│    Confirm   │
│              │              │  6. Stream     │ 6. Save to   │
│ 7. Stop FTP  │◄─────────────┴────────────────┤    Downloads │
└──────────────┘                               └──────────────┘
```

1. **Sender selects files** (photos, videos, documents, archives) and starts a local embedded FTP server bound to the local network interface (port `2121`).
2. **Sender generates dynamic QR code** encoding single-use credentials, session ID, host IP, port, and a 6-digit verification code (`482 913`).
3. **Receiver points camera at QR code** to immediately discover the sender.
4. **Receiver reviews incoming transfer** summary (breakdown by category and total size) and verifies the 6-digit code.
5. **Receiver taps "Accept & Download"** to begin streaming files directly into `Downloads/QRTransfer` with real-time speed (MB/s) and ETA countdown.
6. **Session terminates**: The sender immediately stops the FTP server and invalidates credentials.

---

## 🏗️ Architecture

The app is built using clean layered architecture with **Riverpod 3** state management:

```text
lib/
├── core/
│   ├── constants/            # Port defaults, timeouts, buffer sizes
│   ├── theme/                # Curated dark/light theme, typography, HSL colors
│   └── utils/                # Human-readable formatters & filename sanitizer
├── models/
│   ├── file_item.dart        # File metadata and category classification
│   ├── qr_payload.dart       # JSON session token serialization & validation
│   ├── transfer_progress.dart# Throughput speed, ETA, and progress metrics
│   └── transfer_history_item.dart # Local history records
├── services/
│   ├── network/              # Local IP & Hotspot discovery
│   ├── qr/                   # Cryptographic tokens & 6-digit code generation
│   ├── storage/              # File picker, paths, and traversal prevention
│   └── ftp/
│       ├── ftp_server_service.dart          # Embedded RFC 959 FTP daemon
│       ├── session_virtual_file_operations.dart # Virtual sandboxed file system
│       └── ftp_client_service.dart          # High-speed streaming client
├── state/
│   ├── network_provider.dart # Live network status
│   ├── sender/               # Sender state machine
│   ├── receiver/             # Receiver state machine
│   ├── settings/             # User preferences & theme mode
│   └── history/              # Persistent transfer logs
└── features/
    ├── home/                 # Main entry screen
    ├── sender/               # File selection, connection guide & QR display
    ├── receiver/             # Camera scanner & transfer confirmation
    ├── transfer/             # Live progress ring, speed graph & completion
    ├── settings/             # Theme & storage preferences
    └── history/              # Transfer logs with clear option
```

---

## 🔒 Security & Sandboxing

1. **Virtual Sandboxing**: `SessionVirtualFileOperations` maps virtual root `/` strictly to the sender's selected files. Directory traversal (e.g. `../../etc/passwd` or `..\..\Windows`) throws a `FileSystemException` and is blocked.
2. **Ephemeral Credentials**: Each transfer generates a cryptographically random session ID, username, and high-entropy 16-character password valid only for that single session.
3. **Verification Code**: A 6-digit code (e.g. `482 913`) allows both parties to visually confirm pairing integrity before any bytes transfer.
4. **Immediate Teardown**: The embedded FTP server automatically unbinds its listening socket and closes active sessions upon transfer completion or cancellation.

---

## 📱 Getting Started

### Prerequisites
- Flutter SDK `^3.38.0` or higher
- Dart SDK `^3.10.0` or higher
- Android SDK (target 34+)

### Installation & Run

```bash
# Clone or navigate to the project directory
cd smart_file_transfer

# Fetch dependencies
flutter pub get

# Run tests
flutter test

# Run code analyzer
flutter analyze

# Run on connected device or emulator
flutter run
```

### Android Release Build

```bash
flutter build apk --release
```
The resulting APK will be generated at `build/app/outputs/flutter-apk/app-release.apk`.

---

## 💻 Sending Files from Laptop / PC to Phone

If you want to beam large files, 4K videos, or archives from your PC/laptop to your Android phone, you can run the QRFlux local host server:

### 1. Clone & Navigate to the Repository
```bash
git clone https://github.com/Ganesh-anandam/qrflux.git
cd qrflux
```

### 2. Prerequisites
Make sure you have **Dart SDK** (included with Flutter) installed:
```bash
dart --version
```

### 3. Run the PC Host Server
- **Windows**: Double-click `run_pc_host.bat` (or run `dart run bin/server.dart` in terminal)
- **macOS / Linux**:
  ```bash
  dart run bin/server.dart
  ```

*(If Windows Firewall prompts you for access, click "Allow access", or run `fix_firewall.bat` as Administrator).*

### 4. Stage Files in the Local Web Interface
The server automatically launches `http://localhost:8080` in your default browser.
1. Drag and drop any files or folders from your computer into the drop zone.
2. Click **Generate Transfer QR**.

### 5. Scan & Receive on Your Phone
1. Ensure your Android phone is connected to the same Wi-Fi network (or connect your PC to your phone's Wi-Fi hotspot).
2. Open the **QRFlux Android App**, tap **Receive Files**, and scan the QR code displayed on your PC screen.
3. Your files stream directly into your phone's `Downloads` folder at **50+ MB/s**!

---

## 📶 Network Requirements & Tips

1. **Same Wi-Fi Network**: Both devices can connect to the same local Wi-Fi router (no internet required).
2. **Wi-Fi Hotspot (Fastest)**:
   - Device A turns on **Personal Hotspot**.
   - Device B connects to Device A's Hotspot Wi-Fi.
   - Launch **QR Transfer** and begin sharing at full Wi-Fi Direct speeds (up to 30–50+ MB/s).
3. **AP Isolation**: Some public or enterprise Wi-Fi networks enable Client / AP Isolation which prevents devices on the same subnet from connecting. If this occurs, simply use the sender device's built-in **Personal Hotspot**.

---

## 🧪 Testing

The repository contains test suites covering core functionality:
- `test/qr_payload_test.dart`: QR serialization, parsing, expiration, and code format.
- `test/filename_sanitizer_test.dart`: Path traversal defense and illegal character handling.
- `test/transfer_calculation_test.dart`: Data throughput speeds, byte formatting, and ETA calculation.
- `test/widget_test.dart`: Home screen rendering and navigation actions.

Run all tests:
```bash
flutter test
```

---

## 🌐 Deploy to Vercel

QRFlux includes a complete production-grade Web Portal, Web Sender, Pairing Guide, and direct APK download distribution configured for instant deployment to [Vercel](https://vercel.com):

### 1-Click Import:
1. Push your changes to your GitHub repository (`https://github.com/Ganesh-anandam/qrflux`).
2. Log into [vercel.com](https://vercel.com) and click **"Add New Project"**.
3. Select and import **`qrflux`**.
4. Vercel automatically detects the static output configured in [vercel.json](file:///d:/Google/smart_file_transfer/vercel.json) (pointing to `public/`).
5. Click **"Deploy"**!

### What Vercel Hosts:
- 🚀 **QRFlux Web Portal & Landing Page**: Modern glassmorphic presentation with Android app showcase.
- 📲 **Direct APK Download**: One-click download of `qrflux-app.apk` for any Android phone.
- 💻 **Desktop Companion Guide**: Clear instructions for running the local PC host to beam files from PC to phone.

*(Note: Raw TCP streaming over port 2121 runs locally on the phone/PC daemon for 100% offline security, independent of cloud servers).*

