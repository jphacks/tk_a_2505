//
//  BadgeComponents.swift
//  escape
//
//  Created by YoungJune Kang on 2025/10/25.
//

import SwiftUI

// MARK: - バッジコレクションビュー

struct BadgeCollectionView: View {
    let badges: [Badge]
    var stats: (total: Int, unlocked: Int)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("home.badge_collection.title", tableName: "Localizable")
                    .font(.headline)

                if let stats = stats {
                    Text("(\(stats.unlocked)/\(stats.total))")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }

                Spacer()

                NavigationLink(String(localized: "home.badge_collection.view_all", table: "Localizable")) {
                    BadgeCollectionDetailView(badges: badges)
                }
                .font(.caption)
                .foregroundColor(Color("brandOrange"))
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(badges.prefix(8)) { badge in
                        Simple3DBadgeView(badge: badge)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - バッジアイテムビュー（詳細画面用）

struct BadgeItemView: View {
    let badge: Badge
    @State private var rotationX: Double = 0
    @State private var rotationY: Double = 0
    @State private var dragOffset = CGSize.zero
    @State private var isPressed = false
    @State private var showingDetail = false

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                // 背景の影（3D効果）
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.black.opacity(0.4),
                                Color.black.opacity(0.1),
                                Color.clear,
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 65
                        )
                    )
                    .frame(width: 130, height: 130)
                    .offset(x: 4, y: 4)
                    .blur(radius: 3)

                // メインのバッジ表示
                if let imageUrl = badge.imageUrl, !imageUrl.isEmpty {
                    // Use AsyncImage for remote URLs
                    AsyncImage(url: URL(string: imageUrl)) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(width: 100, height: 100)
                        case let .success(image):
                            ZStack {
                                // 画像用の背景円
                                Circle()
                                    .fill(
                                        RadialGradient(
                                            gradient: Gradient(colors: [
                                                badge.color.opacity(0.3),
                                                badge.color.opacity(0.1),
                                                Color.clear,
                                            ]),
                                            center: .center,
                                            startRadius: 0,
                                            endRadius: 60
                                        )
                                    )
                                    .frame(width: 120, height: 120)
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [
                                                        Color.white.opacity(0.6),
                                                        Color.white.opacity(0.2),
                                                        Color.clear,
                                                        Color.black.opacity(0.1),
                                                    ]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 2
                                            )
                                    )

                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                                    .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 3)
                            }
                        case .failure:
                            // Fallback to imageName if URL fails
                            if let imageName = badge.imageName, !imageName.isEmpty {
                                ZStack {
                                    // 画像用の背景円
                                    Circle()
                                        .fill(
                                            RadialGradient(
                                                gradient: Gradient(colors: [
                                                    badge.color.opacity(0.3),
                                                    badge.color.opacity(0.1),
                                                    Color.clear,
                                                ]),
                                                center: .center,
                                                startRadius: 0,
                                                endRadius: 60
                                            )
                                        )
                                        .frame(width: 120, height: 120)
                                        .overlay(
                                            Circle()
                                                .stroke(
                                                    LinearGradient(
                                                        gradient: Gradient(colors: [
                                                            Color.white.opacity(0.6),
                                                            Color.white.opacity(0.2),
                                                            Color.clear,
                                                            Color.black.opacity(0.1),
                                                        ]),
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    ),
                                                    lineWidth: 2
                                                )
                                        )

                                    Image(imageName)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                        .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 3)
                                }
                            } else {
                                fallbackBadgeItemCircle
                            }
                        @unknown default:
                            fallbackBadgeItemCircle
                        }
                    }
                } else if let imageName = badge.imageName, !imageName.isEmpty {
                    // Fallback to local image
                    ZStack {
                        // 画像用の背景円
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        badge.color.opacity(0.3),
                                        badge.color.opacity(0.1),
                                        Color.clear,
                                    ]),
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 60
                                )
                            )
                            .frame(width: 120, height: 120)
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.white.opacity(0.6),
                                                Color.white.opacity(0.2),
                                                Color.clear,
                                                Color.black.opacity(0.1),
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 2
                                    )
                            )

                        Image(imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 3)
                    }
                } else {
                    // No image available
                    fallbackBadgeItemCircle
                }

                // ハイライト効果
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.7),
                                Color.white.opacity(0.3),
                                Color.clear,
                            ]),
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: 40
                        )
                    )
                    .frame(width: 70, height: 70)
                    .offset(x: -18, y: -18)
                    .opacity(0.8)
            }
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .rotation3DEffect(
                .degrees(rotationX),
                axis: (x: 1, y: 0, z: 0)
            )
            .rotation3DEffect(
                .degrees(rotationY),
                axis: (x: 0, y: 1, z: 0)
            )
            .gesture(
                DragGesture(minimumDistance: 10)
                    .onChanged { value in
                        isPressed = true
                        dragOffset = value.translation

                        // 回転角度を制限（-45度から45度）、感度を上げる
                        let maxRotation: Double = 45
                        let sensitivity = 0.5
                        rotationY = min(max(Double(dragOffset.width) * sensitivity, -maxRotation), maxRotation)
                        rotationX = min(max(Double(-dragOffset.height) * sensitivity, -maxRotation), maxRotation)
                    }
                    .onEnded { _ in
                        isPressed = false
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            rotationX = 0
                            rotationY = 0
                            dragOffset = .zero
                        }
                    }
            )
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            .allowsHitTesting(true)
            .simultaneousGesture(
                TapGesture()
                    .onEnded { _ in
                        showingDetail = true
                    }
            )

            Text(badge.name)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(width: 140, height: 170)
        .sheet(isPresented: $showingDetail) {
            BadgeDetailView(badge: badge)
        }
    }

    // Fallback view when no image is available
    private var fallbackBadgeItemCircle: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            badge.color.opacity(0.9),
                            badge.color.opacity(0.7),
                            badge.color.opacity(0.5),
                            badge.color.opacity(0.3),
                        ]),
                        center: .topLeading,
                        startRadius: 10,
                        endRadius: 60
                    )
                )
                .frame(width: 120, height: 120)
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.8),
                                    Color.white.opacity(0.3),
                                    Color.clear,
                                    Color.black.opacity(0.2),
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                )

            Image(systemName: "photo")
                .font(.system(size: 30))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 2)
        }
    }
}

// MARK: - バッジコレクション詳細ビュー

struct BadgeCollectionDetailView: View {
    let badges: [Badge]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 40) {
                    ForEach(badges) { badge in
                        BadgeItemView(badge: badge)
                    }
                }
                .padding()
            }
            .navigationTitle(String(localized: "home.badge_collection.title", table: "Localizable"))
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - バッジカードボタン

struct BadgeCardButton: View {
    let badge: Badge
    @State private var showingDetail = false

    var body: some View {
        Button(action: {
            showingDetail = true
        }) {
            VStack(spacing: 8) {
                ZStack {
                    // 背景の影（3D効果を強調）
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.black.opacity(0.4),
                                    Color.black.opacity(0.1),
                                    Color.clear,
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: 50
                            )
                        )
                        .frame(width: 120, height: 120)
                        .offset(x: 3, y: 3)
                        .blur(radius: 2)

                    // メインの画像表示
                    if let imageName = badge.imageName, !imageName.isEmpty {
                        SimpleImageLoader(imageName: imageName)
                            .frame(width: 80, height: 80)
                    } else {
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        gradient: Gradient(colors: [
                                            badge.color.opacity(0.9),
                                            badge.color.opacity(0.7),
                                            badge.color.opacity(0.5),
                                            badge.color.opacity(0.3),
                                        ]),
                                        center: .topLeading,
                                        startRadius: 5,
                                        endRadius: 30
                                    )
                                )
                                .frame(width: 100, height: 100)
                                .overlay(
                                    Circle()
                                        .stroke(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color.white.opacity(0.8),
                                                    Color.white.opacity(0.3),
                                                    Color.clear,
                                                    Color.black.opacity(0.2),
                                                ]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 2
                                        )
                                )

                            Image(systemName: "photo")
                                .font(.title3)
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
                        }
                    }
                }

                Text(badge.name)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingDetail) {
            BadgeDetailView(badge: badge)
        }
    }
}

// MARK: - シンプル3Dバッジビュー（ホーム画面用）

struct Simple3DBadgeView: View {
    let badge: Badge
    @State private var showingDetail = false

    var body: some View {
        Button(action: {
            showingDetail = true
        }) {
            VStack(spacing: 4) {
                ZStack {
                    // 背景の影
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.black.opacity(0.3),
                                    Color.black.opacity(0.1),
                                    Color.clear,
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: 45
                            )
                        )
                        .frame(width: 90, height: 90)
                        .offset(x: 2, y: 2)
                        .blur(radius: 1)

                    // メインの画像表示
                    if let imageUrl = badge.imageUrl, !imageUrl.isEmpty {
                        // Use AsyncImage for remote URLs
                        AsyncImage(url: URL(string: imageUrl)) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(width: 65, height: 65)
                            case let .success(image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 65, height: 65)
                                    .clipShape(Circle())
                                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
                            case .failure:
                                // Fallback to imageName if URL fails
                                if let imageName = badge.imageName, !imageName.isEmpty {
                                    SimpleImageLoader(imageName: imageName)
                                } else {
                                    fallbackBadgeCircle
                                }
                            @unknown default:
                                fallbackBadgeCircle
                            }
                        }
                    } else if let imageName = badge.imageName, !imageName.isEmpty {
                        // Fallback to local image
                        SimpleImageLoader(imageName: imageName)
                    } else {
                        // No image available
                        fallbackBadgeCircle
                    }

                    // ハイライト効果
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.6),
                                    Color.clear,
                                ]),
                                center: .topLeading,
                                startRadius: 0,
                                endRadius: 25
                            )
                        )
                        .frame(width: 50, height: 50)
                        .offset(x: -10, y: -10)
                        .opacity(0.7)
                }

                Text(badge.name)
                    .font(.caption2)
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingDetail) {
            BadgeDetailView(badge: badge)
        }
    }

    // Fallback view when no image is available
    private var fallbackBadgeCircle: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            badge.color.opacity(0.9),
                            badge.color.opacity(0.7),
                            badge.color.opacity(0.5),
                            badge.color.opacity(0.3),
                        ]),
                        center: .topLeading,
                        startRadius: 7,
                        endRadius: 40
                    )
                )
                .frame(width: 80, height: 80)
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.8),
                                    Color.white.opacity(0.3),
                                    Color.clear,
                                    Color.black.opacity(0.2),
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )

            Image(systemName: "photo")
                .font(.title2)
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
        }
    }
}

// MARK: - 画像ローダーコンポーネント

struct SimpleImageLoader: View {
    let imageName: String

    var body: some View {
        Image(imageName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 65, height: 65)
            .clipShape(Circle())
            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
    }
}

#Preview("ホーム画面") {
    BadgeCollectionView(
        badges: [
            Badge(id: "1", name: "後楽園", icon: "building.2.fill", color: Badge.randomColor, isUnlocked: true, imageName: "korakuen", imageUrl: nil, badgeNumber: "B001", address: "東京都文京区後楽1-3-61", municipality: "文京区", isShelter: true, isFlood: true, isLandslide: false, isStormSurge: false, isEarthquake: true, isTsunami: false, isFire: true, isInlandFlood: true, isVolcano: false, latitude: 35.7056, longitude: 139.7514, firstUserName: "Taro Yamada"),
            Badge(id: "2", name: "東大前", icon: "house.fill", color: Badge.randomColor, isUnlocked: true, imageName: "todaimae", imageUrl: nil, badgeNumber: "B002", address: "東京都文京区本郷7-3-1", municipality: "文京区", isShelter: true, isFlood: false, isLandslide: false, isStormSurge: false, isEarthquake: true, isTsunami: false, isFire: true, isInlandFlood: false, isVolcano: false, latitude: 35.7123, longitude: 139.7614, firstUserName: nil),
            Badge(id: "3", name: "ロゴ", icon: "exclamationmark.triangle.fill", color: Badge.randomColor, isUnlocked: true, imageName: "logo", imageUrl: nil, badgeNumber: "B003", address: "東京都文京区湯島3-30-1", municipality: "文京区", isShelter: true, isFlood: true, isLandslide: true, isStormSurge: false, isEarthquake: true, isTsunami: false, isFire: true, isInlandFlood: false, isVolcano: false, latitude: 35.7081, longitude: 139.7686, firstUserName: nil),
            Badge(id: "4", name: "避難所D", icon: "checkmark.circle.fill", color: Badge.randomColor, isUnlocked: true, imageName: nil, imageUrl: nil, badgeNumber: "B004", address: "東京都文京区千駄木2-19-1", municipality: "文京区", isShelter: true, isFlood: false, isLandslide: false, isStormSurge: false, isEarthquake: true, isTsunami: false, isFire: true, isInlandFlood: false, isVolcano: false, latitude: 35.7265, longitude: 139.7610, firstUserName: nil),
            Badge(id: "5", name: "避難所E", icon: "heart.fill", color: Badge.randomColor, isUnlocked: true, imageName: nil, imageUrl: nil, badgeNumber: "B005", address: "東京都文京区根津1-28-9", municipality: "文京区", isShelter: true, isFlood: true, isLandslide: false, isStormSurge: false, isEarthquake: true, isTsunami: false, isFire: true, isInlandFlood: true, isVolcano: false, latitude: 35.7180, longitude: 139.7650, firstUserName: nil),
            Badge(id: "6", name: "避難所F", icon: "leaf.fill", color: Badge.randomColor, isUnlocked: true, imageName: nil, imageUrl: nil, badgeNumber: "B006", address: "東京都文京区小石川5-40-18", municipality: "文京区", isShelter: true, isFlood: false, isLandslide: true, isStormSurge: false, isEarthquake: true, isTsunami: false, isFire: true, isInlandFlood: false, isVolcano: false, latitude: 35.7230, longitude: 139.7380, firstUserName: nil),
        ],
        stats: (total: 2303, unlocked: 12)
    )
}

#Preview("すべて表示画面") {
    BadgeCollectionDetailView(badges: [
        Badge(id: "1", name: "後楽園", icon: "star.fill", color: Badge.randomColor, isUnlocked: true, imageName: "korakuen", imageUrl: nil, badgeNumber: "B001", address: "東京都文京区後楽1-3-61", municipality: "文京区", isShelter: true, isFlood: true, isLandslide: false, isStormSurge: false, isEarthquake: true, isTsunami: false, isFire: true, isInlandFlood: true, isVolcano: false, latitude: 35.7056, longitude: 139.7514, firstUserName: "Taro Yamada"),
        Badge(id: "2", name: "東大前", icon: "house.fill", color: Badge.randomColor, isUnlocked: true, imageName: "todaimae", imageUrl: nil, badgeNumber: "B002", address: "東京都文京区本郷7-3-1", municipality: "文京区", isShelter: true, isFlood: false, isLandslide: false, isStormSurge: false, isEarthquake: true, isTsunami: false, isFire: true, isInlandFlood: false, isVolcano: false, latitude: 35.7123, longitude: 139.7614, firstUserName: nil),
        Badge(id: "3", name: "ロゴ", icon: "timer", color: Badge.randomColor, isUnlocked: true, imageName: "logo", imageUrl: nil, badgeNumber: "B003", address: "東京都文京区湯島3-30-1", municipality: "文京区", isShelter: true, isFlood: true, isLandslide: true, isStormSurge: false, isEarthquake: true, isTsunami: false, isFire: true, isInlandFlood: false, isVolcano: false, latitude: 35.7081, longitude: 139.7686, firstUserName: nil),
        Badge(id: "4", name: "避難所D", icon: "checkmark.circle.fill", color: Badge.randomColor, isUnlocked: true, imageName: nil, imageUrl: nil, badgeNumber: "B004", address: "東京都文京区千駄木2-19-1", municipality: "文京区", isShelter: true, isFlood: false, isLandslide: false, isStormSurge: false, isEarthquake: true, isTsunami: false, isFire: true, isInlandFlood: false, isVolcano: false, latitude: 35.7265, longitude: 139.7610, firstUserName: nil),
        Badge(id: "5", name: "避難所E", icon: "heart.fill", color: Badge.randomColor, isUnlocked: true, imageName: nil, imageUrl: nil, badgeNumber: "B005", address: "東京都文京区根津1-28-9", municipality: "文京区", isShelter: true, isFlood: true, isLandslide: false, isStormSurge: false, isEarthquake: true, isTsunami: false, isFire: true, isInlandFlood: true, isVolcano: false, latitude: 35.7180, longitude: 139.7650, firstUserName: nil),
        Badge(id: "6", name: "避難所F", icon: "leaf.fill", color: Badge.randomColor, isUnlocked: true, imageName: nil, imageUrl: nil, badgeNumber: "B006", address: "東京都文京区小石川5-40-18", municipality: "文京区", isShelter: true, isFlood: false, isLandslide: true, isStormSurge: false, isEarthquake: true, isTsunami: false, isFire: true, isInlandFlood: false, isVolcano: false, latitude: 35.7230, longitude: 139.7380, firstUserName: nil),
        Badge(id: "7", name: "避難所G", icon: "building.2.fill", color: Badge.randomColor, isUnlocked: true, imageName: nil, imageUrl: nil, badgeNumber: "B007", address: "東京都文京区春日1-16-21", municipality: "文京区", isShelter: true, isFlood: true, isLandslide: false, isStormSurge: false, isEarthquake: true, isTsunami: false, isFire: true, isInlandFlood: false, isVolcano: false, latitude: 35.7071, longitude: 139.7527, firstUserName: nil),
        Badge(id: "8", name: "避難所H", icon: "tree.fill", color: Badge.randomColor, isUnlocked: true, imageName: nil, imageUrl: nil, badgeNumber: "B008", address: "東京都文京区白山1-33-20", municipality: "文京区", isShelter: true, isFlood: false, isLandslide: true, isStormSurge: false, isEarthquake: true, isTsunami: false, isFire: true, isInlandFlood: false, isVolcano: false, latitude: 35.7246, longitude: 139.7425, firstUserName: nil),
        Badge(id: "9", name: "避難所I", icon: "mountain.2.fill", color: Badge.randomColor, isUnlocked: true, imageName: nil, imageUrl: nil, badgeNumber: "B009", address: "東京都文京区向丘2-1-18", municipality: "文京区", isShelter: true, isFlood: true, isLandslide: false, isStormSurge: false, isEarthquake: true, isTsunami: false, isFire: true, isInlandFlood: true, isVolcano: false, latitude: 35.7194, longitude: 139.7725, firstUserName: nil),
        Badge(id: "10", name: "避難所J", icon: "water.waves", color: Badge.randomColor, isUnlocked: true, imageName: nil, imageUrl: nil, badgeNumber: "B010", address: "東京都文京区水道2-6-3", municipality: "文京区", isShelter: true, isFlood: false, isLandslide: false, isStormSurge: false, isEarthquake: true, isTsunami: true, isFire: true, isInlandFlood: false, isVolcano: false, latitude: 35.7304, longitude: 139.7439, firstUserName: nil),
    ])
}
