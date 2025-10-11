//
//  HomeView.swift
//  escape
//
//  Created by Thanasan Kumdee on 11/10/2568 BE.
//

import SwiftUI

struct HomeView: View {
    @State private var currentMission: Mission? = nil
    @State private var userBadges: [Badge] = []
    @State private var showingMissionDetail = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // ヘッダー
                    HStack {
                        Text("HiNan!")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)

                        Spacer()

                        Image(systemName: "person.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal)

                    // 現在のミッション セクション
                    MissionCardView(mission: currentMission) {
                        showingMissionDetail = true
                    }
                    .padding(.horizontal)

                    // バッジコレクション セクション
                    BadgeCollectionView(badges: userBadges)
                        .padding(.horizontal)

                    // 統計情報
                    StatsView()
                        .padding(.horizontal)
                }
                .padding(.top)
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingMissionDetail) {
                MissionDetailView(mission: currentMission)
            }
            .onAppear {
                loadCurrentMission()
                loadUserBadges()
            }
        }
    }

    private func loadCurrentMission() {
        // TODO: Supabaseから現在のミッションを取得
        currentMission = Mission(
            id: "1",
            title: "震度6強の地震発生！避難所へ緊急避難せよ",
            name: "緊急地震避難訓練",
            description: "AI解析により、マグニチュード7.2の大地震が発生したシナリオが生成されました。建物の倒壊や火災の危険があります。最寄りの避難所まで安全なルートで避難してください。",
            disasterType: .earthquake,
            estimatedDuration: 15,
            distance: 800,
            severity: .critical,
            isUrgent: true,
            aiGeneratedAt: Date()
        )
    }

    private func loadUserBadges() {
        // TODO: Supabaseからユーザーのバッジを取得
        userBadges = [
            Badge(id: "1", name: "初回避難", icon: "star.fill", color: .yellow, isUnlocked: true),
            Badge(id: "2", name: "地震マスター", icon: "house.fill", color: .blue, isUnlocked: true),
            Badge(id: "3", name: "スピードランナー", icon: "timer", color: .green, isUnlocked: false),
            Badge(id: "4", name: "完璧主義者", icon: "checkmark.circle.fill", color: .purple, isUnlocked: false),
        ]
    }
}

#Preview("HomeView - English") {
    HomeView().environment(\.locale, .init(identifier: "en"))
}

#Preview("HomeView - Japanese") {
    HomeView().environment(\.locale, .init(identifier: "ja"))
}
