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
}
