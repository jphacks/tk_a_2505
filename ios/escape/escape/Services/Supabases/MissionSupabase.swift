//
//  MissionSupabase.swift
//  escape
//
//  Created by YoungJune Kang on 2025/10/25.
//

import Foundation
import Supabase

class MissionSupabase {
    // MARK: - Fetch Operations

    /// Fetches today's mission from Supabase
    /// Compares the created_at field with today's date in the user's timezone
    /// - Parameter userId: The user's UUID
    /// - Returns: Today's mission if found, nil otherwise
    /// - Throws: Database error if fetch fails
    func fetchTodaysMission(userId: UUID) async throws -> Mission? {
        // Get start and end of today in user's local timezone
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)

        guard let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday) else {
            throw MissionError.invalidDateRange
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

        // Query with date filter
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

        return response.first
    }

    /// Fetches the latest mission for a user regardless of date
    /// - Parameter userId: The user's UUID
    /// - Returns: Latest mission if found, nil otherwise
    /// - Throws: Database error if fetch fails
    func fetchLatestMission(userId: UUID) async throws -> Mission? {
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

        return response.first
    }

    /// Checks if user has an active mission with status 'have' created today
    /// Returns the active mission if found, nil otherwise
    /// - Parameter userId: The user's UUID
    /// - Returns: Active mission if found, nil otherwise
    func fetchActiveMission(userId: UUID) async -> Mission? {
        do {
            print("🔍 Checking for today's active mission for user: \(userId)")

            // Get start and end of today in user's local timezone
            let calendar = Calendar.current
            let now = Date()
            let startOfToday = calendar.startOfDay(for: now)

            guard let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday) else {
                print("❌ Failed to calculate date range")
                return nil
            }

            // Format dates as ISO8601 UTC strings for database query
            let formatter = ISO8601DateFormatter()
            formatter.timeZone = TimeZone(secondsFromGMT: 0)

            let startString = formatter.string(from: startOfToday)
            let endString = formatter.string(from: endOfToday)

            print("📅 Checking date range: \(startString) to \(endString)")

            let userIdLowercase = userId.uuidString.lowercased()

            // Query for missions with status 'have' created today
            let response: [Mission] = try await supabase
                .from("missions")
                .select()
                .eq("user_id", value: userIdLowercase)
                .eq("status", value: "have")
                .gte("created_at", value: startString)
                .lt("created_at", value: endString)
                .order("created_at", ascending: false)
                .limit(1)
                .execute()
                .value

            if let mission = response.first {
                print("✅ Found today's active mission: \(mission.id)")
                print("   Status: \(mission.status.rawValue)")
                print("   Created: \(mission.createdAt)")
                return mission
            } else {
                print("ℹ️ No active mission found for today")
                return nil
            }
        } catch {
            print("❌ Error checking for today's active mission: \(error)")
            return nil
        }
    }

    // MARK: - Create/Update Operations

    /// Creates a new mission in Supabase
    /// - Parameter mission: The Mission object to create
    /// - Returns: The created Mission with database-generated fields
    /// - Throws: Database error if creation fails
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
    /// - Parameters:
    ///   - missionId: The mission UUID
    ///   - status: New status to set
    /// - Throws: Database error if update fails
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

    // MARK: - Stats-Related Queries

    /// Fetches recent completed missions for a user from Supabase
    /// - Parameters:
    ///   - userId: The user's UUID
    ///   - limit: Maximum number of missions to fetch (default: 30)
    /// - Returns: Array of completed Mission objects
    /// - Throws: Database error if fetch fails
    func fetchRecentCompletedMissions(userId: UUID, limit: Int = 30) async throws -> [Mission] {
        print("📊 Fetching recent missions for stats - User: \(userId)")

        // Convert UUID to lowercase for database query
        let userIdLowercase = userId.uuidString.lowercased()

        // Fetch only completed missions ordered by created_at
        let response: [Mission] = try await supabase
            .from("missions")
            .select()
            .eq("user_id", value: userIdLowercase)
            .eq("status", value: "done") // Only fetch completed missions
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value

        print("✅ Fetched \(response.count) completed mission(s) for stats")

        return response
    }

    /// Fetches completed missions within a specific date range
    /// - Parameters:
    ///   - userId: The user's UUID
    ///   - startDate: Start of the date range
    ///   - endDate: End of the date range
    /// - Returns: Array of completed Mission objects in the date range
    /// - Throws: Database error if fetch fails
    func fetchCompletedMissionsInDateRange(userId: UUID, startDate: Date, endDate: Date) async throws -> [Mission] {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)

        let startString = formatter.string(from: startDate)
        let endString = formatter.string(from: endDate)

        print("📊 Fetching completed missions in date range: \(startString) to \(endString)")

        let userIdLowercase = userId.uuidString.lowercased()

        let response: [Mission] = try await supabase
            .from("missions")
            .select()
            .eq("user_id", value: userIdLowercase)
            .eq("status", value: "done") // Only fetch completed missions
            .gte("created_at", value: startString)
            .lte("created_at", value: endString)
            .order("created_at", ascending: false)
            .execute()
            .value

        print("✅ Fetched \(response.count) completed mission(s) in date range")

        return response
    }

    // MARK: - Error Handling

    enum MissionError: LocalizedError {
        case invalidDateRange
        case notFound
        case creationFailed

        var errorDescription: String? {
            switch self {
            case .invalidDateRange:
                return "Failed to calculate date range"
            case .notFound:
                return "Mission not found"
            case .creationFailed:
                return "Failed to create mission"
            }
        }
    }
}
