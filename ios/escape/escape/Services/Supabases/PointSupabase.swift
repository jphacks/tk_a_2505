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

    /// Gets smart paginated national leaderboard (top 10 + context around user)
    /// - Parameter userId: The current user's UUID
    /// - Returns: Array of RankingEntry with smart pagination
    /// - Throws: Database error if fetch fails
    func getSmartPaginatedNationalLeaderboard(userId: UUID) async throws -> [RankingEntry] {
        print("🏆 Fetching smart paginated national leaderboard")

        // Get user's rank first
        guard let userRank = try await getUserNationalRank(userId: userId) else {
            // User has no points, just return top 10
            return try await getNationalLeaderboard(limit: 10)
        }

        print("📊 User rank: \(userRank)")

        // Always get top 10
        let topUsers = try await getNationalLeaderboard(limit: 10)

        // If user is in top 25, just return top rankings
        if userRank <= 25 {
            return try await getNationalLeaderboard(limit: max(userRank + 15, 25))
        }

        // Get users around current user (15 behind, user, 15 ahead)
        var allUsers = topUsers

        // Add separator marker if gap exists
        if userRank > 25 {
            allUsers.append(RankingEntry(
                id: UUID(),
                rank: -1, // Special marker for separator
                userId: UUID(),
                userName: "---",
                totalPoints: 0,
                profileBadgeImageUrl: nil
            ))
        }

        // Get context around user (offset to get from rank-15 to rank+15)
        let contextStart = max(11, userRank - 15)
        let contextLimit = min(31, userRank + 15)

        let contextUsers = try await getNationalLeaderboardRange(
            offset: contextStart - 1,
            limit: contextLimit - contextStart + 1
        )

        allUsers.append(contentsOf: contextUsers)

        return allUsers
    }

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

        // Extract all user IDs
        let userIds = points.compactMap { $0.userId?.uuidString.lowercased() }

        guard !userIds.isEmpty else {
            return []
        }

        // Batch fetch all user names AND badge URLs in ONE query
        struct UserQuery: Decodable {
            let id: String
            let name: String?
            let shelterBadgeId: String?

            enum CodingKeys: String, CodingKey {
                case id
                case name
                case shelterBadgeId = "shelter_badge_id"
            }
        }

        let users: [UserQuery] = try await supabase
            .from("users")
            .select("id,name,shelter_badge_id")
            .in("id", values: userIds)
            .execute()
            .value

        // Create lookup dictionary for O(1) access
        let userDict = Dictionary(uniqueKeysWithValues: users.map { ($0.id, ($0.name, $0.shelterBadgeId)) })

        // Get all badge IDs that need their image URLs
        let badgeIds = users.compactMap { $0.shelterBadgeId }

        // Batch fetch badge image URLs if there are any badges
        var badgeUrlDict: [String: String] = [:]
        if !badgeIds.isEmpty {
            struct BadgeQuery: Decodable {
                let id: String
                let badgeName: String

                enum CodingKeys: String, CodingKey {
                    case id
                    case badgeName = "badge_name"
                }
            }

            let badges: [BadgeQuery] = try await supabase
                .from("shelter_badges")
                .select("id,badge_name")
                .in("id", values: badgeIds)
                .execute()
                .value

            // Build badge URL dictionary
            for badge in badges {
                let imageUrl = try supabase.storage.from("badge_images").getPublicURL(path: "\(badge.badgeName).png")
                badgeUrlDict[badge.id] = imageUrl.absoluteString
            }
        }

        // Build rankings with batched user data and badge URLs
        var rankings: [RankingEntry] = []
        for (index, point) in points.enumerated() {
            guard let userId = point.userId else { continue }

            let userIdLower = userId.uuidString.lowercased()
            let (userName, badgeId) = userDict[userIdLower] ?? (nil, nil)
            let badgeUrl = badgeId.flatMap { badgeUrlDict[$0] }

            rankings.append(RankingEntry(
                id: point.id,
                rank: index + 1,
                userId: userId,
                userName: userName,
                totalPoints: point.point ?? 0,
                profileBadgeImageUrl: badgeUrl
            ))
        }

        print("✅ Built \(rankings.count) ranking entries with names and badges (batched)")
        return rankings
    }

    /// Gets national leaderboard range with offset
    /// - Parameters:
    ///   - offset: Number of records to skip
    ///   - limit: Number of records to fetch
    /// - Returns: Array of RankingEntry with rank, userId, username, and points
    /// - Throws: Database error if fetch fails
    func getNationalLeaderboardRange(offset: Int, limit: Int) async throws -> [RankingEntry] {
        print("🏆 Fetching national leaderboard range (offset: \(offset), limit: \(limit))")

        // Fetch users with offset
        let points: [Point] = try await supabase
            .from("points")
            .select()
            .order("point", ascending: false)
            .range(from: offset, to: offset + limit - 1)
            .execute()
            .value

        // Extract all user IDs
        let userIds = points.compactMap { $0.userId?.uuidString.lowercased() }

        guard !userIds.isEmpty else {
            return []
        }

        // Batch fetch all user names AND badge URLs in ONE query
        struct UserQuery: Decodable {
            let id: String
            let name: String?
            let shelterBadgeId: String?

            enum CodingKeys: String, CodingKey {
                case id
                case name
                case shelterBadgeId = "shelter_badge_id"
            }
        }

        let users: [UserQuery] = try await supabase
            .from("users")
            .select("id,name,shelter_badge_id")
            .in("id", values: userIds)
            .execute()
            .value

        // Create lookup dictionary
        let userDict = Dictionary(uniqueKeysWithValues: users.map { ($0.id, ($0.name, $0.shelterBadgeId)) })

        // Get all badge IDs and fetch their URLs
        let badgeIds = users.compactMap { $0.shelterBadgeId }
        var badgeUrlDict: [String: String] = [:]
        if !badgeIds.isEmpty {
            struct BadgeQuery: Decodable {
                let id: String
                let badgeName: String

                enum CodingKeys: String, CodingKey {
                    case id
                    case badgeName = "badge_name"
                }
            }

            let badges: [BadgeQuery] = try await supabase
                .from("shelter_badges")
                .select("id,badge_name")
                .in("id", values: badgeIds)
                .execute()
                .value

            for badge in badges {
                let imageUrl = try supabase.storage.from("badge_images").getPublicURL(path: "\(badge.badgeName).png")
                badgeUrlDict[badge.id] = imageUrl.absoluteString
            }
        }

        // Build rankings
        var rankings: [RankingEntry] = []
        for (index, point) in points.enumerated() {
            guard let userId = point.userId else { continue }

            let userIdLower = userId.uuidString.lowercased()
            let (userName, badgeId) = userDict[userIdLower] ?? (nil, nil)
            let badgeUrl = badgeId.flatMap { badgeUrlDict[$0] }

            rankings.append(RankingEntry(
                id: point.id,
                rank: offset + index + 1,
                userId: userId,
                userName: userName,
                totalPoints: point.point ?? 0,
                profileBadgeImageUrl: badgeUrl
            ))
        }

        return rankings
    }

    /// Gets team leaderboard with user names for a specific group
    /// - Parameter groupId: The team/group UUID
    /// - Returns: Array of RankingEntry for team members
    /// - Throws: Database error if fetch fails
    func getTeamLeaderboard(groupId: UUID) async throws -> [RankingEntry] {
        print("🏆 Fetching team leaderboard for group: \(groupId)")

        // First, get all group members
        let members: [TeamMember] = try await supabase
            .from("group_members")
            .select()
            .eq("group_id", value: groupId)
            .execute()
            .value

        let memberUserIds = members.map { $0.userId }

        guard !memberUserIds.isEmpty else {
            print("⚠️ No members found in team")
            return []
        }

        // Get points for all members in ONE query
        let memberPoints: [Point] = try await supabase
            .from("points")
            .select()
            .in("user_id", values: memberUserIds.map { $0.uuidString.lowercased() })
            .order("point", ascending: false)
            .execute()
            .value

        print("✅ Fetched \(memberPoints.count) member points")

        // Extract user IDs from points
        let userIdsWithPoints = memberPoints.compactMap { $0.userId?.uuidString.lowercased() }

        guard !userIdsWithPoints.isEmpty else {
            print("⚠️ No members have points yet")
            return []
        }

        // Batch fetch ALL user names AND badge URLs in ONE query
        struct UserQuery: Decodable {
            let id: String
            let name: String?
            let shelterBadgeId: String?

            enum CodingKeys: String, CodingKey {
                case id
                case name
                case shelterBadgeId = "shelter_badge_id"
            }
        }

        let users: [UserQuery] = try await supabase
            .from("users")
            .select("id,name,shelter_badge_id")
            .in("id", values: userIdsWithPoints)
            .execute()
            .value

        // Create lookup dictionary for O(1) access
        let userDict = Dictionary(uniqueKeysWithValues: users.map { ($0.id, ($0.name, $0.shelterBadgeId)) })

        // Get all badge IDs and fetch their URLs
        let badgeIds = users.compactMap { $0.shelterBadgeId }
        var badgeUrlDict: [String: String] = [:]
        if !badgeIds.isEmpty {
            struct BadgeQuery: Decodable {
                let id: String
                let badgeName: String

                enum CodingKeys: String, CodingKey {
                    case id
                    case badgeName = "badge_name"
                }
            }

            let badges: [BadgeQuery] = try await supabase
                .from("shelter_badges")
                .select("id,badge_name")
                .in("id", values: badgeIds)
                .execute()
                .value

            for badge in badges {
                let imageUrl = try supabase.storage.from("badge_images").getPublicURL(path: "\(badge.badgeName).png")
                badgeUrlDict[badge.id] = imageUrl.absoluteString
            }
        }

        // Build rankings with batched data and badge URLs
        var rankings: [RankingEntry] = []
        for (index, point) in memberPoints.enumerated() {
            guard let userId = point.userId else { continue }

            let userIdLower = userId.uuidString.lowercased()
            let (userName, badgeId) = userDict[userIdLower] ?? (nil, nil)
            let badgeUrl = badgeId.flatMap { badgeUrlDict[$0] }

            rankings.append(RankingEntry(
                id: point.id,
                rank: index + 1,
                userId: userId,
                userName: userName,
                totalPoints: point.point ?? 0,
                profileBadgeImageUrl: badgeUrl
            ))
        }

        print("✅ Built \(rankings.count) team ranking entries with badges (batched)")
        return rankings
    }

    /// Gets smart paginated team leaderboard (top 10 + context around user)
    /// - Parameters:
    ///   - groupId: The team/group UUID
    ///   - userId: The current user's UUID
    /// - Returns: Array of RankingEntry with smart pagination
    /// - Throws: Database error if fetch fails
    func getSmartPaginatedTeamLeaderboard(groupId: UUID, userId: UUID) async throws -> [RankingEntry] {
        print("🏆 Fetching smart paginated team leaderboard")

        // Get full team leaderboard
        let allRankings = try await getTeamLeaderboard(groupId: groupId)

        guard let userIndex = allRankings.firstIndex(where: { $0.userId == userId }) else {
            // User not found in rankings, return top 10
            return Array(allRankings.prefix(10))
        }

        let userRank = userIndex + 1
        print("📊 User team rank: \(userRank)/\(allRankings.count)")

        // If team is small or user is in top 25, return all or top portion
        if allRankings.count <= 25 || userRank <= 25 {
            return allRankings
        }

        // Build smart paginated result
        var result: [RankingEntry] = []

        // Top 10
        result.append(contentsOf: Array(allRankings.prefix(10)))

        // Separator
        result.append(RankingEntry(
            id: UUID(),
            rank: -1,
            userId: UUID(),
            userName: "---",
            totalPoints: 0,
            profileBadgeImageUrl: nil
        ))

        // Context around user (15 before, user, 15 after)
        let contextStart = max(10, userIndex - 15)
        let contextEnd = min(allRankings.count - 1, userIndex + 15)

        result.append(contentsOf: Array(allRankings[contextStart ... contextEnd]))

        return result
    }

    /// Gets user's rank within their team
    /// - Parameters:
    ///   - groupId: The team/group UUID
    ///   - userId: The user's UUID
    /// - Returns: User's rank within team (1-indexed), or nil if not in team or no points
    /// - Throws: Database error if fetch fails
    func getUserTeamRank(groupId: UUID, userId: UUID) async throws -> Int? {
        print("🏆 Calculating team rank for user: \(userId) in group: \(groupId)")

        let rankings = try await getTeamLeaderboard(groupId: groupId)

        guard let userIndex = rankings.firstIndex(where: { $0.userId == userId }) else {
            print("⚠️ User not found in team rankings")
            return nil
        }

        let rank = userIndex + 1
        print("✅ User team rank: \(rank)/\(rankings.count)")

        return rank
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
