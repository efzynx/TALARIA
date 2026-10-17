---
version: alpha
name: Talaria-Inverse
description: Cool-spectrum, high-contrast, cyberpunk-editorial design system. The chromatic inversion of Hermes gold/amber warmth into electric cyan, arctic azure, and abyssal obsidian.
colors:
  primary: "#00E5FF"
  primary-hover: "#38BDF8"
  primary-active: "#0284C7"
  secondary: "#0077B6"
  tertiary: "#6366F1"
  background: "#080C14"
  surface: "#0F172A"
  surface-hover: "#1E293B"
  surface-active: "#334155"
  border: "#1E293B"
  border-highlight: "#00E5FF"
  text-primary: "#F1F5F9"
  text-secondary: "#94A3B8"
  text-muted: "#64748B"
  ok: "#10B981"
  error: "#F43F5E"
  warn: "#F59E0B"
  thinking: "#38BDF8"
typography:
  h1:
    fontFamily: Plus Jakarta Sans
    fontSize: 28px
    fontWeight: 700
    lineHeight: 1.2
    letterSpacing: "-0.02em"
  h2:
    fontFamily: Plus Jakarta Sans
    fontSize: 20px
    fontWeight: 600
    lineHeight: 1.3
  body-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 15px
    fontWeight: 400
    lineHeight: 1.5
  code:
    fontFamily: JetBrains Mono
    fontSize: 13px
    lineHeight: 1.4
rounded:
  sm: 4px
  md: 8px
  lg: 12px
  full: 9999px
spacing:
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 32px
components:
  card:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.text-primary}"
    rounded: "{rounded.md}"
    padding: 16px
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "#080C14"
    rounded: "{rounded.sm}"
    padding: 12px
  button-primary-hover:
    backgroundColor: "{colors.primary-hover}"
    textColor: "#080C14"
    rounded: "{rounded.sm}"
    padding: 12px
  button-surface:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.text-primary}"
    rounded: "{rounded.sm}"
    padding: 12px
  approval-card:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.text-primary}"
    rounded: "{rounded.md}"
    padding: 16px
---

## Overview

Talaria-Inverse dirancang sebagai antitesis visual dari Hermes standar. Jika estetika bawaan Hermes bernuansa hangat, klasik Mediterania, emas (`#FFD700`/`#FFBF00`), dan perunggu (`#CD7F32`), Talaria mengusung gaya **cyberpunk-editorial presisi: dingin, elektrik, dan abyssal obsidian**. 

Fokus utama adalah kenyamanan mata di layar OLED mobile (true dark mode), legibilitas tinggi saat membaca stream reasoning model, dan hierarki visual yang jelas untuk approval tindakan shell/tools.

## Colors

- **Primary (#00E5FF):** Electric Cyan. Aksen interaktif utama, indikator aktif, dan pengganti titik status `●` Hermes. Kontras rasio >15:1 di atas background hitam.
- **Background (#080C14):** Abyssal Night. Hitam pekat dengan sedikit rona biru dingin (deep void), menghemat konsumsi daya layar AMOLED di ponsel Android.
- **Surface (#0F172A):** Slate Void. Latar kontainer kartu, input chat, dan pane daftar sesi.
- **Secondary (#0077B6) & Tertiary (#6366F1):** Menandai kategori sekunder, tab navigasi tidak aktif, dan badge peran.
- **Semantic Feedback:**
  - `ok` (#10B981): Operasi sukses, status server terhubung.
  - `error` (#F43F5E): Kegagalan eksekusi, penolakan izin, atau koneksi terputus.
  - `warn` (#F59E0B): Peringatan kuota atau reconnection timeout.
  - `thinking` (#38BDF8): Warna stream teks reasoning model.

## Typography

- **Teks Utama (Plus Jakarta Sans):** Font geometris humanis dengan keterbacaan tinggi di layar sentuh berukuran 5.5 s.d 6.7 inci.
- **Teks Teknis (JetBrains Mono):** Untuk kode, output terminal bash, log RPC WebSocket, dan session ID.

## Layout

- **Mobile Viewport (Android):**
  - *Bottom Bar Navigation:* Tab Home/Chat, Sessions/Projects, Pending Approvals, dan Settings ditempatkan di bagian bawah agar dapat dijangkau satu jempol.
  - *Collapsible Tool Feeds:* Eksekusi tool (seperti terminal atau file reader) ditampilkan dalam blok akordeon ringkas agar tidak menenggelamkan teks balasan agen.
- **Desktop Viewport (Windows & Linux):**
  - *Responsive Master-Detail:* Sidebar tree navigasi di sisi kiri, obrolan utama di tengah, dan log/terminal inspektur di sisi kanan.

## Elevation & Depth

- Tidak menggunakan drop-shadow tebal yang membebani GPU perangkat seluler.
- Mengandalkan pemisah garis struktural (*flat structural borders*) `1px solid {colors.border}` dan kontras tonal antara `background` dan `surface`.

## Shapes

- Radius presisi: `rounded-sm (4px)` untuk tombol aksi teknis dan tag, `rounded-md (8px)` untuk kartu obrolan dan modul dialog, serta `rounded-lg (12px)` untuk bottom sheet.

## Components

- **Approval Banner / Card:** Elemen paling krusial di mobile. Ditampilkan mengambang (*floating bottom sheet*) dengan opsi instan: `Allow Once`, `Allow for Session`, dan `Deny`. Tombol dirancang dengan tinggi minimum 48px untuk kemudahan sentuhan.
- **Connection Pill:** Indikator visual real-time status WebSocket (`ws://` / `wss://`):
  - Hijau: Live socket aktif.
  - Kuning berkedip: Sedang reconnecting.
  - Merah: Offline.

## Do's and Don'ts

### Do's
- Gunakan ikon vektor SVG bersih (seperti Lucide Icons / Heroicons).
- Sediakan haptic feedback halus saat menekan tombol approval atau aksi berbahaya.
- Pastikan input chat auto-scroll mulus mengikuti kemunculan token streaming.

### Don'ts
- **Dilarang menggunakan emoji/emoticon unicode sebagai icon UI** (selalu gunakan vector icons sesuai preferensi Efzyn).
- Jangan gunakan animasi transisi berat yang menyebabkan frame-drop di Android.
- Jangan menyembunyikan status kegagalan WebSocket di balik menu dalam; selalu tampilkan banner status yang jelas.
