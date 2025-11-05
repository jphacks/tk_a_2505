//
//  TeamRankingView.swift
//  escape
//
//  Created by YoungJune Kang on 2025/11/05.
//

import SwiftUI

struct TeamRankingView: View {
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color("brandMediumBlue").opacity(0.05),
                    Color(.systemBackground),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                // Icon
                Image(systemName: "person.3.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color("brandMediumBlue"), Color("brandOrange")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // Title
                Text("ranking.team_coming_soon")
                    .font(.title2)
                    .fontWeight(.bold)

                // Description
                Text("ranking.team_description")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                // TODO: Badge
                Text("TODO")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color("brandOrange"))
                    )
            }
            .padding()
        }
    }
}
