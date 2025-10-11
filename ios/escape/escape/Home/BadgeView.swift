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
                        InteractiveImageLoader(imageName: imageName)
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

// MARK: - 詳細画面用回転可能バッジビュー

struct RotatableBadgeView: View {
    let badge: Badge
    @State private var isFlipped = false
    @State private var rotationAngle: Double = 0

    var body: some View {
        ZStack {
            if !isFlipped {
                // 前面
                DetailBadgeFrontView(badge: badge)
            } else {
                // 背面
                DetailBadgeBackView(badge: badge)
                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            }
        }
        .rotation3DEffect(.degrees(rotationAngle), axis: (x: 0, y: 1, z: 0))
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.8)) {
                rotationAngle += 180
                isFlipped.toggle()
            }
        }
        .frame(width: 150, height: 150)
    }
}

// MARK: - バッジ前面ビュー

struct DetailBadgeFrontView: View {
    let badge: Badge

    var body: some View {
        ZStack {
            // 背景の影
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
                        endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)
                .offset(x: 5, y: 5)
                .blur(radius: 3)

            // メインの画像表示
            if let imageName = badge.imageName, !imageName.isEmpty {
                DetailImageLoader(imageName: imageName)
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
                                startRadius: 10,
                                endRadius: 60
                            )
                        )
                        .frame(width: 150, height: 150)
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
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 2)
                }
            }

            // ハイライト効果
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.8),
                            Color.white.opacity(0.3),
                            Color.clear,
                        ]),
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: 50
                    )
                )
                .frame(width: 100, height: 100)
                .offset(x: -15, y: -15)
                .opacity(0.7)
        }
    }
}

// MARK: - バッジ背面ビュー

struct DetailBadgeBackView: View {
    let badge: Badge

    var body: some View {
        ZStack {
            // 背景の影
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
                        endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)
                .offset(x: 5, y: 5)
                .blur(radius: 3)

            // 背面の暗い円
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.black.opacity(0.9),
                            Color.black.opacity(0.7),
                            Color.black.opacity(0.5),
                        ]),
                        center: .center,
                        startRadius: 10,
                        endRadius: 75
                    )
                )
                .frame(width: 150, height: 150)
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.gray.opacity(0.6),
                                    Color.gray.opacity(0.3),
                                    Color.clear,
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )

            // 背面の情報表示
            VStack(spacing: 8) {
                if badge.isUnlocked {
                    Text("取得者")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))

                    Text("getter_name")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text("取得日")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.top, 4)

                    Text(dateFormatter.string(from: Date()))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                } else {
                    Image(systemName: "lock.fill")
                        .font(.title)
                        .foregroundColor(.white.opacity(0.5))

                    Text("未取得")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }
}

// MARK: - 詳細画面用画像ローダー

struct DetailImageLoader: View {
    let imageName: String

    var body: some View {
        Group {
            if let uiImage = UIImage(named: imageName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 4)
            } else if let bundlePath = Bundle.main.path(forResource: imageName, ofType: "png"),
                      let uiImage = UIImage(contentsOfFile: bundlePath)
            {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 4)
            } else {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 4)
            }
        }
    }
}

// MARK: - バッジ詳細ビュー

struct BadgeDetailView: View {
    let badge: Badge
    @Environment(\.dismiss) private var dismiss
    @State private var isAnimating = false

    var body: some View {
        NavigationStack {
            ZStack {
                // 背景グラデーション
                LinearGradient(
                    gradient: Gradient(colors: [badge.color, badge.color.opacity(0.7)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // ヘッダーセクション
                        VStack(spacing: 16) {
                            // 回転可能なバッジ
                            RotatableBadgeView(badge: badge)
                                .scaleEffect(isAnimating ? 1.05 : 1.0)
                                .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isAnimating)

                            VStack(alignment: .leading, spacing: 8) {
                                if badge.isUnlocked {
                                    Text("取得済み")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white.opacity(0.9))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.white.opacity(0.25))
                                        .cornerRadius(12)
                                } else {
                                    Text("未取得")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white.opacity(0.9))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.white.opacity(0.25))
                                        .cornerRadius(12)
                                }

                                Text(badge.name)
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.leading)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 20)

                        // 詳細情報セクション
                        VStack(spacing: 20) {
                            // バッジ情報
                            VStack(alignment: .leading, spacing: 12) {
                                Text("バッジについて")
                                    .font(.headline)
                                    .foregroundColor(.white)

                                Text("このバッジは特定の場所を訪れることで獲得できます。探索を続けて、より多くのバッジを集めましょう！")
                                    .font(.body)
                                    .foregroundColor(.white.opacity(0.9))
                                    .lineSpacing(4)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(20)
                            .background(Color.white.opacity(0.15))
                            .cornerRadius(16)

                            // ステータス情報
                            VStack(alignment: .leading, spacing: 8) {
                                Text("ステータス")
                                    .font(.headline)
                                    .foregroundColor(.white)

                                HStack {
                                    Image(systemName: badge.isUnlocked ? "checkmark.circle.fill" : "lock.circle.fill")
                                        .foregroundColor(.white.opacity(0.8))

                                    Text(badge.isUnlocked ? "取得済み" : "未取得")
                                        .font(.body)
                                        .foregroundColor(.white.opacity(0.9))
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(20)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(16)
                        }
                        .padding(.horizontal, 24)

                        if !badge.isUnlocked {
                            // アクションボタン
                            VStack(spacing: 16) {
                                Button(action: {
                                    // TODO: バッジ取得処理
                                }) {
                                    HStack {
                                        Image(systemName: "location.circle.fill")
                                            .font(.title2)

                                        Text("このバッジを探しに行く")
                                            .font(.headline)
                                            .fontWeight(.bold)
                                    }
                                    .foregroundColor(badge.color)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.white)
                                    .cornerRadius(16)
                                }
                                .scaleEffect(isAnimating ? 1.05 : 1.0)
                                .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: isAnimating)
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 40)
                        } else {
                            Spacer(minLength: 40)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                isAnimating = true
            }
        }
    }
}

#Preview("ホーム画面") {
    BadgeCollectionView(badges: [
        Badge(id: "1", name: "後楽園", icon: "building.2.fill", color: Color("brandOrange"), isUnlocked: true, imageName: "korakuen"),
        Badge(id: "2", name: "東大前", icon: "house.fill", color: Color("brandDarkBlue"), isUnlocked: true, imageName: "todaimae"),
        Badge(id: "3", name: "ロゴ", icon: "exclamationmark.triangle.fill", color: Color("brandMediumBlue"), isUnlocked: true, imageName: "logo"),
        Badge(id: "4", name: "避難所D", icon: "checkmark.circle.fill", color: Color("brandRed"), isUnlocked: true, imageName: nil),
        Badge(id: "5", name: "避難所E", icon: "heart.fill", color: Color("brandPeach"), isUnlocked: true, imageName: nil),
        Badge(id: "6", name: "避難所F", icon: "leaf.fill", color: Color.green, isUnlocked: true, imageName: nil),
    ])
}

#Preview("すべて表示画面") {
    BadgeCollectionDetailView(badges: [
        Badge(id: "1", name: "後楽園", icon: "star.fill", color: Color("brandOrange"), isUnlocked: true, imageName: "korakuen"),
        Badge(id: "2", name: "東大前", icon: "house.fill", color: Color("brandDarkBlue"), isUnlocked: true, imageName: "todaimae"),
        Badge(id: "3", name: "ロゴ", icon: "timer", color: Color("brandMediumBlue"), isUnlocked: true, imageName: "logo"),
        Badge(id: "4", name: "避難所D", icon: "checkmark.circle.fill", color: Color("brandRed"), isUnlocked: true, imageName: nil),
        Badge(id: "5", name: "避難所E", icon: "heart.fill", color: Color("brandPeach"), isUnlocked: true, imageName: nil),
        Badge(id: "6", name: "避難所F", icon: "leaf.fill", color: Color.green, isUnlocked: true, imageName: nil),
        Badge(id: "7", name: "避難所G", icon: "building.2.fill", color: Color.purple, isUnlocked: true, imageName: nil),
        Badge(id: "8", name: "避難所H", icon: "tree.fill", color: Color.brown, isUnlocked: true, imageName: nil),
        Badge(id: "9", name: "避難所I", icon: "mountain.2.fill", color: Color.gray, isUnlocked: true, imageName: nil),
        Badge(id: "10", name: "避難所J", icon: "water.waves", color: Color.blue, isUnlocked: true, imageName: nil),
    ])
}
