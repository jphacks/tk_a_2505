//
//  StatsView.swift
//  escape
//
//  Created by Claude on 11/10/2568 BE.
//

import SwiftUI

// MARK: - 統計ビュー

struct StatsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("home.stats.title", tableName: "Localizable")
                .font(.headline)

            HStack(spacing: 20) {
                StatItemView(
                    title: String(localized: "home.stats.completed_missions", table: "Localizable"),
                    value: "5",
                    icon: "checkmark.circle.fill",
                    color: Color("brandMediumBlue")
                )

                StatItemView(
                    title: String(localized: "home.stats.distance_walked", table: "Localizable"),
                    value: "3.2km",
                    icon: "figure.walk",
                    color: Color("brandDarkBlue")
                )

                StatItemView(
                    title: String(localized: "home.stats.badges_earned", table: "Localizable"),
                    value: "2",
                    icon: "star.fill",
                    color: Color("brandOrange")
                )
            }
        }
    }
}

// MARK: - 統計アイテムビュー

struct StatItemView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    StatsView()
}
