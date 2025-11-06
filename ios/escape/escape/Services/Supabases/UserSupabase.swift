//
//  UserSupabase.swift
//  escape
//
//  Created by YoungJune Kang on 2025/10/25.
//

import Foundation
import Supabase

class UserSupabase {
    // MARK: - User Profile Operations

    /// Fetches the current user's profile from the users table
    /// - Returns: User object with profile data
    /// - Throws: Database error if fetch fails
    func getCurrentUserProfile() async throws -> User {
        let currentUser = try await supabase.auth.session.user

        let user: User = try await supabase
            .from("users")
            .select()
            .eq("id", value: currentUser.id)
            .single()
            .execute()
            .value

        return user
    }

    /// Updates the current user's profile
    /// - Parameter name: New name for the user
    /// - Throws: Database error if update fails
    func updateUserProfile(name: String) async throws {
        let currentUser = try await supabase.auth.session.user

        try await supabase
            .from("users")
            .update(["name": name])
            .eq("id", value: currentUser.id)
            .execute()
    }

    /// Updates the current user's profile with name and profile badge
    /// - Parameters:
    ///   - name: New name for the user
    ///   - profileBadgeId: UUID of the badge to use as profile photo (optional)
    /// - Throws: Database error if update fails
    func updateUserProfile(name: String, profileBadgeId: UUID?) async throws {
        let currentUser = try await supabase.auth.session.user

        struct UpdateData: Encodable {
            let name: String
            let shelter_badge_id: String?
        }

        let updateData = UpdateData(
            name: name,
            shelter_badge_id: profileBadgeId?.uuidString
        )

        try await supabase
            .from("users")
            .update(updateData)
            .eq("id", value: currentUser.id)
            .execute()
    }

    /// Updates only the profile badge for the current user
    /// - Parameter profileBadgeId: UUID of the badge to use as profile photo (nil to clear)
    /// - Throws: Database error if update fails
    func updateProfileBadge(profileBadgeId: UUID?) async throws {
        let currentUser = try await supabase.auth.session.user

        struct UpdateBadgeData: Encodable {
            let shelter_badge_id: String?
        }

        let updateData = UpdateBadgeData(
            shelter_badge_id: profileBadgeId?.uuidString
        )

        try await supabase
            .from("users")
            .update(updateData)
            .eq("id", value: currentUser.id)
            .execute()
    }

    /// Fetches a user by their ID
    /// - Parameter userId: The user's UUID
    /// - Returns: User object, or nil if not found
    func getUser(by userId: UUID) async throws -> User? {
        let users: [User] = try await supabase
            .from("users")
            .select()
            .eq("id", value: userId)
            .limit(1)
            .execute()
            .value

        return users.first
    }

    /// Deletes the current user's account and all associated data
    /// - Throws: Database error if deletion fails
    func deleteAccount() async throws {
        let currentUser = try await supabase.auth.session.user

        // Call the Supabase RPC function to delete the user account
        // This function should be created in Supabase to handle both:
        // 1. Deleting user data from the users table
        // 2. Deleting the auth user via auth.users (requires service role)
        try await supabase.rpc("delete_user_account").execute()
    }
}
