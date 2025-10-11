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
                            .foregroundColor(Color("brandOrange"))

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
            id: UUID(),
            userId: UUID(),
            title: "震度6強の地震発生！避難所へ緊急避難せよ",
            overview: "AI解析により、マグニチュード7.2の大地震が発生したシナリオが生成されました。建物の倒壊や火災の危険があります。最寄りの避難所まで安全なルートで避難してください。",
            disasterType: .earthquake,
            evacuationRegion: "文京区",
            status: .active,
            steps: nil,
            distances: nil,
            createdAt: Date()
        )
    }

    private func loadUserBadges() {
        // TODO: Supabaseからユーザーのバッジを取得
        let sampleBadges = [
            ("1", "後楽園", "star.fill", "korakuen", "B001", "東京都文京区後楽1-3-61", "文京区", true, true, false, false, true, false, true, true, false, 35.7056, 139.7514),
            ("2", "東大前", "house.fill", "todaimae", "B002", "東京都文京区本郷7-3-1", "文京区", true, false, false, false, true, false, true, false, false, 35.7123, 139.7614),
            ("3", "ロゴ", "timer", "logo", "B003", "東京都文京区湯島3-30-1", "文京区", true, true, true, false, true, false, true, false, false, 35.7081, 139.7686),
            ("4", "避難所D", "checkmark.circle.fill", nil, "B004", "東京都文京区千駄木2-19-1", "文京区", true, false, false, false, true, false, true, false, false, 35.7265, 139.7610),
        ]

        userBadges = sampleBadges.map { sample in
            Badge(
                id: sample.0,
                name: sample.1,
                icon: sample.2,
                color: Badge.randomColor,
                isUnlocked: true,
                imageName: sample.3,
                badgeNumber: sample.4,
                address: sample.5,
                municipality: sample.6,
                isShelter: sample.7,
                isFlood: sample.8,
                isLandslide: sample.9,
                isStormSurge: sample.10,
                isEarthquake: sample.11,
                isTsunami: sample.12,
                isFire: sample.13,
                isInlandFlood: sample.14,
                isVolcano: sample.15,
                latitude: sample.16,
                longitude: sample.17
            )
        }
    }
}

#Preview("HomeView - English") {
    HomeView().environment(\.locale, .init(identifier: "en"))
}

#Preview("HomeView - Japanese") {
    HomeView().environment(\.locale, .init(identifier: "ja"))
}
