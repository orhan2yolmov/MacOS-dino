// swift-tools-version: 6.0
// MacOS-Dino – Dinamik Hareketli Arka Plan Uygulaması
// Supabase Veritabanı Projesi: Yolmov

import PackageDescription

let package = Package(
    name: "MacOS-Dino",
    platforms: [
        .macOS(.v14)
    ],
    swiftLanguageModes: [.v5],
    dependencies: [
        // Supabase Swift SDK
        .package(url: "https://github.com/supabase-community/supabase-swift.git", from: "2.0.0"),
        // Keychain erişimi
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.2.2"),
    ],
    targets: [
        .executableTarget(
            name: "MacOSDino",
            dependencies: [
                .product(name: "Supabase", package: "supabase-swift"),
                .product(name: "KeychainAccess", package: "KeychainAccess"),
            ],
            path: "MacOSDino",
            exclude: [
                "App/Info.plist",
                "App/MacOSDino.entitlements",
            ],
            resources: [
                .process("Resources"),
                .process("Core/Shaders/SimpleWave.metal"),
                .process("Core/Shaders/CursorRepel.metal"),
                .process("Core/Shaders/AudioReactive.metal"),
                .process("Core/Shaders/LiquidGlass.metal"),
            ]
        ),
    ]
)
