//
//  MissionResultViewModel.swift
//  escape
//
//  Created by YoungJune Kang on 2025/10/25.
//

import Foundation
import SwiftUI

// Carry the text and optional image URL we want to hand to the share sheet.
struct BadgeSharePayload {
    let message: String
    let imageURL: URL?
}

@MainActor
@Observable
class MissionResultViewModel {
    var isGeneratingBadge = false
    var isBadgeGenerated = false
    var showSuccessAlert = false
    var errorMessage: String?
    var generatedBadgeUrl: String?
    var isFirstVisitor = false
    var showDescriptionInput = false
    var userDescription = ""
    var acquiredBadge: Badge?
    var missionResult: MissionResult?
    var currentUserPoints: Int64 = 0
    var currentUserRank: Int?
    // Prepare the text and optional image link we want to share when a badge is unlocked.
    var sharePayload: BadgeSharePayload? {
        guard let badge = acquiredBadge else { return nil }
        // Pull a localized template and inject the badge name so the share message respects each language.
        let template = NSLocalizedString(
            "badge_share_message", comment: "Share message shown when a badge is earned"
        )
        return BadgeSharePayload(
            message: String(format: template, badge.name),
            imageURL: badge.imageUrl.flatMap { URL(string: $0) }
        )
    }

    // Cache the raw image data once we download the badge artwork for sharing.
    var shareImageData: Data?
    // Cache a snapshot image (as data) so we can show it in the share sheet preview.
    var shareSnapshotData: Data?
    var badgeSkillLevel: Int = 0

    // MARK: - Dependencies

    let badgeViewModel: BadgeViewModel // Made public for BadgeGenerationSection component
    private let badgeService: BadgeSupabase
    private let shelterService: ShelterSupabase
    private let authService: AuthSupabase
    private let missionResultService: MissionResultSupabase
    private let missionService: MissionSupabase
    private let pointService: PointSupabase
    private let missionId: UUID

    // MARK: - Initialization

    init(
        badgeViewModel: BadgeViewModel,
        missionId: UUID,
        initialMissionResult: MissionResult? = nil,
        badgeService: BadgeSupabase = BadgeSupabase(),
        shelterService: ShelterSupabase = ShelterSupabase(),
        authService: AuthSupabase = AuthSupabase(),
        missionResultService: MissionResultSupabase = MissionResultSupabase(),
        missionService: MissionSupabase = MissionSupabase(),
        pointService: PointSupabase = PointSupabase()
    ) {
        self.badgeViewModel = badgeViewModel
        self.missionId = missionId
        missionResult = initialMissionResult
        self.badgeService = badgeService
        self.shelterService = shelterService
        self.authService = authService
        self.missionResultService = missionResultService
        self.missionService = missionService
        self.pointService = pointService
    }

    // MARK: - Actions

    func handleMissionCompletion(shelter: Shelter) async {
        do {
            // Step 0: Mark mission as completed in database
            print("📝 Marking mission \(missionId) as completed...")
            do {
                try await missionService.updateMissionStatus(missionId: missionId, status: .completed)
                print("✅ Mission status updated to 'done'")
            } catch {
                print("❌ Failed to update mission status: \(error)")
                // Don't block the badge generation if status update fails
            }

            isGeneratingBadge = true

            // Convert shelter.id (String) to UUID
            guard let shelterUUID = UUID(uuidString: shelter.id) else {
                errorMessage = "Invalid shelter ID format"
                isGeneratingBadge = false
                return
            }

            // Step 1: Verify shelter exists in database using ShelterSupabase
            let shelterExists = try await shelterService.verifyShelterExists(shelterUUID: shelterUUID)
            if !shelterExists {
                errorMessage = "Shelter not found in database. Please use a real shelter from the database."
                isGeneratingBadge = false
                return
            }

            // Step 2: Check if badge exists for this shelter in shelter_badges table
            let existingBadge = try await badgeService.getBadgeForShelter(shelterId: shelterUUID)

            if let badge = existingBadge {
                // Badge exists in shelter_badges table
                // Convert to Badge UI model and display immediately
                acquiredBadge = createBadgeUIModel(from: badge, shelter: shelter)
                generatedBadgeUrl = badge.getImageUrl()

                // Add to user_shelter_badges table (if not already added)
                do {
                    _ = try await badgeService.unlockBadge(badgeId: badge.id)
                } catch {
                    debugPrint("❌ Failed to unlock badge: \(error)")
                }

                isBadgeGenerated = true
                isGeneratingBadge = false
            } else {
                // No badge exists in shelter_badges table - user is first visitor
                isFirstVisitor = true
                showDescriptionInput = true
                isGeneratingBadge = false
            }

            // Step 3: Refresh user's total points and rank after mission completion
            // This should happen after mission result is created (which happens before this view is shown)
            print("💰 Refreshing user total points and rank...")
            do {
                let currentUserId = try await authService.getCurrentUserId()
                let updatedPoints = try await pointService.refreshUserPoints(userId: currentUserId)
                currentUserPoints = updatedPoints.point ?? 0
                print("✅ User points refreshed: \(currentUserPoints)")

                // Get user's national ranking
                currentUserRank = try await pointService.getUserNationalRank(userId: currentUserId)
                print("🏆 User rank: \(currentUserRank ?? 0)")
            } catch {
                print("⚠️ Failed to refresh points/rank: \(error)")
                // Don't block UI if points refresh fails
            }

        } catch {
            errorMessage = error.localizedDescription
            isGeneratingBadge = false
        }
    }

    func generateBadgeWithDescription(shelter: Shelter) async {
        isGeneratingBadge = true
        showDescriptionInput = false

        do {
            // Convert shelter.id to UUID
            guard let shelterUUID = UUID(uuidString: shelter.id) else {
                errorMessage = "Invalid shelter ID format"
                isGeneratingBadge = false
                return
            }

            // Verify shelter exists in database using ShelterSupabase
            let shelterExists = try await shelterService.verifyShelterExists(shelterUUID: shelterUUID)
            if !shelterExists {
                errorMessage = "Shelter not found in database. Please use a real shelter from the database."
                isGeneratingBadge = false
                return
            }

            // Double-check that badge doesn't exist before generating
            let existingBadgeRecheck = try await badgeService.getBadgeForShelter(shelterId: shelterUUID)
            if let existingBadge = existingBadgeRecheck {
                // Badge was created by another request, use it
                acquiredBadge = createBadgeUIModel(from: existingBadge, shelter: shelter)
                generatedBadgeUrl = existingBadge.getImageUrl()
                do {
                    _ = try await badgeService.unlockBadge(badgeId: existingBadge.id)
                } catch {
                    debugPrint("❌ Failed to unlock existing badge: \(error)")
                }
                isBadgeGenerated = true
                showSuccessAlert = true
                return
            }

            // Generate badge using devtools method with shelter info and user description
            await badgeViewModel.generateBadge(
                locationName: shelter.name,
                locationAddress: shelter.address,
                locationDescription: userDescription.isEmpty
                    ? "A notable shelter location" : userDescription,
                colorTheme: nil
            )

            if let badgeUrl = badgeViewModel.generatedBadgeUrl {
                generatedBadgeUrl = badgeUrl

                // Extract filename from URL for badge name
                let badgeFileName =
                    extractFileNameFromUrl(badgeUrl)
                        ?? "badge_\(Int(Date().timeIntervalSince1970 * 1000)).png"

                // Final check before creating to prevent race conditions
                let finalCheck = try await badgeService.getBadgeForShelter(shelterId: shelterUUID)
                if let existingBadge = finalCheck {
                    // Badge was created by another request, use it instead
                    acquiredBadge = createBadgeUIModel(from: existingBadge, shelter: shelter)
                    generatedBadgeUrl = existingBadge.getImageUrl()
                    do {
                        _ = try await badgeService.unlockBadge(badgeId: existingBadge.id)
                    } catch {
                        debugPrint("❌ Failed to unlock final check badge: \(error)")
                    }
                    isBadgeGenerated = true
                    showSuccessAlert = true
                    return
                }

                // Get current user ID using AuthSupabase
                let currentUserId = try await authService.getCurrentUserId()

                // Step 1: Create shelter badge in shelter_badges table
                let createdBadge = try await badgeService.createShelterBadge(
                    badgeName: badgeFileName,
                    shelterId: shelterUUID,
                    firstUserId: currentUserId
                )

                // Step 2: Add to user_shelter_badges table
                try await badgeService.unlockBadge(badgeId: createdBadge.id)

                // Step 3: Create Badge UI model and display
                acquiredBadge = createBadgeUIModel(from: createdBadge, shelter: shelter, imageUrl: badgeUrl)

                isBadgeGenerated = true
                showSuccessAlert = true
            } else if let error = badgeViewModel.errorMessage {
                errorMessage = error
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isGeneratingBadge = false
    }

    // MARK: - Helper Methods

    // Download the badge artwork so the share sheet can include the actual image.
    func loadShareImageData() async {
        guard shareImageData == nil,
              let url = sharePayload?.imageURL
        else {
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            shareImageData = data
        } catch {
            print("Failed to load badge image for sharing: \(error)")
        }
    }

    // Helper function to create Badge UI model
    private func createBadgeUIModel(
        from shelterBadge: ShelterBadge, shelter: Shelter, imageUrl: String? = nil
    ) -> Badge {
        Badge(
            id: shelterBadge.id.uuidString,
            name: shelter.name,
            icon: "star.fill",
            color: .orange,
            isUnlocked: true,
            imageName: nil,
            imageUrl: imageUrl ?? shelterBadge.getImageUrl(),
            badgeNumber: shelter.number?.description,
            address: shelter.address,
            municipality: shelter.municipality,
            isShelter: shelter.isShelter ?? false,
            isFlood: shelter.isFlood ?? false,
            isLandslide: shelter.isLandslide ?? false,
            isStormSurge: shelter.isStormSurge ?? false,
            isEarthquake: shelter.isEarthquake ?? false,
            isTsunami: shelter.isTsunami ?? false,
            isFire: shelter.isFire ?? false,
            isInlandFlood: shelter.isInlandFlood ?? false,
            isVolcano: shelter.isVolcano ?? false,
            latitude: shelter.latitude,
            longitude: shelter.longitude,
            firstUserName: "You"
        )
    }

    // Helper function to extract filename from URL
    private func extractFileNameFromUrl(_ urlString: String) -> String? {
        guard let url = URL(string: urlString) else { return nil }
        let fileName = url.lastPathComponent

        // If the filename doesn't contain a proper extension, return nil
        if fileName.contains(".") {
            return fileName
        }

        return nil
    }

    // MARK: - Skill Level Methods

    /// Fetches mission result count for the badge's shelter and calculates skill level
    /// - Parameter badge: The badge to calculate skill level for
    func loadBadgeSkillLevel(for badge: Badge) async {
        guard let shelterUUID = UUID(uuidString: badge.id) else {
            print("❌ Invalid badge shelter ID: \(badge.id)")
            return
        }

        do {
            let currentUserId = try await authService.getCurrentUserId()
            let missionResults = try await missionResultService.getUserShelterMissionResults(
                userId: currentUserId,
                shelterId: shelterUUID
            )
            let starCount = SkillLevelCalculator.calculateStarCount(from: missionResults.count)

            await MainActor.run {
                badgeSkillLevel = starCount
            }

            print(
                "✅ Loaded skill level for badge \(badge.name): \(starCount) stars (\(missionResults.count) missions)"
            )
        } catch {
            print("❌ Failed to load badge skill level: \(error)")
            await MainActor.run {
                badgeSkillLevel = 0
            }
        }
    }
}
