# 🦕 MacOS-Dino

**macOS İçin Dinamik Hareketli Arka Plan Uygulaması**

> Yüksek performanslı, Apple Silicon + Liquid Glass uyumlu, interaktif hareketli wallpaper deneyimi.

![macOS](https://img.shields.io/badge/macOS-14%2B-blue?logo=apple)
![Swift](https://img.shields.io/badge/Swift-5.9-orange?logo=swift)
![Metal](https://img.shields.io/badge/Metal-GPU-green)
![Supabase](https://img.shields.io/badge/Supabase-Backend-purple)

---

## ✨ Özellikler

- 🎬 **Video Wallpaper** – AVFoundation + Apple Silicon Media Engine ile HEVC/H.264 video oynatma
- 🎨 **Metal Shaders** – GPU hızlandırmalı interaktif shader efektleri (Dalga, Parçacık, Liquid Glass, Ses Reaktif)
- 🖱️ **Fare Etkileşimi** – İmleci takip eden parçacıklar, itme/çekme efektleri
- 🎵 **Ses Reaktif** – Mikrofon/sistem sesi ile gerçek zamanlı FFT analizi → görsel dalga
- 🖥️ **Çoklu Monitör** – Her ekrana bağımsız wallpaper, hot-plug desteği
- 🔒 **Kilit Ekranı** – Apple Aerial formatı uyumlu entegrasyon
- ⚡ **Ultra Verimli** – CPU ≤%0.4 | RAM ≤135MB | Energy Impact ≤8
- 🌐 **Supabase Backend** – Gerçek zamanlı senkronizasyon, bulut kütüphane (Yolmov projesi)
- 💎 **Liquid Glass** – macOS Tahoe 26 tasarım diline tam uyum
- 🏪 **Freemium Model** – 15 ücretsiz wallpaper + Pro ($9.99 lifetime)

---

## 🏗️ Mimari

```
MacOSDino/
├── App/                          # Uygulama giriş noktası
│   ├── MacOSDinoApp.swift        # @main SwiftUI App
│   ├── AppDelegate.swift         # NSApplicationDelegate
│   ├── Info.plist                # LSUIElement, Bundle config
│   └── MacOSDino.entitlements    # Sandbox + Hardened Runtime
│
├── Core/                         # Motor katmanı
│   ├── Engine/
│   │   ├── WallpaperEngine.swift      # Ana koordinatör
│   │   ├── DesktopWindow.swift        # kCGDesktopWindowLevel - 1
│   │   ├── VideoPlayerEngine.swift    # AVFoundation + loop
│   │   ├── OcclusionDetector.swift    # CGWindowList oklüzyon
│   │   ├── DisplayLinkManager.swift   # ProMotion 120Hz
│   │   └── MultiMonitorManager.swift  # Çoklu ekran yönetimi
│   ├── Shaders/
│   │   ├── ShaderManager.swift        # Metal pipeline yönetimi
│   │   ├── SimpleWave.metal           # Dalga efekti
│   │   ├── CursorRepel.metal          # Fare etkileşimi
│   │   ├── AudioReactive.metal        # Ses reaktif
│   │   └── LiquidGlass.metal          # Liquid Glass refraction
│   ├── Audio/
│   │   └── AudioAnalyzer.swift        # FFT ses analizi
│   └── Performance/
│       └── PerformanceMonitor.swift   # CPU/RAM/FPS izleme
│
├── Models/                       # Veri modelleri
│   ├── Wallpaper.swift
│   ├── UserProfile.swift
│   ├── Category.swift
│   └── DisplayConfiguration.swift
│
├── Services/                     # İş katmanı
│   ├── Supabase/
│   │   ├── SupabaseClient.swift       # Yolmov proje config
│   │   ├── AuthService.swift          # Auth + Apple Sign In
│   │   ├── WallpaperService.swift     # CRUD + arama
│   │   ├── StorageService.swift       # Video/thumbnail yönetimi
│   │   ├── RealtimeService.swift      # Canlı değişiklik takibi
│   │   └── AnalyticsService.swift     # Kullanım istatistikleri
│   ├── WallpaperManager.swift         # İndirme + cache
│   └── SubscriptionManager.swift      # StoreKit 2 IAP
│
├── Views/                        # UI katmanı
│   ├── MenuBar/
│   │   ├── MenuBarView.swift
│   │   └── MenuBarPopover.swift
│   ├── Gallery/
│   │   ├── GalleryView.swift          # Ana galeri (3-panel)
│   │   ├── WallpaperCard.swift        # Grid kart bileşeni
│   │   └── WallpaperDetailView.swift  # Sağ detay paneli
│   ├── Settings/
│   │   └── SettingsView.swift         # Ayarlar (5 tab)
│   ├── Auth/
│   │   └── LoginView.swift
│   └── Components/
│       ├── DisplayPreview.swift       # Monitör önizleme
│       └── Theme.swift                # Renk + stil sabitleri
│
└── Resources/
    └── Assets.xcassets/

Supabase/
├── config.toml                        # Supabase proje config
├── migrations/
│   ├── 001_initial_schema.sql         # Tüm tablolar + RLS + seed
│   └── 002_storage_policies.sql       # Storage bucket politikaları
└── functions/
    ├── generate-aerial-format/        # Video → Aerial converter
    └── live-preview-websocket/        # Canlı önizleme WebSocket
```

---

## 🔧 Teknoloji Stack

| Katman | Teknoloji |
|--------|-----------|
| UI Framework | SwiftUI 6+ |
| Grafik | Metal, Core Animation, Core Video |
| Video | AVFoundation, Apple Media Engine |
| Pencere | AppKit (NSWindow, Quartz) |
| Backend | Supabase – Yolmov Projesi (PostgreSQL, Realtime, Storage, Edge Functions) |
| Auth | Supabase Auth + Sign in with Apple |
| Ödeme | StoreKit 2 |
| Ses | AVAudioEngine + Accelerate (FFT) |
| CI/CD | GitHub Actions + Fastlane |

---

## 🚀 Başlangıç

### Gereksinimler

- macOS 14.0+ (Sonoma veya üzeri)
- Xcode 15.0+
- Apple Silicon veya Intel Mac
- Metal destekli GPU

### Kurulum

```bash
# Repo'yu klonla
git clone https://github.com/your-repo/MacOS-Dino.git
cd MacOS-Dino

# Swift Package Manager bağımlılıklarını çöz
swift package resolve

# Xcode'da aç
open Package.swift
```

### Supabase Veritabanı Kurulumu (Yolmov)

```bash
# Supabase CLI kur
brew install supabase/tap/supabase

# Migration'ları çalıştır
cd Supabase
supabase db push

# Edge function'ları deploy et
supabase functions deploy generate-aerial-format
supabase functions deploy live-preview-websocket
```

### Storage Bucket'ları (Supabase Dashboard)

1. `wallpaper-videos` → Public, 500MB limit
2. `thumbnails` → Public, 5MB limit
3. `user-uploads` → Private (RLS), 5GB/user quota

---

## 🛡️ Güvenlik

- **App Sandbox** + **Hardened Runtime** aktif
- **Notarization** zorunlu
- Supabase anahtarları **anon key** ile sınırlı (RLS aktif)
- Service role key **asla** client'ta kullanılmaz
- Storage RLS ile kullanıcı izolasyonu

---

## 💰 İş Modeli

| Plan | Fiyat | İçerik |
|------|-------|--------|
| Ücretsiz | $0 | 15 wallpaper, temel özellikler |
| Pro (Lifetime) | $9.99 | Tüm shader'lar, sınırsız import, 5GB upload |
| Content Pass | $0.99/ay | Sanatçı serileri, community upload |

---

## 📅 Yol Haritası

- [x] Aşama 0: Proje yapısı + Supabase kurulum
- [ ] Aşama 1: AVFoundation motor + Quartz katman + oklüzyon (1-3 ay)
- [ ] Aşama 2: MenuBarExtra + Liquid Glass UI + Metal shaders (4-6 ay)
- [ ] Aşama 3: Kilit ekranı + çoklu monitör + Realtime (7-9 ay)
- [ ] Aşama 4: App Store + marketing + 1.0 lansman (10-12 ay)

---

## 📄 Lisans

© 2026 MacOS-Dino. Tüm hakları saklıdır.