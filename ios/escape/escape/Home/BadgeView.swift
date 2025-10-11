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
            .navigationTitle(String(localized: "home.badge_collection.title", table: "Localizable"))
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    BadgeCollectionView(badges: [
        Badge(id: "1", name: "sample1", icon: "star.fill", color: Color("brandOrange"), isUnlocked: true),
        Badge(id: "2", name: "sample2", icon: "house.fill", color: Color("brandDarkBlue"), isUnlocked: true),
        Badge(id: "3", name: "sample3", icon: "timer", color: Color("brandMediumBlue"), isUnlocked: false),
        Badge(id: "4", name: "sample4", icon: "checkmark.circle.fill", color: Color("brandRed"), isUnlocked: false),
    ])
}
