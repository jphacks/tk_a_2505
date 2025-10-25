//
//  MissionResultViewModel.swift
//  escape
//
//  Created by YoungJune Kang on 2025/10/25.
//

import Foundation
import SwiftUI

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

    // MARK: - Dependencies

    let badgeViewModel: BadgeViewModel // Made public for BadgeGenerationSection component
    private let badgeService: BadgeSupabase
    private let shelterService: ShelterSupabase
    private let authService: AuthSupabase

    // MARK: - Initialization

    init(
        badgeViewModel: BadgeViewModel,
        badgeService: BadgeSupabase = BadgeSupabase(),
        shelterService: ShelterSupabase = ShelterSupabase(),
        authService: AuthSupabase = AuthSupabase()
    ) {
        self.badgeViewModel = badgeViewModel
        self.badgeService = badgeService
        self.shelterService = shelterService
        self.authService = authService
    }

    // MARK: - Actions

    func handleMissionCompletion(shelter: Shelter) async {
        do {
            isGeneratingBadge = true

            // Convert shelter.id (String) to UUID
            guard let shelterUUID = UUID(uuidString: shelter.id) else {
                errorMessage = "Invalid shelter ID format"
                isGeneratingBadge = false
                return
            }

            // Step 0: Verify shelter exists in database using ShelterSupabase
            let shelterExists = try await shelterService.verifyShelterExists(shelterUUID: shelterUUID)
            if !shelterExists {
                errorMessage = "Shelter not found in database. Please use a real shelter from the database."
                isGeneratingBadge = false
                return
            }

            // Step 1: Check if badge exists for this shelter in shelter_badges table
            let existingBadge = try await badgeService.getBadgeForShelter(shelterId: shelterUUID)

            if let badge = existingBadge {
                // Badge exists in shelter_badges table
                // Convert to Badge UI model and display immediately
                acquiredBadge = createBadgeUIModel(from: badge, shelter: shelter)
                generatedBadgeUrl = badge.getImageUrl()

                // Add to user_shelter_badges table (if not already added)
                try? await badgeService.unlockBadge(badgeId: badge.id)

                isBadgeGenerated = true
                isGeneratingBadge = false
            } else {
                // No badge exists in shelter_badges table - user is first visitor
                isFirstVisitor = true
                showDescriptionInput = true
                isGeneratingBadge = false
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
                try? await badgeService.unlockBadge(badgeId: existingBadge.id)
                isBadgeGenerated = true
                showSuccessAlert = true
                return
            }

            // Generate badge using devtools method with user description
            await badgeViewModel.generateBadge(
                locationName: shelter.name,
                locationDescription: userDescription.isEmpty ? "A notable shelter location" : userDescription,
                colorTheme: nil
            )

            if let badgeUrl = badgeViewModel.generatedBadgeUrl {
                generatedBadgeUrl = badgeUrl

                // Extract filename from URL for badge name
                let badgeFileName = extractFileNameFromUrl(badgeUrl) ?? "badge_\(Int(Date().timeIntervalSince1970 * 1000)).png"

                // Final check before creating to prevent race conditions
                let finalCheck = try await badgeService.getBadgeForShelter(shelterId: shelterUUID)
                if let existingBadge = finalCheck {
                    // Badge was created by another request, use it instead
                    acquiredBadge = createBadgeUIModel(from: existingBadge, shelter: shelter)
                    generatedBadgeUrl = existingBadge.getImageUrl()
                    try? await badgeService.unlockBadge(badgeId: existingBadge.id)
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

    // Helper function to create Badge UI model
    private func createBadgeUIModel(from shelterBadge: ShelterBadge, shelter: Shelter, imageUrl: String? = nil) -> Badge {
        Badge(
            id: shelterBadge.id.uuidString,
            name: shelter.name,
            icon: "star.fill",
            color: .orange,
            isUnlocked: true,
            imageName: nil,
            imageUrl: imageUrl ?? shelterBadge.getImageUrl(),
            badgeNumber: shelter.commonId,
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
}
