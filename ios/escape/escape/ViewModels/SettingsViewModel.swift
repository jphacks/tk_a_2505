//
//  SettingsViewModel.swift
//  escape
//
//  Created by YoungJune Kang on 2025/10/25.
//

import Foundation
import SwiftUI
import Supabase

@MainActor
@Observable
class SettingsViewModel {
    var name = ""
    var isLoading = false
    var showLogoutConfirmation = false

    // Badge-related properties
    var userBadges: [Badge] = []
    var selectedProfileBadgeId: UUID?
    var profileBadgeImageUrl: String?

    // MARK: - Dependencies

    private let userService: UserSupabase
    private let authService: AuthSupabase
    private let badgeService: BadgeSupabase

    // MARK: - Initialization

    init(
        userService: UserSupabase = UserSupabase(),
        authService: AuthSupabase = AuthSupabase(),
        badgeService: BadgeSupabase = BadgeSupabase()
    ) {
        self.userService = userService
        self.authService = authService
        self.badgeService = badgeService
    }

    // MARK: - Actions

    func loadProfile() async {
        do {
            let user = try await userService.getCurrentUserProfile()
            name = user.name ?? ""
            selectedProfileBadgeId = user.profileBadgeId

            // Load user's collected badges
            await loadUserBadges()

            // Load profile badge image URL if a badge is selected
            if let badgeId = selectedProfileBadgeId {
                await loadProfileBadgeImage(badgeId: badgeId)
            }
        } catch {
            debugPrint("❌ Error loading profile: \(error)")
        }
    }

    func loadUserBadges() async {
        do {
            let collectedBadges = try await badgeService.getUserCollectedBadgesWithDetails()
            userBadges = collectedBadges.map { $0.toBadge() }
            print("✅ Loaded \(userBadges.count) badges for profile selection")
        } catch {
            debugPrint("❌ Error loading user badges: \(error)")
            userBadges = []
        }
    }

    func loadProfileBadgeImage(badgeId: UUID) async {
        do {
            // Find the badge in user's collected badges
            if let badge = userBadges.first(where: { $0.id == badgeId.uuidString }) {
                profileBadgeImageUrl = badge.imageUrl
            } else {
                // Badge not in loaded badges, fetch from shelter_badges table
                let shelterBadges: [ShelterBadge] = try await supabase
                    .from("shelter_badges")
                    .select()
                    .eq("id", value: badgeId)
                    .limit(1)
                    .execute()
                    .value

                if let shelterBadge = shelterBadges.first {
                    profileBadgeImageUrl = shelterBadge.getImageUrl()
                }
            }
        } catch {
            debugPrint("❌ Error loading profile badge image: \(error)")
        }
    }

    func updateProfile() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await userService.updateUserProfile(name: name, profileBadgeId: selectedProfileBadgeId)

            // Update profile badge image URL after successful update
            if let badgeId = selectedProfileBadgeId {
                await loadProfileBadgeImage(badgeId: badgeId)
            } else {
                profileBadgeImageUrl = nil
            }
        } catch {
            debugPrint("❌ Error updating profile: \(error)")
        }
    }

    func selectProfileBadge(_ badgeId: UUID?) {
        selectedProfileBadgeId = badgeId

        if let badgeId = badgeId {
            Task {
                await loadProfileBadgeImage(badgeId: badgeId)
            }
        } else {
            profileBadgeImageUrl = nil
        }
    }

    func signOut() async throws {
        try await authService.signOut()
    }

    func deleteAccount() async throws {
        try await userService.deleteAccount()
        // Sign out to clear local session after account deletion
        try await authService.signOut()
    }
}
