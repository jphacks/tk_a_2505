//
//  StatsViews.swift
//  escape
//
//  Created by Claude on 11/10/2568 BE.
//

import SwiftUI

// MARK: - 統計ビュー

struct StatsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("今週の統計")
                .font(.headline)

            HStack(spacing: 20) {
                StatItemView(
                    title: "完了したミッション",
                    value: "5",
                    icon: "checkmark.circle.fill",
                    color: .green
                )

                StatItemView(
                    title: "歩いた距離",
                    value: "3.2km",
                    icon: "figure.walk",
                    color: .blue
                )

                StatItemView(
                    title: "獲得バッジ",
                    value: "2",
                    icon: "star.fill",
                    color: .orange
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
