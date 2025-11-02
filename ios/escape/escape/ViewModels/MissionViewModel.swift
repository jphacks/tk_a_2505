//
//  MissionViewModel.swift
//  escape
//
//  Created by YoungJune Kang on 2025/10/25.
//

import Foundation

@MainActor
@Observable
class MissionViewModel {
    var isLoading = false
    var errorMessage: String?
    var todaysMission: Mission?

    // MARK: - Dependencies

    private let missionService: MissionSupabase
    private let missionGenerator: MissionGenerator

    // MARK: - Initialization

    init(
        missionService: MissionSupabase = MissionSupabase(),
        missionGenerator: MissionGenerator = MissionGenerator()
    ) {
        self.missionService = missionService
        self.missionGenerator = missionGenerator
    }

    /// Fetches today's mission from Supabase
    /// Compares the created_at field with today's date in the user's timezone
    func fetchTodaysMission(userId: UUID) async {
        isLoading = true
        errorMessage = nil
        todaysMission = nil

        do {
            todaysMission = try await missionService.fetchTodaysMission(userId: userId)
        } catch {
            errorMessage = "Failed to fetch today's mission: \(error.localizedDescription)"
            print("❌ Error fetching mission: \(error)")
        }

        isLoading = false
    }

    /// Fetches the latest mission for a user regardless of date
    func fetchLatestMission(userId: UUID) async {
        isLoading = true
        errorMessage = nil
        todaysMission = nil

        do {
            todaysMission = try await missionService.fetchLatestMission(userId: userId)
        } catch {
            errorMessage = "Failed to fetch latest mission: \(error.localizedDescription)"
            print("❌ Error fetching latest mission: \(error)")
        }

        isLoading = false
    }

    /// Creates a new mission in Supabase
    func createMission(_ mission: Mission) async throws -> Mission {
        return try await missionService.createMission(mission)
    }

    /// Updates mission status
    func updateMissionStatus(missionId: UUID, status: MissionState) async throws {
        try await missionService.updateMissionStatus(missionId: missionId, status: status)
    }

    /// Checks if user has an active mission with status 'have' created today
    /// Returns the active mission if found, nil otherwise
    func fetchActiveMission(userId: UUID) async -> Mission? {
        return await missionService.fetchActiveMission(userId: userId)
    }

    /// Ensures user has an active mission for today
    /// Checks if user has a mission with status 'have' created today
    /// If not (either completed today's mission or it's a new day), generates a new mission
    /// This should be called when the app launches
    func ensureUserHasActiveMission(userId: UUID) async {
        print("🚀 Ensuring user has an active mission for today...")

        // Check if user already has an active mission created today
        let activeMission = await fetchActiveMission(userId: userId)

        if activeMission != nil {
            print("✅ User already has an active mission for today, skipping generation")
            todaysMission = activeMission
            return
        }

        // No active mission found for today, generate a new one
        // This happens when:
        // 1. It's a new day (previous mission was yesterday or earlier)
        // 2. User completed today's mission (status changed from 'have' to 'done')
        print("🎯 No active mission found for today, generating new daily mission...")
        isLoading = true
        errorMessage = nil

        do {
            let newMission = try await missionGenerator.generateMission()

            print("✅ New daily mission generated: \(newMission.id)")
            print("   Title: \(newMission.title ?? "nil")")
            print("   Status: \(newMission.status.rawValue)")

            todaysMission = newMission
        } catch {
            errorMessage = "Failed to generate mission: \(error.localizedDescription)"
            print("❌ Error generating mission: \(error)")
        }

        isLoading = false
    }

    /// Resets the controller state
    func reset() {
        isLoading = false
        errorMessage = nil
        todaysMission = nil
    }
}
