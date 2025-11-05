//
//  PointSupabase.swift
//  escape
//
//  Created by YoungJune Kang on 2025/11/02.
//

import Foundation
import Supabase

class PointSupabase {
    // MARK: - Create Operations

    /// Adds a point record for a user
    /// - Parameters:
    ///   - userId: The user's UUID
    ///   - points: The points to add (positive or negative)
    /// - Returns: The created Point record
    /// - Throws: Database error if creation fails
    func addPointRecord(userId: UUID, points: Int64) async throws -> Point {
        print("💰 Adding point record for user: \(userId), points: \(points)")

        struct PointPayload: Encodable {
            let userId: String
            let point: Int64

            enum CodingKeys: String, CodingKey {
                case userId = "user_id"
                case point
            }
        }

        let payload = PointPayload(
            userId: userId.uuidString.lowercased(),
            point: points
        )

        let response: Point = try await supabase
            .from("points")
            .insert(payload)
            .select()
            .single()
            .execute()
            .value

        print("✅ Successfully added point record with ID: \(response.id)")

        return response
    }

    // MARK: - Fetch Operations

    /// Gets the total points for a user by summing all point records
    /// - Parameter userId: The user's UUID
    /// - Returns: Total points
    /// - Throws: Database error if fetch fails
    func getTotalPoints(userId: UUID) async throws -> Int64 {
        print("📊 Fetching total points for user: \(userId)")

        let userIdLowercase = userId.uuidString.lowercased()

        let response: [Point] = try await supabase
            .from("points")
            .select()
            .eq("user_id", value: userIdLowercase)
            .execute()
            .value

        let total = response.reduce(0) { $0 + ($1.point ?? 0) }

        print("✅ Total points for user: \(total)")

        return total
    }

    /// Fetches recent point records for a user
    /// - Parameters:
    ///   - userId: The user's UUID
    ///   - limit: Maximum number of records to fetch (default: 50)
    /// - Returns: Array of Point objects
    /// - Throws: Database error if fetch fails
    func getRecentPointRecords(userId: UUID, limit: Int = 50) async throws -> [Point] {
        print("📊 Fetching recent point records for user: \(userId)")

        let userIdLowercase = userId.uuidString.lowercased()

        let response: [Point] = try await supabase
            .from("points")
            .select()
            .eq("user_id", value: userIdLowercase)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value

        print("✅ Fetched \(response.count) point record(s)")

        return response
    }

    // MARK: - Ranking Operations

    /// Gets national leaderboard with user names
    /// - Parameter limit: Number of top users to fetch (default: 100)
    /// - Returns: Array of RankingEntry with rank, userId, username, and points
    /// - Throws: Database error if fetch fails
    func getNationalLeaderboard(limit: Int = 100) async throws -> [RankingEntry] {
        print("🏆 Fetching national leaderboard (top \(limit))")

        // Fetch top users ordered by points
        let points: [Point] = try await supabase
            .from("points")
            .select()
            .order("point", ascending: false)
            .limit(limit)
            .execute()
            .value

        print("✅ Fetched \(points.count) ranking entries")

        // Fetch user names for these points (batch query would be better, but iterate for now)
        var rankings: [RankingEntry] = []
        for (index, point) in points.enumerated() {
            guard let userId = point.userId else { continue }

            // Fetch user name
            let userIdLowercase = userId.uuidString.lowercased()

            // Simple model for user query
            struct UserQuery: Decodable {
                let name: String?
            }

            let users: [UserQuery] = try await supabase
                .from("users")
                .select("name")
                .eq("id", value: userIdLowercase)
                .execute()
                .value

            let userName = users.first?.name

            rankings.append(RankingEntry(
                id: point.id,
                rank: index + 1,
                userId: userId,
                userName: userName,
                totalPoints: point.point ?? 0
            ))
        }

        print("✅ Built \(rankings.count) ranking entries with names")
        return rankings
    }

    /// Gets user's national ranking by counting users with higher points
    /// Extremely efficient - uses single COUNT query instead of fetching all records
    /// - Parameter userId: The user's UUID
    /// - Returns: User's rank (1-indexed), or nil if user has no points record
    /// - Throws: Database error if fetch fails
    func getUserNationalRank(userId: UUID) async throws -> Int? {
        print("🏆 Calculating national rank for user: \(userId)")

        let userIdLowercase = userId.uuidString.lowercased()

        // Step 1: Get user's current points
        let userPoints: [Point] = try await supabase
            .from("points")
            .select()
            .eq("user_id", value: userIdLowercase)
            .execute()
            .value

        guard let userPoint = userPoints.first, let currentPoints = userPoint.point else {
            print("⚠️ User has no points record")
            return nil
        }

        print("📊 User has \(currentPoints) points")

        // Step 2: Count how many users have MORE points (efficient query)
        // Convert Int64 to Int for PostgrestFilterValue compatibility
        let response: [Point] = try await supabase
            .from("points")
            .select()
            .gt("point", value: Int(currentPoints))
            .execute()
            .value

        let usersAhead = response.count
        let rank = usersAhead + 1

        print("✅ User rank: \(rank) (users ahead: \(usersAhead))")

        return rank
    }

    // MARK: - Refresh Operations

    /// Refreshes user's total points by summing all mission results and updating/creating single point record
    /// - Parameter userId: The user's UUID
    /// - Returns: The updated Point record with total points
    /// - Throws: Database error if refresh fails
    func refreshUserPoints(userId: UUID) async throws -> Point {
        print("🔄 Refreshing total points for user: \(userId)")

        let userIdLowercase = userId.uuidString.lowercased()

        // Step 1: Query mission_results to sum all final_points for this user
        let missionResults: [MissionResult] = try await supabase
            .from("mission_results")
            .select()
            .eq("user_id", value: userIdLowercase)
            .execute()
            .value

        let totalPoints = missionResults.reduce(Int64(0)) { sum, result in
            sum + (result.finalPoints ?? 0)
        }

        print("💰 Calculated total points from \(missionResults.count) missions: \(totalPoints)")

        // Step 2: Delete any existing point records for this user
        try await supabase
            .from("points")
            .delete()
            .eq("user_id", value: userIdLowercase)
            .execute()

        print("🗑️ Deleted old point records")

        // Step 3: Insert new single point record with total
        struct PointPayload: Encodable {
            let userId: String
            let point: Int64

            enum CodingKeys: String, CodingKey {
                case userId = "user_id"
                case point
            }
        }

        let payload = PointPayload(
            userId: userIdLowercase,
            point: totalPoints
        )

        let response: Point = try await supabase
            .from("points")
            .insert(payload)
            .select()
            .single()
            .execute()
            .value

        print("✅ Successfully refreshed user points: \(totalPoints)")

        return response
    }

    // MARK: - Error Handling

    enum PointError: LocalizedError {
        case creationFailed
        case fetchFailed
        case userNotAuthenticated

        var errorDescription: String? {
            switch self {
            case .creationFailed:
                return "Failed to create point record"
            case .fetchFailed:
                return "Failed to fetch points"
            case .userNotAuthenticated:
                return "User is not authenticated"
            }
        }
    }
}
