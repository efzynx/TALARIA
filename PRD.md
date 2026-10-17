# Product Requirements Document (PRD) — Talaria

## 1. Project Overview & Mission

- **Project Name:** Talaria
- **Repository / Directory:** `/home/efzyn/Project/talaria`
- **Owner / Creator:** Ahmad Fauzan Adiman (Efzyn)
- **Tagline:** *Wings for your Hermes Agent — Mobile-First & Desktop Remote Client.*
- **Core Purpose:**
  Membangun aplikasi remote client native, mandiri (*standalone*), dan multiplatform berbasis **Flutter** untuk mengendalikan 100% kapabilitas daemon headless `hermes serve` (port 9119) melalui protokol WebSocket JSON-RPC 2.0.
  Aplikasi ini meniadakan ketergantungan pada Hermes Web Dashboard browser dan memberikan pengalaman *first-class* di ponsel cerdas (Android), sembari tetap berfungsi optimal saat diinstal di Desktop (Windows & Linux).

---

## 2. Target Platforms & Distribution Requirements

| Platform | Target OS / Architecture | Format Distribusi | Metode Signing & Release |
|---|---|---|---|
| **Android (Utama)** | Android 8.0+ (API 26 s.d 35) / ARM64, x86_64 | Release APK & AAB | Sign release via GitHub Actions Secret (`ANDROID_KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`) |
| **Windows** | Windows 10 / 11 (x64) | Installer (`.msi` / NSIS `.exe`) & Portable `.zip` | Build & pack via GitHub Actions Windows Runner |
| **Linux** | Ubuntu / Debian / Arch / CachyOS (x86_64) | AppImage & `.deb` | Build & pack via GitHub Actions Ubuntu Runner |

---

## 3. System Architecture & Communication Flow

### 3.1. Network & Connectivity Model
Talaria berkomunikasi langsung dengan backend Hermes melalui:
- **Protokol:** WebSocket (`ws://` untuk jaringan lokal/Tailscale, `wss://` untuk Cloudflare Tunnel/HTTPS).
- **Format Pertukaran Data:** JSON-RPC 2.0.
- **Heartbeat & Resiliensi:**
  - Client mengirim frame `{"jsonrpc": "2.0", "id": <n>, "method": "gateway.ping"}` setiap 30 detik.
  - Jika koneksi terputus (*network drop*), aplikasi menjalankan *exponential backoff reconnect* (1 detik, 2 detik, 5 detik, 10 detik, maks 30 detik).
  - Draft input teks dan riwayat lokal disimpan dalam *ephemeral storage* agar pesan pengguna tidak hilang saat jaringan berpindah (misal: Wi-Fi ke Seluler).

### 3.2. Pemetaan Method JSON-RPC Utama

1. **Sesi & Percakapan:**
   - `session.create` / `session.list` / `session.resume` / `session.delete`
   - `prompt.submit`: Mengirim prompt pengguna ke agen.
   - Event broadcast masuk: Streaming teks token LLM, status turn, dan metadata konsumsi token.
2. **Keamanan & Approval Gatekeeper (Paling Krusial di HP):**
   - Event `approval.pending`: Menerima pemberitahuan saat agen membutuhkan konfirmasi eksekusi perintah terminal berbahaya.
   - `approval.respond`: Mengirim keputusan dari layar HP (`once`, `session`, `deny`).
3. **Konfigurasi & Pengaturan Sistem (100% Fitur):**
   - `config.get`, `config.set`, `config.show`: Membaca dan memodifikasi konfigurasi `config.yaml` tanpa membuka terminal host.
   - `model.options`, `model.save_key`: Mengganti LLM yang aktif, reasoning effort (none/low/high/ultra), dan API keys.
   - `tools.list`, `tools.configure`, `toolsets.list`: Mengaktifkan/menonaktifkan toolsets per platform.
   - `skills.manage`, `skills.reload`: Memuat ulang atau meninjau daftar skill agen.
4. **Workspace & Projects:**
   - `projects.list`, `projects.tree`, `projects.create`, `projects.set_active`: Memilih workspace aktif (seperti project `kepkat`).

---

## 4. Spesifikasi UX & Desain (Mobile-First)

Mengacu pada panduan desain di `DESIGN.md`:
- **Tema Visual (Talaria-Inverse):**
  - Kebalikan dari tema emas/hangat Hermes: Menggunakan palet **Cyberpunk Cold Void** (Latar belakang hitam abisal `#080C14`, permukaan `#0F172A`, aksen **Electric Cyan `#00E5FF`**, aksen reasoning **Sky Blue `#38BDF8`**).
- **Ergonomi Layar Sentuh:**
  - *Thumb-Zone Optimization:* Elemen aksi penting (input chat, tombol kirim, approval modal, tab navigasi) ditempatkan di sepertiga area bawah layar.
  - *Collapsible Accordion Tools:* Status pengerjaan tool (terminal stdout, file parsing) diringkas dalam akordeon satu-baris agar tidak menenggelamkan teks jawaban agen di layar 6 inci.
  - *No-AI-Slop Copy:* Salinan teks antarmuka dibuat singkat, padat, dan teknis (tanpa basa-basi).
  - *Strict Vector Icons:* Tidak menggunakan emoji/emoticon sebagai icon UI sistem.

---

## 5. Rencana Arsitektur Kode Flutter

```text
lib/
├── core/
│   ├── network/            # WebSocket client, JSON-RPC 2.0 handler, reconnect logic
│   ├── theme/              # Color palette (Talaria-Inverse), typography, token constants
│   └── utils/              # Haptic feedback, formatting, logger
├── data/
│   ├── models/             # Data class: Session, Message, ToolCall, Project, ConfigItem
│   └── repositories/       # HermesRepository (abstraksi komunikasi RPC)
├── state/                  # State management (Riverpod / BLoC)
│   ├── connection_provider # Status live WebSocket & auth
│   ├── session_provider    # Riwayat pesan aktif & streaming
│   ├── approval_provider   # Antrian approval tertunda
│   └── project_provider    # Active project workspace
└── presentation/
    ├── navigation/         # BottomBar (Mobile) / SideRail (Desktop)
    ├── screens/
    │   ├── chat/           # Layar obrolan utama dengan token stream
    │   ├── sessions/       # Riwayat sesi percakapan & filter proyek
    │   ├── projects/       # Manajemen workspace project
    │   ├── approvals/      # Daftar konfirmasi keamanan yang tertunda
    │   └── settings/       # Konfigurasi model, tools, provider, dan server URL
    └── widgets/
        ├── approval_sheet  # Bottom sheet modal untuk konfirmasi perintah
        ├── tool_accordion  # Tampilan step tool hemat ruang
        └── connection_pill # Badge status online/offline
```

---

## 6. Otomasi CI/CD (GitHub Actions Workflow)

Workflow build diatur dalam file `.github/workflows/release.yml` dengan pemicu tag rilis Git (`v*.*.*`):

1. **Job `build-android` (Ubuntu Runner):**
   - Setup Java 17 + Flutter SDK.
   - Decode Secret `ANDROID_KEYSTORE_BASE64` menjadi file `keystore.jks`.
   - Build Release: `flutter build apk --release --split-per-abi` dan `flutter build appbundle`.
   - Menghasilkan artifact APK bertanda tangan (*signed release*).
2. **Job `build-linux` (Ubuntu Runner):**
   - Setup dependencies GTK (`libgtk-3-dev`, `ninja-build`, `pkg-config`).
   - Eksekusi: `flutter build linux --release`.
   - Packaging menjadi `.tar.gz` dan AppImage.
3. **Job `build-windows` (Windows Runner):**
   - Setup Visual Studio C++ toolchain + Flutter.
   - Eksekusi: `flutter build windows --release`.
   - Packaging binary dan dependencies menjadi zip/NSIS installer.
4. **Job `publish-release`:**
   - Mengumpulkan seluruh binary dari 3 platform ke dalam rilis GitHub baru secara otomatis.

---

## 7. Timeline & Rencana Eksekusi

- **Fase 1:** Inisialisasi struktur Flutter, implementasi `DESIGN.md` (ThemeData, Palette, Fonts), dan core WebSocket JSON-RPC 2.0 client.
- **Fase 2:** Implementasi antarmuka Chat Mobile-First (streaming text, tool execution accordion, voice audio player).
- **Fase 3:** Modul Approval Gatekeeper (push notification / modal one-tap authorization).
- **Fase 4:** Modul Manajemen Sistem (Settings, Models, Tools, Project Workspace selector).
- **Fase 5:** Adaptasi tata letak responsif untuk Desktop (Windows & Linux split-pane view).
- **Fase 6:** Setup konfigurasi GitHub Actions workflow & build verifikasi.
