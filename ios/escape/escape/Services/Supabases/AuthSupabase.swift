//
//  AuthSupabase.swift
//  escape
//
//  Created by YoungJune Kang on 2025/10/25.
//

import Foundation
import Supabase

class AuthSupabase {
    // MARK: - Authentication Operations

    /// Signs in a user with OTP (email magic link)
    /// - Parameters:
    ///   - email: User's email address
    ///   - redirectTo: URL to redirect to after authentication
    /// - Throws: Authentication error if sign in fails
    func signInWithOTP(email: String, redirectTo: URL?) async throws {
        try await supabase.auth.signInWithOTP(
            email: email,
            redirectTo: redirectTo
        )
    }

    /// Signs out the current user
    /// - Throws: Authentication error if sign out fails
    func signOut() async throws {
        try await supabase.auth.signOut()
    }

    /// Handles authentication session from deep link URL
    /// - Parameter url: The deep link URL containing authentication token
    /// - Throws: Authentication error if session handling fails
    func handleSession(from url: URL) async throws {
        try await supabase.auth.session(from: url)
    }

    /// Gets the current user's ID
    /// - Returns: The current user's UUID
    /// - Throws: Authentication error if not authenticated
    func getCurrentUserId() async throws -> UUID {
        let session = try await supabase.auth.session
        return session.user.id
    }
}
