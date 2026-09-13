# Build a Professional Offline QR + FTP File Transfer App in Flutter

## 1. Project Objective

Build a production-quality Flutter mobile application for **direct offline file transfer between nearby devices using FTP and QR-code pairing**.

The application must be extremely easy to understand for a first-time user while still having a modern, high-tech, polished UI/UX.

### Core principle

The application should work without:

- Internet
- Cloud servers
- User accounts
- External databases
- Mobile data
- Third-party file storage

The application should use:

- Direct local device connectivity
- A local FTP server on the sender
- An FTP client on the receiver
- QR code for connection/pairing information
- QR scanner for receiving devices

> Important: FTP requires a network transport. The application should support a direct local connection such as a device-created hotspot/local Wi-Fi connection, but it must not require internet access.

Do not upload files to any external server.

---

# 2. Product Name

Use a professional temporary product name:

**QR Transfer**

The branding should communicate:

- Speed
- Privacy
- Simplicity
- Offline transfer
- Modern technology

Keep the branding clean rather than gimmicky.

---

# 3. Target Users

The application should be understandable by:

- Non-technical users
- Students
- Professionals
- Developers
- Older users
- Users transferring photos/videos
- Users transferring large files

Do not expose technical terminology such as:

- FTP
- IP address
- Port
- TCP
- Socket
- Host
- Authentication token

unless the user opens an **Advanced / Technical Details** section.

Instead show:

> "Connect your devices"

> "Scan this QR code on the other phone."

> "Waiting for the other device..."

---

# 4. Primary User Flow

The entire experience should require as few steps as possible.

## Home

Show two clear primary actions:

### Send Files

Icon: upload/send

Subtitle:

> "Send files to another device"

### Receive Files

Icon: download/receive

Subtitle:

> "Receive files from another device"

Do not overload the home screen with settings.

---

# 5. Sender Flow

## Step 1 — Select files

Allow the user to select:

- Images
- Videos
- Documents
- Audio
- ZIP files
- Multiple files
- Folders if supported by the platform

Display selected files as cards.

Each card should show:

- File icon/thumbnail
- File name
- File size
- Remove button

Show:

```text
3 files
128 MB total
```

Primary CTA:

**Continue**

---

# 6. Connection Preparation

After selecting files, guide the user clearly.

Show:

### Connect the devices

```text
1. Keep both devices nearby
2. Connect the receiving device to this device
3. Scan the QR code
```

Avoid technical terminology.

If the application can detect the required local connection automatically, do so.

If manual connection is required, provide extremely clear instructions.

Never assume the user understands networking.

---

# 7. Sender QR Screen

This is one of the most important screens.

Design it as a focused pairing screen.

Show:

```text
Connect device

Scan this QR code
from the receiving device

        [ QR CODE ]

Waiting for connection...

Connected devices: 0
```

Also provide:

**6-digit verification code**

Example:

```text
482 913
```

Explain:

> "Ask the other person to confirm this code."

Provide:

- Cancel
- Help

Do not expose IP address/port by default.

Add an optional:

**Connection details**

expandable section for advanced users.

---

# 8. Receiver Flow

When the user chooses:

**Receive Files**

show:

```text
Scan QR code

Point your camera at
the sender's QR code.
```

Launch the scanner immediately.

Scanner UI should include:

- Camera preview
- QR scanning frame
- Flash button
- Cancel button
- Helpful scanning animation

Do not require the user to manually type IP addresses.

---

# 9. QR Processing

The QR code should contain only temporary connection/session information.

Example conceptual payload:

```json
{
  "version": 1,
  "protocol": "ftp",
  "host": "192.168.x.x",
  "port": 2121,
  "sessionId": "...",
  "credential": "...",
  "expiresAt": "..."
}
```

Do not place actual file contents inside the QR code.

Validate:

- Payload version
- Protocol
- Host
- Port
- Session ID
- Credential
- Expiration

Reject malformed or expired QR codes gracefully.

---

# 10. Receiver Confirmation

After scanning, show a confirmation screen.

Example:

```text
Device connected

Someone wants to send:

📷 12 photos
🎬 2 videos
📄 1 document

Total
1.4 GB

Verification code

482 913

        Accept
        Decline
```

Only begin file transfer after user confirmation.

Never silently download files.

---

# 11. FTP Architecture

Implement a local FTP server for the sender.

The sender should expose only the files selected for the current transfer session.

Do NOT expose the user's entire filesystem.

Use:

- Temporary session directory/access layer
- Random credentials
- Session ID
- Short expiration
- Authentication
- Controlled file access

After transfer completion or cancellation:

```text
FTP server → STOP
Session → INVALID
Credentials → INVALID
```

---

# 12. FTP Client

The receiver should connect using the information obtained from the QR code.

The client must support:

- File listing
- File size
- Download
- Multiple files
- Progress
- Cancellation
- Connection errors
- Retry where safe
- Transfer completion verification

Do not load entire files into memory.

Use streaming I/O.

---

# 13. Large File Optimization

The application must be optimized for large files.

Never use:

```dart
readAsBytes()
```

for large files.

Use streaming APIs.

Support files potentially ranging from:

- KB
- MB
- GB

Optimize:

- Memory usage
- Disk I/O
- Network throughput
- CPU usage
- UI rendering

The UI must remain responsive during transfers.

Move expensive work away from the main isolate when appropriate.

---

# 14. Transfer Progress

Provide professional real-time progress.

Example:

```text
Sending

video_2026.mp4

████████████████░░░░

78%

1.24 GB / 1.58 GB

Speed
28.4 MB/s

Remaining
00:12
```

Also show:

- Current file
- Overall progress
- Number of completed files
- Total files
- Transfer speed
- Estimated remaining time

Avoid excessive animation that could consume CPU.

---

# 15. Transfer Completion

Show a polished success screen:

```text
✓ Transfer complete

12 files transferred

1.4 GB

Transfer time
00:48

        Done
```

Optional:

**View files**

**Transfer another batch**

---

# 16. Error Handling

Errors must be understandable to normal users.

Never show:

> SocketException: Connection refused

Instead show:

> **Couldn't connect**

Then:

> Make sure both devices are connected and nearby.

Actions:

**Try Again**

**How to connect**

**Cancel**

For expired QR:

> **QR code expired**

> Create a new QR code on the sending device.

For interrupted transfer:

> **Transfer interrupted**

> Your devices lost their connection.

Actions:

**Resume** if technically safe

**Retry**

**Cancel**

---

# 17. High-Tech UI/UX

Create a premium modern interface inspired by contemporary file-sharing applications.

Design characteristics:

- Minimal
- Clean
- Premium
- Modern
- High-tech
- Strong visual hierarchy
- Smooth micro-interactions
- Excellent typography
- Spacious layout
- Subtle gradients
- Soft elevation
- Rounded cards
- Modern icons
- Smooth progress indicators

Avoid:

- Excessive neon
- Overly futuristic sci-fi graphics
- Clutter
- Too many colors
- Unnecessary animations
- Complex dashboards

The UI should look like a **professional 2026 mobile application**, not a demo project.

---

# 18. Design System

Create a centralized design system.

Define:

```text
AppColors
AppTypography
AppSpacing
AppRadius
AppShadows
AppAnimations
```

Use consistent:

- Padding
- Margins
- Border radius
- Font sizes
- Icon sizes
- Button heights
- Card styles

Support:

- Light mode
- Dark mode
- System theme

Dark mode should look intentionally designed, not simply inverted.

---

# 19. Accessibility

The application must be accessible.

Support:

- Large text
- Screen readers
- Semantic labels
- High contrast
- Minimum touch target sizes
- Clear error messages
- Do not rely only on color to communicate status

Buttons must clearly communicate their purpose.

---

# 20. Privacy

Privacy should be a major product feature.

The application should clearly communicate:

> "Your files stay between your devices."

Do not:

- Upload files
- Track file names
- Require accounts
- Collect unnecessary personal data
- Store transfer credentials permanently

Delete temporary session information after completion.

---

# 21. Security

Implement secure session handling.

Generate cryptographically secure random:

- Session IDs
- Temporary credentials
- Verification codes

Use short-lived sessions.

Validate all QR input.

Prevent:

- Unauthorized access
- Path traversal
- Access outside selected files
- Expired-session access
- Malformed requests

Never trust filenames or paths received from another device.

Sanitize filenames before writing them to storage.

---

# 22. Permissions

Request only permissions actually required.

Do not request permissions at application startup unnecessarily.

Explain why a permission is required immediately before requesting it.

Example:

> "Camera access is needed to scan the connection QR code."

For storage/file access:

> "Allow access so you can select files to send."

Handle denied permissions gracefully.

---

# 23. Architecture

Use clean, maintainable architecture.

Recommended:

```text
Presentation
     │
     ▼
State Management
     │
     ▼
Domain / Use Cases
     │
     ▼
Services
     │
     ├── FTP
     ├── QR
     ├── Network
     ├── File System
     └── Security
```

Separate UI from networking and file-transfer logic.

Do not put FTP logic directly inside widgets.

---

# 24. State Management

Use a production-appropriate state-management solution.

Recommended:

**Riverpod**

Separate states for:

```text
Idle
SelectingFiles
Preparing
WaitingForConnection
Connecting
Connected
AwaitingApproval
Transferring
Paused
Completed
Failed
Cancelled
```

Avoid unnecessary rebuilds.

---

# 25. Repository / Service Layer

Create interfaces so the implementation can be tested.

For example:

```text
FileRepository
TransferRepository
QrRepository
NetworkRepository
SecurityRepository
```

Keep platform-specific code isolated.

---

# 26. Testing

Write tests for:

### Unit tests

- QR encoding
- QR decoding
- Session validation
- Expiration
- Filename sanitization
- Transfer calculations
- Progress calculation

### Integration tests

- Sender creates session
- Receiver scans QR
- Authentication
- File listing
- File download
- Multiple files
- Cancellation
- Failed connection
- Session expiry

### UI tests

Test:

- Send flow
- Receive flow
- QR scanner
- Confirmation
- Transfer progress
- Completion
- Error states

---

# 27. Performance Requirements

Target:

- Smooth 60 FPS UI
- Minimal memory usage
- No UI freezes during transfers
- Streaming file transfers
- Efficient progress updates
- Batched UI state updates
- No unnecessary rebuilds
- Proper lifecycle handling
- Proper cancellation of streams/subscriptions

Do not update the UI hundreds of times per second.

Throttle progress updates appropriately.

---

# 28. Battery Optimization

Avoid unnecessary:

- Polling
- Continuous background processing
- High-frequency timers
- Excessive animations

Use event-driven communication where possible.

Stop:

- FTP server
- timers
- streams
- sockets
- listeners

when no longer required.

---

# 29. Offline-First Principle

The application should remain completely functional without internet.

Do not call remote APIs for core functionality.

Do not depend on:

- Firebase
- AWS
- Supabase
- Cloud storage
- External authentication
- Remote database

The transfer should happen locally between devices.

---

# 30. Android / Platform Considerations

Design the implementation with Android restrictions in mind.

Handle:

- App lifecycle
- Background/foreground behavior
- Local network connectivity
- Storage APIs
- Scoped storage
- Camera permissions
- Battery restrictions
- Large-file handling

Do not assume the application can keep a server alive indefinitely while completely backgrounded.

If platform limitations prevent a feature, provide a clear user-facing explanation instead of silently failing.

---

# 31. Settings

Keep settings simple.

Include:

```text
Appearance
├── System
├── Light
└── Dark

Transfer
├── Default download location
├── Confirm before receiving
├── Auto-start transfer
└── Transfer history

Security
├── Verification code
└── Session expiration

Advanced
└── Connection details
```

Do not expose advanced networking settings to normal users.

---

# 32. Transfer History

Store only local metadata if this feature is enabled.

Example:

```text
Today

Sent
12 files • 1.4 GB

Received
4 files • 230 MB
```

Do not store the actual files in the transfer history database.

Allow users to clear history.

---

# 33. Empty States

Design professional empty states.

Example:

```text
No transfers yet

Send or receive files
to see your transfer history here.

        Send files
```

Avoid generic blank screens.

---

# 34. Animations

Use subtle animations for:

- Screen transitions
- QR appearance
- Device connection
- Transfer progress
- Success state

Animations must be:

- Fast
- Smooth
- Purposeful

Do not animate every component.

Respect reduced-motion/accessibility settings where possible.

---

# 35. Code Quality

Follow strict Flutter/Dart best practices.

Requirements:

- Null safety
- Strong typing
- No unnecessary dynamic types
- Small reusable widgets
- Meaningful names
- No duplicated logic
- No magic numbers
- Constants for configuration
- Proper exception handling
- Proper logging
- Documentation for complex networking logic

Run:

```bash
flutter analyze
flutter test
dart format .
```

The project should finish with zero analyzer errors.

---

# 36. Logging

Create structured logging for development.

Example:

```text
[TRANSFER] Session created
[FTP] Server started
[QR] Payload generated
[QR] QR scanned
[FTP] Client authenticated
[TRANSFER] Started
[TRANSFER] Completed
[FTP] Server stopped
```

Never log:

- Passwords
- Authentication tokens
- Private file contents
- Sensitive user information

Disable verbose logging in release builds.

---

# 37. Project Deliverables

Produce:

1. Complete Flutter project
2. Clean folder structure
3. Production-quality UI
4. FTP server implementation
5. FTP client implementation
6. QR generator
7. QR scanner
8. File picker
9. File storage
10. Transfer progress
11. Security/session handling
12. Error handling
13. State management
14. Unit tests
15. Integration tests where practical
16. README
17. Architecture documentation

---

# 38. README Requirements

The README must explain:

### What is QR Transfer?

### How it works

```text
Select → Connect → Scan → Accept → Transfer
```

### Requirements

Clearly explain that FTP requires a local network transport, even though internet is not required.

### Architecture

Include a simple architecture diagram.

### Installation

Provide:

```bash
flutter pub get
flutter run
```

### Build

Explain Android release build.

### Security

Explain temporary sessions and credentials.

### Limitations

Clearly document platform/network limitations rather than hiding them.

---

# 39. Development Strategy

Do not attempt to build everything at once.

Implement in phases:

## Phase 1

Build the complete UI using mock transfer data.

## Phase 2

Implement file selection.

## Phase 3

Implement QR generation/scanning.

## Phase 4

Implement local FTP server.

## Phase 5

Implement FTP client.

## Phase 6

Connect QR → FTP session.

## Phase 7

Implement real file streaming.

## Phase 8

Add progress/speed/ETA.

## Phase 9

Add security and session expiry.

## Phase 10

Optimize performance.

## Phase 11

Add tests.

## Phase 12

Perform final UX polish.

---

# 40. Critical UX Rule

At every point, the user should know:

**What is happening?**

**What should I do next?**

**Is my file safe?**

**Is the transfer still running?**

**How long will it take?**

Never leave the user staring at a spinner without an explanation.

For example, instead of:

```text
Connecting...
```

use:

```text
Connecting to the other device

Keep both devices nearby.
This usually takes a few seconds.
```

---

# 41. Final Product Quality Bar

Do not build this as a basic CRUD/demo Flutter application.

Treat it as a real consumer product.

Prioritize:

1. Reliability
2. Simplicity
3. Security
4. Transfer performance
5. Accessibility
6. Visual quality
7. Maintainability

The final application should feel comparable to a polished commercial file-transfer application.

Before considering the project complete, test:

- Small files
- Large files
- Multiple files
- Many files
- Duplicate filenames
- Special characters in filenames
- Interrupted transfers
- Device disconnection
- Expired QR codes
- Invalid QR codes
- Permission denial
- Storage limitations
- App backgrounding
- Repeated transfers
- Dark mode
- Different screen sizes

Do not claim a feature works until it has been tested.

## Most important requirement

**Keep the user experience extremely simple while keeping the underlying architecture technically robust.**

The user should experience:

> **Select → Scan → Accept → Transfer**

Everything complicated about FTP, networking, authentication, sessions, streaming, security, and optimization should remain behind the scenes.