//
//  MissionSection.swift
//  escape
//
//  Created by Thanasan Kumdee on 7/11/2568 BE.
//
import Supabase
import SwiftUI

struct MissionSection: View {
    @State private var missionViewModel = MissionViewModel()
    @State private var showingMissionDetail = false
    @Environment(\.missionStateService) var missionStateService
    @EnvironmentObject var tabSelection: TabSelection

    var body: some View {
        Group {
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
        }
        .onAppear {
            loadCurrentMission()
        }
        .onChange(of: missionStateService.currentMission) {
            print("🔄 Mission state changed in HomeView")
            loadCurrentMission()
        }
        .sheet(isPresented: $showingMissionDetail) {
            MissionDetailView(
                mission: missionViewModel.todaysMission,
                selectedTab: $tabSelection.selectedTab,
                isPresented: $showingMissionDetail
            )
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

#Preview {
    MissionSection()
        .environment(\.missionStateService, MissionStateService())
}
