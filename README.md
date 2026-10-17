# Talaria

> *Wings for your Hermes Agent — Mobile-First & Desktop Remote Client.*

Talaria is a standalone multiplatform client built with **Flutter** for controlling [Hermes Agent](https://hermes-agent.nousresearch.com/docs) daemon instances (`hermes serve` on port 9119) over WebSocket JSON-RPC 2.0.

Designed mobile-first for Android smartphones while maintaining a desktop layout (Linux & Windows).

---

## Features

- **JSON-RPC 2.0 Engine:** Standard request/response and real-time streaming notifications over WebSocket (`ws://` / `wss://`).
- **Resilient Connectivity:** Automated heartbeat (`gateway.ping` every 30s), round-trip latency tracking, and exponential backoff reconnection (1s, 2s, 5s, 10s, 30s).
- **Talaria-Inverse Design System:** AMOLED dark aesthetic (`#080C14` abyssal black, `#0F172A` slate void, `#00E5FF` electric cyan, `#38BDF8` reasoning stream).
- **Security Approval Gatekeeper:** Instant one-tap authorizations (`Allow Once`, `Allow for Session`, `Deny`) for dangerous terminal and tool calls, with haptic feedback.
- **Collapsible Tool Accordions:** Real-time tool execution status and stdout output collapsed into compact single-line items.
- **Responsive Navigation Shell:** Bottom Navigation Bar for mobile (<720px) and Navigation Rail for desktop (>=720px).
- **Workspace & Session Management:** Switch active projects and agent sessions directly from your device.

---

## Target Platforms

| Platform | Target OS / Architecture | Artifact Format |
|---|---|---|
| **Android** | Android 8.0+ (API 26–35) / ARM64, x86_64 | Release APK & AppBundle |
| **Linux** | Ubuntu / Debian / Arch / CachyOS (x86_64) | Standalone Bundle & tar.gz |
| **Windows** | Windows 10 / 11 (x64) | Standalone Bundle & zip |

---

## Project Architecture

```text
lib/
├── core/
│   ├── network/            # WebSocket client, JSON-RPC 2.0 handler, reconnect logic
│   ├── theme/              # AMOLED dark tokens (Talaria-Inverse), typography, ThemeData
│   └── utils/              # Haptic feedback and utilities
├── data/
│   ├── models/             # Domain models: ChatMessage, ToolCall, Session, Project, ApprovalRequest
│   └── repositories/       # HermesRepository (abstraction for RPC calls)
├── state/                  # Riverpod StateNotifiers
│   ├── connection_provider # WebSocket connection & diagnostics
│   ├── chat_provider       # Active chat buffer & token streaming
│   ├── approval_provider   # Pending security approval queue
│   ├── session_provider    # Agent session management
│   └── project_provider    # Workspace project selection
└── presentation/
    ├── navigation/         # Responsive AppShell (BottomBar / NavigationRail)
    ├── screens/
    │   ├── chat/           # Chat interface with streaming & tool accordions
    │   ├── sessions/       # Agent session management
    │   ├── projects/       # Workspace project selector
    │   ├── approvals/      # Security gatekeeper queue
    │   └── settings/       # Daemon endpoint, model configuration & diagnostics
    └── widgets/
        ├── connection_pill # Status badge with latency diagnostic dialog
        ├── tool_accordion  # Collapsible execution block for terminal/tools
        └── approval_sheet  # Floating bottom modal for approval decisions
```

---

## Getting Started

### Prerequisites

- Flutter SDK (3.22+)
- A running Hermes Agent daemon (`hermes serve` on port 9119)

### Running Locally

```bash
# Clone the repository
git clone https://github.com/efzynx/TALARIA.git
cd TALARIA

# Install dependencies
flutter pub get

# Run analyze & tests
flutter analyze
flutter test

# Run on your target platform
flutter run -d linux      # Linux desktop
flutter run -d windows    # Windows desktop
flutter run -d <device>   # Android device
```

---

## License

[MIT License](LICENSE) © 2026 Ahmad Fauzan Adiman (Efzyn)
