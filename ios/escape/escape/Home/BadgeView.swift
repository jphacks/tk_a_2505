//
//  BadgeView.swift
//  escape
//
//  Created by Claude on 11/10/2568 BE.
//

import SwiftUI

// MARK: - バッジコレクションビュー

struct BadgeCollectionView: View {
    let badges: [Badge]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("home.badge_collection.title", tableName: "Localizable")
                    .font(.headline)

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

// MARK: - バッジホームアイテムビュー（4列×2行用）

struct BadgeHomeItemView: View {
    let badge: Badge

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(badge.color.opacity(0.2))
                    .frame(width: 60, height: 60)

                if let imageName = badge.imageName, !imageName.isEmpty {
                    Image(imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "photo")
                        .font(.title2)
                        .foregroundColor(badge.color)
                }
            }

            Text(badge.name)
                .font(.caption2)
                .foregroundColor(.primary)
                .lineLimit(1)
        }
    }
}

// MARK: - バッジアイテムビュー（詳細画面用）

struct BadgeItemView: View {
    let badge: Badge

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(badge.color.opacity(0.2))
                    .frame(width: 80, height: 80)

                if let imageName = badge.imageName, !imageName.isEmpty {
                    Image(imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "photo")
                        .font(.title)
                        .foregroundColor(badge.color)
                }
            }

            Text(badge.name)
                .font(.caption)
                .foregroundColor(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - バッジコレクション詳細ビュー

struct BadgeCollectionDetailView: View {
    let badges: [Badge]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 30) {
                    ForEach(badges) { badge in
                        BadgeCardButton(badge: badge)
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

    var body: some View {
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
                            endRadius: 35
                        )
                    )
                    .frame(width: 70, height: 70)
                    .offset(x: 2, y: 2)
                    .blur(radius: 1)

                // メインの画像表示
                if let imageName = badge.imageName, !imageName.isEmpty {
                    SimpleImageLoader(imageName: imageName)
                } else {
                    // 画像がない場合のみ背景円形を表示
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
                        .frame(width: 60, height: 60)
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
                            endRadius: 20
                        )
                    )
                    .frame(width: 40, height: 40)
                    .offset(x: -8, y: -8)
                    .opacity(0.7)
            }

            Text(badge.name)
                .font(.caption2)
                .foregroundColor(.primary)
                .lineLimit(1)
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
            .frame(width: 50, height: 50)
            .clipShape(Circle())
            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
    }
}

#Preview("ホーム画面") {
    BadgeCollectionView(badges: [
        Badge(id: "1", name: "後楽園", icon: "building.2.fill", color: Color("brandOrange"), isUnlocked: true, imageName: "korakuen", badgeNumber: "B001", address: "東京都文京区後楽1-3-61", municipality: "文京区", isShelter: true, isFlood: true, isLandslide: false, isStormSurge: false, isEarthquake: true, isTsunami: false, isFire: true, isInlandFlood: true, isVolcano: false, latitude: 35.7056, longitude: 139.7514),
        Badge(id: "2", name: "東大前", icon: "house.fill", color: Color("brandDarkBlue"), isUnlocked: true, imageName: "todaimae", badgeNumber: "B002", address: "東京都文京区本郷7-3-1", municipality: "文京区", isShelter: true, isFlood: false, isLandslide: false, isStormSurge: false, isEarthquake: true, isTsunami: false, isFire: true, isInlandFlood: false, isVolcano: false, latitude: 35.7123, longitude: 139.7614),
        Badge(id: "3", name: "ロゴ", icon: "exclamationmark.triangle.fill", color: Color("brandMediumBlue"), isUnlocked: true, imageName: "logo", badgeNumber: "B003", address: "東京都文京区湯島3-30-1", municipality: "文京区", isShelter: true, isFlood: true, isLandslide: true, isStormSurge: false, isEarthquake: true, isTsunami: false, isFire: true, isInlandFlood: false, isVolcano: false, latitude: 35.7081, longitude: 139.7686),
        Badge(id: "4", name: "避難所D", icon: "checkmark.circle.fill", color: Color("brandRed"), isUnlocked: true, imageName: nil, badgeNumber: "B004", address: "東京都文京区千駄木2-19-1", municipality: "文京区", isShelter: true, isFlood: false, isLandslide: false, isStormSurge: false, isEarthquake: true, isTsunami: false, isFire: true, isInlandFlood: false, isVolcano: false, latitude: 35.7265, longitude: 139.7610),
        Badge(id: "5", name: "避難所E", icon: "heart.fill", color: Color("brandPeach"), isUnlocked: true, imageName: nil, badgeNumber: "B005", address: "東京都文京区根津1-28-9", municipality: "文京区", isShelter: true, isFlood: true, isLandslide: false, isStormSurge: false, isEarthquake: true, isTsunami: false, isFire: true, isInlandFlood: true, isVolcano: false, latitude: 35.7180, longitude: 139.7650),
        Badge(id: "6", name: "避難所F", icon: "leaf.fill", color: Color.green, isUnlocked: true, imageName: nil, badgeNumber: "B006", address: "東京都文京区小石川5-40-18", municipality: "文京区", isShelter: true, isFlood: false, isLandslide: true, isStormSurge: false, isEarthquake: true, isTsunami: false, isFire: true, isInlandFlood: false, isVolcano: false, latitude: 35.7230, longitude: 139.7380),
    ])
}

#Preview("すべて表示画面") {
    BadgeCollectionDetailView(badges: [
        Badge(id: "1", name: "後楽園", icon: "star.fill", color: Color("brandOrange"), isUnlocked: true, imageName: "korakuen", badgeNumber: "B001", address: "東京都文京区後楽1-3-61", municipality: "文京区", isShelter: true, isFlood: true, isLandslide: false, isStormSurge: false, isEarthquake: true, isTsunami: false, isFire: true, isInlandFlood: true, isVolcano: false, latitude: 35.7056, longitude: 139.7514),
        Badge(id: "2", name: "東大前", icon: "house.fill", color: Color("brandDarkBlue"), isUnlocked: true, imageName: "todaimae", badgeNumber: "B002", address: "東京都文京区本郷7-3-1", municipality: "文京区", isShelter: true, isFlood: false, isLandslide: false, isStormSurge: false, isEarthquake: true, isTsunami: false, isFire: true, isInlandFlood: false, isVolcano: false, latitude: 35.7123, longitude: 139.7614),
        Badge(id: "3", name: "ロゴ", icon: "timer", color: Color("brandMediumBlue"), isUnlocked: true, imageName: "logo", badgeNumber: "B003", address: "東京都文京区湯島3-30-1", municipality: "文京区", isShelter: true, isFlood: true, isLandslide: true, isStormSurge: false, isEarthquake: true, isTsunami: false, isFire: true, isInlandFlood: false, isVolcano: false, latitude: 35.7081, longitude: 139.7686),
        Badge(id: "4", name: "避難所D", icon: "checkmark.circle.fill", color: Color("brandRed"), isUnlocked: true, imageName: nil, badgeNumber: "B004", address: "東京都文京区千駄木2-19-1", municipality: "文京区", isShelter: true, isFlood: false, isLandslide: false, isStormSurge: false, isEarthquake: true, isTsunami: false, isFire: true, isInlandFlood: false, isVolcano: false, latitude: 35.7265, longitude: 139.7610),
        Badge(id: "5", name: "避難所E", icon: "heart.fill", color: Color("brandPeach"), isUnlocked: true, imageName: nil, badgeNumber: "B005", address: "東京都文京区根津1-28-9", municipality: "文京区", isShelter: true, isFlood: true, isLandslide: false, isStormSurge: false, isEarthquake: true, isTsunami: false, isFire: true, isInlandFlood: true, isVolcano: false, latitude: 35.7180, longitude: 139.7650),
        Badge(id: "6", name: "避難所F", icon: "leaf.fill", color: Color.green, isUnlocked: true, imageName: nil, badgeNumber: "B006", address: "東京都文京区小石川5-40-18", municipality: "文京区", isShelter: true, isFlood: false, isLandslide: true, isStormSurge: false, isEarthquake: true, isTsunami: false, isFire: true, isInlandFlood: false, isVolcano: false, latitude: 35.7230, longitude: 139.7380),
        Badge(id: "7", name: "避難所G", icon: "building.2.fill", color: Color.purple, isUnlocked: true, imageName: nil, badgeNumber: "B007", address: "東京都文京区春日1-16-21", municipality: "文京区", isShelter: true, isFlood: true, isLandslide: false, isStormSurge: false, isEarthquake: true, isTsunami: false, isFire: true, isInlandFlood: false, isVolcano: false, latitude: 35.7071, longitude: 139.7527),
        Badge(id: "8", name: "避難所H", icon: "tree.fill", color: Color.brown, isUnlocked: true, imageName: nil, badgeNumber: "B008", address: "東京都文京区白山1-33-20", municipality: "文京区", isShelter: true, isFlood: false, isLandslide: true, isStormSurge: false, isEarthquake: true, isTsunami: false, isFire: true, isInlandFlood: false, isVolcano: false, latitude: 35.7246, longitude: 139.7425),
        Badge(id: "9", name: "避難所I", icon: "mountain.2.fill", color: Color.gray, isUnlocked: true, imageName: nil, badgeNumber: "B009", address: "東京都文京区向丘2-1-18", municipality: "文京区", isShelter: true, isFlood: true, isLandslide: false, isStormSurge: false, isEarthquake: true, isTsunami: false, isFire: true, isInlandFlood: true, isVolcano: false, latitude: 35.7194, longitude: 139.7725),
        Badge(id: "10", name: "避難所J", icon: "water.waves", color: Color.blue, isUnlocked: true, imageName: nil, badgeNumber: "B010", address: "東京都文京区水道2-6-3", municipality: "文京区", isShelter: true, isFlood: false, isLandslide: false, isStormSurge: false, isEarthquake: true, isTsunami: true, isFire: true, isInlandFlood: false, isVolcano: false, latitude: 35.7304, longitude: 139.7439),
    ])
}
