//
//  MissionCardView.swift
//  escape
//
//  Created by YoungJune Kang on 2025/10/25.
//

import SwiftUI

// MARK: - ミッションカードビュー

struct MissionCardView: View {
    let mission: Mission?
    let onTap: () -> Void
    @State private var isAnimating = false
    @Environment(\.missionStateService) private var missionStateService

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    // Active mission indicator (only shown when mission is active in global state)
                    if let mission = mission,
                       let currentMission = missionStateService.currentMission,
                       mission.id == currentMission.id
                    {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color("brandOrange"))
                                .frame(width: 8, height: 8)
                                .shadow(color: Color("brandOrange").opacity(0.5), radius: 4, x: 0, y: 0)

                            Text("home.mission.activated", tableName: "Localizable")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(Color("brandOrange"))
                        }
                    }

                    Text("home.mission.todays_mission", tableName: "Localizable")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }

                Spacer()
            }

            if let mission = mission,
               let _ = mission.disasterType,
               mission.status != .completed
            {
                Button(action: onTap) {
                    ZStack {
                        // グラデーション背景
                        LinearGradient(
                            gradient: Gradient(colors: mission.disasterType?.gradientColors ?? [Color("brandOrange"), Color("brandRed")]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .cornerRadius(20)

                        // コンテンツ
                        VStack(alignment: .leading, spacing: 16) {
                            // ヘッダー部分
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Image(systemName: mission.disasterType?.emergencyIcon ?? "exclamationmark.triangle.fill")
                                            .font(.title)
                                            .foregroundColor(.white)

                                        Text(mission.disasterType?.localizedName ?? "Disaster")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white.opacity(0.9))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.white.opacity(0.25))
                                            .cornerRadius(8)
                                    }

                                    Text(mission.title ?? "")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.leading)
                                }

                                Spacer()

                                VStack(spacing: 4) {
                                    Image(systemName: "chevron.right.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }

                            // 説明文
                            Text(mission.overview ?? "")
                                .font(.body)
                                .foregroundColor(.white.opacity(0.9))
                                .lineLimit(3)
                                .multilineTextAlignment(.leading)
                        }
                        .padding(20)
                    }
                    .shadow(color: (mission.disasterType?.color ?? Color("brandOrange")).opacity(0.3), radius: 15, x: 0, y: 8)
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                // ミッション完了状態
                ZStack {
                    LinearGradient(
                        gradient: Gradient(colors: [Color("brandMediumBlue"), Color("brandDarkBlue")]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .cornerRadius(20)

                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.white)

                        Text("home.mission.all_complete", tableName: "Localizable")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)

                        Text("home.mission.next_update", tableName: "Localizable")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                    }
                    .padding(24)
                }
                .shadow(color: Color("brandMediumBlue").opacity(0.3), radius: 15, x: 0, y: 8)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}
