//
//  MissionController.swift
//  escape
//
//  Created by YoungJune Kang on 2025/10/11.
//

import Foundation
import Supabase

@Observable
class MissionController {
    var isLoading = false
    var errorMessage: String?
    var todaysMission: Mission?

    /// Fetches today's mission from Supabase
    /// Compares the created_at field with today's date in the user's timezone
    func fetchTodaysMission(userId: UUID) async {
        isLoading = true
        errorMessage = nil
        todaysMission = nil

        do {
            // Get start and end of today in user's local timezone
            let calendar = Calendar.current
            let now = Date()
            let startOfToday = calendar.startOfDay(for: now)

            guard let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday) else {
                errorMessage = "Failed to calculate date range"
                isLoading = false
                return
            }

            // Format dates as ISO8601 UTC strings for database query
            let formatter = ISO8601DateFormatter()
            formatter.timeZone = TimeZone(secondsFromGMT: 0)

            let startString = formatter.string(from: startOfToday)
            let endString = formatter.string(from: endOfToday)

            print("🔍 Fetching missions for user: \(userId)")
            print("📅 Date range: \(startString) to \(endString)")

            // Convert UUID to lowercase for database query (PostgreSQL stores UUIDs as lowercase)
            let userIdLowercase = userId.uuidString.lowercased()
            print("🔑 Querying with user_id: \(userIdLowercase)")

            // First, try to get any missions for this user without date filter to test
            let allMissionsResponse: [Mission] = try await supabase
                .from("missions")
                .select()
                .eq("user_id", value: userIdLowercase)
                .execute()
                .value

            print("🔍 Total missions for user (no date filter): \(allMissionsResponse.count)")

            // Now query with date filter
            let response: [Mission] = try await supabase
                .from("missions")
                .select()
                .eq("user_id", value: userIdLowercase)
                .gte("created_at", value: startString)
                .lt("created_at", value: endString)
                .order("created_at", ascending: false)
                .limit(1)
                .execute()
                .value

            print("✅ Found \(response.count) mission(s)")
            if let mission = response.first {
                print("📋 Mission: \(mission.id)")
                print("   Title: \(mission.title ?? "nil")")
                print("   DisasterType: \(mission.disasterType?.rawValue ?? "nil")")
                print("   Status: \(mission.status.rawValue)")
                print("   Created: \(mission.createdAt)")
            }

            todaysMission = response.first

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
            print("🔍 Fetching latest mission for user: \(userId)")

            // Convert UUID to lowercase for database query (PostgreSQL stores UUIDs as lowercase)
            let userIdLowercase = userId.uuidString.lowercased()

            let response: [Mission] = try await supabase
                .from("missions")
                .select()
                .eq("user_id", value: userIdLowercase)
                .order("created_at", ascending: false)
                .limit(1)
                .execute()
                .value

            print("✅ Found \(response.count) mission(s)")
            if let mission = response.first {
                print("📋 Mission: \(mission.id)")
                print("   Title: \(mission.title ?? "nil")")
                print("   DisasterType: \(mission.disasterType?.rawValue ?? "nil")")
                print("   Status: \(mission.status.rawValue)")
                print("   Created: \(mission.createdAt)")
            }

            todaysMission = response.first

        } catch {
            errorMessage = "Failed to fetch latest mission: \(error.localizedDescription)"
            print("❌ Error fetching latest mission: \(error)")
        }

        isLoading = false
    }

    /// Creates a new mission in Supabase
    func createMission(_ mission: Mission) async throws -> Mission {
        let response: Mission = try await supabase
            .from("missions")
            .insert(mission)
            .select()
            .single()
            .execute()
            .value

        return response
    }

    /// Updates mission status
    func updateMissionStatus(missionId: UUID, status: MissionState) async throws {
        struct StatusUpdate: Encodable {
            let status: MissionState
        }

        try await supabase
            .from("missions")
            .update(StatusUpdate(status: status))
            .eq("id", value: missionId.uuidString.lowercased())
            .execute()
    }

    /// Updates mission steps and distances
    func updateMissionProgress(missionId: UUID, steps: Int64?, distances: Double?) async throws {
        struct ProgressUpdate: Encodable {
            let steps: Int64?
            let distances: Double?
        }

        try await supabase
            .from("missions")
            .update(ProgressUpdate(steps: steps, distances: distances))
            .eq("id", value: missionId.uuidString.lowercased())
            .execute()
    }

    /// Resets the controller state
    func reset() {
        isLoading = false
        errorMessage = nil
        todaysMission = nil
    }
}
