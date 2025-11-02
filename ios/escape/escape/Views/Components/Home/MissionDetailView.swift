//
//  MissionDetailView.swift
//  escape
//
//  Created by YoungJune Kang on 2025/10/25.
//

import SwiftUI

// MARK: - ミッション詳細ビュー

struct MissionDetailView: View {
    let mission: Mission?
    @Binding var selectedTab: Tab
    @Binding var isPresented: Bool
    @Environment(\.dismiss) private var dismiss
    @Environment(\.missionStateService) private var missionStateService
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
        if let currentMission = missionStateService.currentMission,
           let thisMission = mission
        {
            return currentMission.id == thisMission.id
        }
        return false
    }

    private func startMission() {
        guard let mission = mission else { return }

        // Update global mission state
        missionStateService.updateMission(mission)

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
        missionStateService.resetMission()

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
            status: .active,
            createdAt: Date()
        ),
        selectedTab: .constant(.home),
        isPresented: .constant(true)
    )
}
