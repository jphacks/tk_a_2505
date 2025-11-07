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
    @State private var selectedGameMode: GameMode = .default

    var body: some View {
        NavigationStack {
            ZStack {
                if let mission = mission, let _ = mission.disasterType {
                    // 背景グラデーション
                    LinearGradient(
                        gradient: Gradient(
                            colors: mission.disasterType?.gradientColors ?? [
                                Color("brandOrange"), Color("brandRed"),
                            ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()

                    ScrollView {
                        VStack(spacing: 24) {
                            // ヘッダーセクション
                            VStack(spacing: 20) {
                                // タイトルとタイプ
                                VStack(alignment: .leading, spacing: 12) {
                                    Text(mission.title ?? "")
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.leading)
                                        .fixedSize(horizontal: false, vertical: true)

                                    HStack(spacing: 8) {
                                        HStack(spacing: 4) {
                                            Image(
                                                systemName: mission.disasterType?.iconName ?? "exclamationmark.triangle"
                                            )
                                            .font(.system(size: 11))
                                            Text(mission.disasterType?.localizedName ?? "Disaster")
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                        }
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Color.white.opacity(0.25))
                                        .cornerRadius(8)

                                        if isMissionActive {
                                            HStack(spacing: 4) {
                                                Image(systemName: "figure.run")
                                                    .font(.system(size: 10))
                                                Text("In Progress")
                                                    .font(.caption)
                                                    .fontWeight(.semibold)
                                            }
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(Color.green.opacity(0.4))
                                            .cornerRadius(8)
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 20)

                            // 詳細情報セクション
                            VStack(spacing: 16) {
                                // 説明文
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "doc.text.fill")
                                            .font(.subheadline)
                                        Text("home.mission.overview", tableName: "Localizable")
                                            .font(.headline)
                                    }
                                    .foregroundColor(.white)

                                    Text(mission.overview ?? "")
                                        .font(.body)
                                        .foregroundColor(.white.opacity(0.95))
                                        .lineSpacing(6)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(20)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.white.opacity(0.2))
                                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                )
                            }
                            .padding(.horizontal, 24)

                            // ゲームモード選択（ミッションが未開始の場合のみ）
                            if !isMissionActive {
                                VStack(alignment: .leading, spacing: 16) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "gamecontroller.fill")
                                            .font(.subheadline)
                                        Text("home.mission.mode_select", tableName: "Localizable")
                                            .font(.headline)
                                    }
                                    .foregroundColor(.white)

                                    VStack(spacing: 12) {
                                        ForEach([GameMode.default, GameMode.mapless], id: \.self) { mode in
                                            Button(action: {
                                                selectedGameMode = mode
                                            }) {
                                                HStack(alignment: .top, spacing: 12) {
                                                    // モードアイコン
                                                    ZStack {
                                                        RoundedRectangle(cornerRadius: 8)
                                                            .fill(Color.white.opacity(selectedGameMode == mode ? 0.3 : 0.2))
                                                            .frame(width: 44, height: 44)
                                                        Image(systemName: mode == .default ? "map.fill" : "location.north.fill")
                                                            .font(.system(size: 20))
                                                            .foregroundColor(.white)
                                                    }

                                                    VStack(alignment: .leading, spacing: 6) {
                                                        Text(mode.localizedName)
                                                            .font(.subheadline)
                                                            .fontWeight(.bold)
                                                        Text(mode.localizedDescription)
                                                            .font(.caption)
                                                            .foregroundColor(.white.opacity(0.85))
                                                            .multilineTextAlignment(.leading)
                                                            .fixedSize(horizontal: false, vertical: true)
                                                    }

                                                    Spacer()

                                                    // チェックマーク
                                                    Image(
                                                        systemName: selectedGameMode == mode
                                                            ? "checkmark.circle.fill" : "circle"
                                                    )
                                                    .font(.title3)
                                                    .foregroundColor(.white)
                                                }
                                                .foregroundColor(.white)
                                                .padding(16)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 20)
                                                        .fill(
                                                            selectedGameMode == mode
                                                                ? Color.white.opacity(0.25) : Color.white.opacity(0.12)
                                                        )
                                                        .overlay(
                                                            RoundedRectangle(cornerRadius: 20)
                                                                .stroke(
                                                                    Color.white.opacity(selectedGameMode == mode ? 0.4 : 0.0),
                                                                    lineWidth: 2
                                                                )
                                                        )
                                                )
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 24)
                            }

                            // アクションボタン
                            VStack(spacing: 12) {
                                Button(action: {
                                    if isMissionActive {
                                        cancelMission()
                                    } else {
                                        startMission()
                                    }
                                }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: isMissionActive ? "xmark.circle.fill" : "play.circle.fill")
                                            .font(.title2)

                                        Text(
                                            isMissionActive
                                                ? String(localized: "home.mission.cancel", table: "Localizable")
                                                : String(localized: "home.mission.start", table: "Localizable")
                                        )
                                        .font(.title3)
                                        .fontWeight(.bold)
                                    }
                                    .foregroundColor(
                                        isMissionActive
                                            ? Color.white : (mission.disasterType?.color ?? Color("brandOrange"))
                                    )
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 18)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(isMissionActive ? Color.red : Color.white.opacity(0.95))
                                            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color.white.opacity(0.3), lineWidth: isMissionActive ? 0 : 1)
                                    )
                                }
                                .buttonStyle(.plain)
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
        missionStateService.updateGameMode(selectedGameMode)

        print("🚀 Mission started: \(mission.title ?? "Unknown")")
        print("🎮 Game mode: \(selectedGameMode.rawValue)")
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
            overview:
            "AI解析により、マグニチュード7.2の大地震が発生したシナリオが生成されました。建物の倒壊や火災の危険があります。最寄りの避難所まで安全なルートで避難してください。",
            disasterType: .earthquake,
            status: .active,
            createdAt: Date()
        ),
        selectedTab: .constant(.home),
        isPresented: .constant(true)
    )
    .environment(\.missionStateService, MissionStateService())
}
