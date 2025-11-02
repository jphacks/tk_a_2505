//
//  HomeView.swift
//  escape
//
//  Created by YoungJune Kang on 2025/10/25.
//

import Supabase
import SwiftUI

struct HomeView: View {
    @Binding var selectedTab: Tab
    @State private var missionViewModel = MissionViewModel()
    @State private var homeViewModel = HomeViewModel()
    @State private var groupViewModel = GroupViewModel()
    @State private var showingMissionDetail = false
    @State private var showingGroupBottomSheet = false
    @Environment(\.missionStateService) var missionStateService // need when you want to listen to the mission state changes

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

                        // グループアイコンボタン
                        Button(action: {
                            showingGroupBottomSheet = true
                        }) {
                            Image(systemName: "person.3.fill")
                                .font(.title2)
                                .foregroundColor(Color("brandOrange"))
                                .frame(width: 44, height: 44)
                                .background(Color("brandOrange").opacity(0.1))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal)

                    // 現在のミッション セクション
                    if missionViewModel.isLoading {
                        // Loading state
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                            .padding(.horizontal)
                    } else if let errorMessage = missionViewModel.errorMessage {
                        // Error state
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.largeTitle)
                                .foregroundColor(.red)
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            Button("Retry") {
                                loadCurrentMission()
                            }
                            .buttonStyle(.bordered)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                        .padding(.horizontal)
                    } else {
                        MissionCardView(mission: missionViewModel.todaysMission) {
                            showingMissionDetail = true
                        }
                        .padding(.horizontal)
                    }

                    // バッジコレクション セクション
                    BadgeCollectionView(badges: homeViewModel.userBadges, stats: homeViewModel.badgeStats)
                        .padding(.horizontal)

                    // 統計情報
                    StatsView()
                        .padding(.horizontal)
                }
                .padding(.top)
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingMissionDetail) {
                MissionDetailView(
                    mission: missionViewModel.todaysMission,
                    selectedTab: $selectedTab,
                    isPresented: $showingMissionDetail
                )
            }
            .sheet(isPresented: $showingGroupBottomSheet) {
                GroupBottomSheetView(groupViewModel: groupViewModel)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .onAppear {
                loadCurrentMission()
                Task {
                    await homeViewModel.loadUserBadges()
                    await groupViewModel.loadUserGroups()
                }
            }
            .onChange(of: missionStateService.currentMission) { _, _ in
                // Reload mission when it changes (e.g., cancelled from another view)
                print("🔄 Mission state changed in HomeView")
                loadCurrentMission()
            }
        }
    }

    private func loadCurrentMission() {
        Task {
            // Get current user ID from Supabase auth
            guard let currentUser = supabase.auth.currentUser else {
                missionViewModel.errorMessage = "Not authenticated"
                print("⚠️ User not authenticated")
                return
            }

            let userId = currentUser.id
            print("👤 Current user ID: \(userId)")
            print("👤 User email: \(currentUser.email ?? "none")")
            print("👤 UUID lowercase: \(userId.uuidString.lowercased())")

            // Fetch today's mission from Supabase
            await missionViewModel.fetchTodaysMission(userId: userId)

            // Debug: If no mission found, try fetching latest mission
            if missionViewModel.todaysMission == nil && missionViewModel.errorMessage == nil {
                print("ℹ️ No today's mission found, trying to fetch latest...")
                await missionViewModel.fetchLatestMission(userId: userId)
            }
        }
    }
}

#Preview("HomeView - English") {
    HomeView(selectedTab: .constant(.home)).environment(\.locale, .init(identifier: "en"))
}

#Preview("HomeView - Japanese") {
    HomeView(selectedTab: .constant(.home)).environment(\.locale, .init(identifier: "ja"))
}
