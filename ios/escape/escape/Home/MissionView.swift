//
//  MissionView.swift
//  escape
//
//  Created by Claude on 11/10/2568 BE.
//

import SwiftUI

// MARK: - ミッションカードビュー

struct MissionCardView: View {
    let mission: Mission?
    let onTap: () -> Void
    @State private var isAnimating = false
    @Environment(\.missionStateManager) private var missionStateManager

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    // Active mission indicator (only shown when mission is active in global state)
                    if let mission = mission,
                       let currentMission = missionStateManager.currentMission,
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

            if let mission = mission, let disasterType = mission.disasterType {
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

// MARK: - ミッションカードコンテンツ

struct MissionCardContent: View {
    let mission: Mission

    var body: some View {
        ZStack {
            // グラデーション背景
            LinearGradient(
                gradient: Gradient(colors: (mission.disasterType?.gradientColors ?? [Color("brandOrange"), Color("brandRed")]) + [.black.opacity(0.3)]),
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
}

// MARK: - ミッション詳細ビュー

struct MissionDetailView: View {
    let mission: Mission?
    @Binding var selectedTab: Tab
    @Binding var isPresented: Bool
    @Environment(\.dismiss) private var dismiss
    @Environment(\.missionStateManager) private var missionStateManager
    @State private var isAnimating = false

    var body: some View {
        NavigationStack {
            ZStack {
                if let mission = mission, let disasterType = mission.disasterType {
                    // 背景グラデーション
                    LinearGradient(
                        gradient: Gradient(colors: mission.disasterType?.gradientColors ?? [Color("brandOrange"), Color("brandRed")]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()

                    ScrollView {
                        VStack(spacing: 24) {
                            // ヘッダーセクション
                            VStack(spacing: 16) {
                                HStack {
                                    Image(systemName: mission.disasterType?.emergencyIcon ?? "exclamationmark.triangle.fill")
                                        .font(.system(size: 60))
                                        .foregroundColor(.white)
                                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)

                                    Spacer()

                                    VStack(alignment: .trailing, spacing: 8) {}
                                }

                                VStack(alignment: .leading, spacing: 8) {
                                    Text(mission.disasterType?.localizedName ?? "Disaster")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white.opacity(0.9))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.white.opacity(0.25))
                                        .cornerRadius(12)

                                    Text(mission.title ?? "")
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
                                // 説明文
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("home.mission.overview", tableName: "Localizable")
                                        .font(.headline)
                                        .foregroundColor(.white)

                                    Text(mission.overview ?? "")
                                        .font(.body)
                                        .foregroundColor(.white.opacity(0.9))
                                        .lineSpacing(4)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(20)
                                .background(Color.white.opacity(0.15))
                                .cornerRadius(16)

                                // ミッション情報
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("home.mission.info", tableName: "Localizable")
                                        .font(.headline)
                                        .foregroundColor(.white)

                                    HStack {
                                        Image(systemName: "calendar")
                                            .foregroundColor(.white.opacity(0.8))

                                        Text(String(localized: "home.mission.date_format", table: "Localizable").replacingOccurrences(of: "%@", with: dateFormatter.string(from: mission.createdAt)))
                                            .font(.body)
                                            .foregroundColor(.white.opacity(0.9))
                                    }

                                    if let evacuationRegion = mission.evacuationRegion {
                                        HStack {
                                            Image(systemName: "location")
                                                .foregroundColor(.white.opacity(0.8))

                                            Text("避難地域: \(evacuationRegion)")
                                                .font(.body)
                                                .foregroundColor(.white.opacity(0.9))
                                        }
                                    }

                                    if let steps = mission.steps {
                                        HStack {
                                            Image(systemName: "figure.walk")
                                                .foregroundColor(.white.opacity(0.8))

                                            Text("歩数: \(steps) 歩")
                                                .font(.body)
                                                .foregroundColor(.white.opacity(0.9))
                                        }
                                    }

                                    if let distance = mission.distances {
                                        HStack {
                                            Image(systemName: "ruler")
                                                .foregroundColor(.white.opacity(0.8))

                                            Text(String(format: "距離: %.1f km", distance))
                                                .font(.body)
                                                .foregroundColor(.white.opacity(0.9))
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(20)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(16)
                            }
                            .padding(.horizontal, 24)

                            // アクションボタン
                            VStack(spacing: 16) {
                                Button(action: {
                                    if isMissionActive {
                                        cancelMission()
                                    } else {
                                        startMission()
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: isMissionActive ? "xmark.circle.fill" : "play.circle.fill")
                                            .font(.title2)

                                        Text(isMissionActive ? String(localized: "home.mission.cancel", table: "Localizable") : String(localized: "home.mission.start", table: "Localizable"))
                                            .font(.headline)
                                            .fontWeight(.bold)
                                    }
                                    .foregroundColor(isMissionActive ? .red : (mission.disasterType?.color ?? Color("brandOrange")))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.white)
                                    .cornerRadius(16)
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 40)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(String(localized: "home.mission.close", table: "Localizable")) {
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

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }

    private var isMissionActive: Bool {
        // Check if current global mission matches this mission
        if let currentMission = missionStateManager.currentMission,
           let thisMission = mission
        {
            return currentMission.id == thisMission.id
        }
        return false
    }

    private func startMission() {
        guard let mission = mission else { return }

        // Update global mission state
        missionStateManager.updateMission(mission)

        print("🚀 Mission started: \(mission.title ?? "Unknown")")
        print("📍 Navigating to map...")

        // Dismiss the sheet
        isPresented = false

        // Small delay to ensure smooth transition
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            // Switch to map tab
            selectedTab = .map
        }
    }

    private func cancelMission() {
        print("❌ Mission cancelled")

        // Reset global mission state
        missionStateManager.resetMission()

        // Dismiss the sheet
        dismiss()
    }
}

#Preview {
    MissionDetailView(
        mission: Mission(
            id: UUID(),
            userId: UUID(),
            title: "震度6強の地震発生！避難所へ緊急避難せよ",
            overview: "AI解析により、マグニチュード7.2の大地震が発生したシナリオが生成されました。建物の倒壊や火災の危険があります。最寄りの避難所まで安全なルートで避難してください。",
            disasterType: .earthquake,
            evacuationRegion: "文京区",
            status: .active,
            steps: 2500,
            distances: 1.2,
            createdAt: Date()
        ),
        selectedTab: .constant(.home),
        isPresented: .constant(true)
    )
}
