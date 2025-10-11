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
                        Interactive3DBadgeView(badge: badge)
                    }
                }
                .padding()
            }
            .navigationTitle(String(localized: "home.badge_collection.title", table: "Localizable"))
            .navigationBarTitleDisplayMode(.large)
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
