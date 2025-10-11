//
//  BadgeViews.swift
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
                Text("バッジコレクション")
                    .font(.headline)

                Spacer()

                NavigationLink("すべて見る") {
                    BadgeCollectionDetailView(badges: badges)
                }
                .font(.caption)
                .foregroundColor(.orange)
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                ForEach(badges.prefix(8)) { badge in
                    BadgeItemView(badge: badge)
                }
            }
        }
    }
}

// MARK: - バッジアイテムビュー

struct BadgeItemView: View {
    let badge: Badge

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(badge.isUnlocked ? badge.color.opacity(0.2) : Color(.systemGray5))
                    .frame(width: 60, height: 60)

                Image(systemName: badge.icon)
                    .font(.title2)
                    .foregroundColor(badge.isUnlocked ? badge.color : .gray)
            }

            Text(badge.name)
                .font(.caption2)
                .foregroundColor(badge.isUnlocked ? .primary : .secondary)
                .lineLimit(1)
        }
        .opacity(badge.isUnlocked ? 1.0 : 0.6)
    }
}

// MARK: - バッジコレクション詳細ビュー

struct BadgeCollectionDetailView: View {
    let badges: [Badge]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 20) {
                    ForEach(badges) { badge in
                        BadgeItemView(badge: badge)
                    }
                }
                .padding()
            }
            .navigationTitle("バッジコレクション")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    BadgeCollectionView(badges: [
        Badge(id: "1", name: "初回避難", icon: "star.fill", color: .yellow, isUnlocked: true),
        Badge(id: "2", name: "地震マスター", icon: "house.fill", color: .blue, isUnlocked: true),
        Badge(id: "3", name: "スピードランナー", icon: "timer", color: .green, isUnlocked: false),
        Badge(id: "4", name: "完璧主義者", icon: "checkmark.circle.fill", color: .purple, isUnlocked: false),
    ])
}
