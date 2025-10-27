//
//  MissionResultSupabase.swift
//  escape
//
//  Created by Claude on 11/10/2568 BE.
//

import Foundation
import Supabase

class MissionResultSupabase {
    // MARK: - Fetch Operations

    /// Fetches all mission results for a specific user
    /// - Parameter userId: The user's UUID
    /// - Returns: Array of MissionResult objects
    /// - Throws: Database error if fetch fails
    func getUserMissionResults(userId: UUID) async throws -> [MissionResult] {
        print("🔍 Fetching mission results for user: \(userId)")

        let userIdLowercase = userId.uuidString.lowercased()

        let response: [MissionResult] = try await supabase
            .from("mission_results")
            .select()
            .eq("user_id", value: userIdLowercase)
            .order("created_at", ascending: false)
            .execute()
            .value

        print("✅ Found \(response.count) mission result(s) for user")

        return response
    }

    /// Fetches mission results for a specific user at a specific shelter
    /// - Parameters:
    ///   - userId: The user's UUID
    ///   - shelterId: The shelter's UUID
    /// - Returns: Array of MissionResult objects
    /// - Throws: Database error if fetch fails
    func getUserShelterMissionResults(userId: UUID, shelterId: UUID) async throws -> [MissionResult] {
        print("🔍 Fetching mission results for user: \(userId) at shelter: \(shelterId)")

        let userIdLowercase = userId.uuidString.lowercased()
        let shelterIdLowercase = shelterId.uuidString.lowercased()

        let response: [MissionResult] = try await supabase
            .from("mission_results")
            .select()
            .eq("user_id", value: userIdLowercase)
            .eq("shelter_id", value: shelterIdLowercase)
            .order("created_at", ascending: false)
            .execute()
            .value

        print("✅ Found \(response.count) mission result(s) for user at shelter")

        return response
    }

    /// Fetches all mission results for a specific shelter
    /// - Parameter shelterId: The shelter's UUID
    /// - Returns: Array of MissionResult objects
    /// - Throws: Database error if fetch fails
    func getShelterMissionResults(shelterId: UUID) async throws -> [MissionResult] {
        print("🔍 Fetching mission results for shelter: \(shelterId)")

        let shelterIdLowercase = shelterId.uuidString.lowercased()

        let response: [MissionResult] = try await supabase
            .from("mission_results")
            .select()
            .eq("shelter_id", value: shelterIdLowercase)
            .order("created_at", ascending: false)
            .execute()
            .value

        print("✅ Found \(response.count) mission result(s) for shelter")

        return response
    }

    // MARK: - Create Operations

    /// Inserts a new mission result into the database
    /// - Parameter missionResult: The MissionResult object to insert
    /// - Returns: The created MissionResult with database-generated fields
    /// - Throws: Database error if creation fails
    func createMissionResult(_ missionResult: MissionResult) async throws -> MissionResult {
        print("💾 creating mission result for mission: \(missionResult.missionId)")

        let response: MissionResult = try await supabase
            .from("mission_results")
            .insert(missionResult)
            .select()
            .single()
            .execute()
            .value

        print("✅ Successfully created mission result with ID: \(response.id)")

        return response
    }

    // MARK: - Statistics & Analytics

    /// Fetches recent mission results for a user from Supabase
    /// - Parameters:
    ///   - userId: The user's UUID
    ///   - limit: Maximum number of mission results to fetch (default: 30)
    /// - Returns: Array of MissionResult objects
    /// - Throws: Database error if fetch fails
    func fetchRecentMissionResults(userId: UUID, limit: Int = 30) async throws -> [MissionResult] {
        print("📊 Fetching recent mission results for stats - User: \(userId)")

        // Convert UUID to lowercase for database query
        let userIdLowercase = userId.uuidString.lowercased()

        // Fetch mission results ordered by created_at
        let response: [MissionResult] = try await supabase
            .from("mission_results")
            .select()
            .eq("user_id", value: userIdLowercase)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value

        print("✅ Fetched \(response.count) mission result(s) for stats")

        return response
    }

    /// Fetches mission results within a specific date range
    /// - Parameters:
    ///   - userId: The user's UUID
    ///   - startDate: Start of the date range
    ///   - endDate: End of the date range
    /// - Returns: Array of MissionResult objects in the date range
    /// - Throws: Database error if fetch fails
    func fetchMissionResultsInDateRange(userId: UUID, startDate: Date, endDate: Date) async throws -> [MissionResult] {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)

        let startString = formatter.string(from: startDate)
        let endString = formatter.string(from: endDate)

        print("📊 Fetching mission results in date range: \(startString) to \(endString)")

        let userIdLowercase = userId.uuidString.lowercased()

        let response: [MissionResult] = try await supabase
            .from("mission_results")
            .select()
            .eq("user_id", value: userIdLowercase)
            .gte("created_at", value: startString)
            .lte("created_at", value: endString)
            .order("created_at", ascending: false)
            .execute()
            .value

        print("✅ Fetched \(response.count) mission result(s) in date range")

        return response
    }

    // MARK: - Error Handling

    enum MissionResultError: LocalizedError {
        case notFound
        case creationFailed
        case invalidParameters
        case userNotAuthenticated
        case missionResultAlreadyExists

        var errorDescription: String? {
            switch self {
            case .notFound:
                return "Mission result not found"
            case .creationFailed:
                return "Failed to create mission result"
            case .invalidParameters:
                return "Invalid parameters provided"
            case .userNotAuthenticated:
                return "User is not authenticated"
            case .missionResultAlreadyExists:
                return "Mission result already exists for this mission"
            }
        }
    }
}
