//
//  BadgeViewModel.swift
//  escape
//
//  Created by YoungJune Kang on 2025/10/25.
//

import Foundation
import SwiftUI

@MainActor
@Observable
class BadgeViewModel {
    var generatedBadgeUrl: String?
    var generatedPrompt: String?
    var errorMessage: String?
    var isGenerating = false

    // MARK: - Dependencies

    private let badgeGenerator: BadgeGenerator

    // MARK: - Initialization

    init(badgeGenerator: BadgeGenerator = BadgeGenerator()) {
        self.badgeGenerator = badgeGenerator
    }

    func generateBadge(
        locationName: String,
        locationAddress: String,
        locationDescription: String,
        colorTheme: String? = nil
    ) async {
        isGenerating = true
        errorMessage = nil
        defer { isGenerating = false }

        do {
            let result = try await badgeGenerator.generateBadge(
                locationName: locationName,
                locationAddress: locationAddress,
                locationDescription: locationDescription,
                colorTheme: colorTheme
            )

            generatedBadgeUrl = result.imageUrl
            generatedPrompt = result.prompt

            debugPrint("✅ Badge generated successfully")
            debugPrint("📝 Prompt: \(result.prompt)")
        } catch {
            errorMessage = error.localizedDescription
            debugPrint("❌ Badge generation error: \(error)")
        }
    }

    func generateBadgeFromLocationName(_ locationName: String) async {
        isGenerating = true
        errorMessage = nil
        defer { isGenerating = false }

        do {
            let result = try await badgeGenerator.generateBadgeFromLocationName(locationName)

            generatedBadgeUrl = result.imageUrl
            generatedPrompt = result.prompt

            debugPrint("✅ Badge generated successfully from location name: \(locationName)")
            debugPrint("📝 Prompt: \(result.prompt)")
        } catch {
            errorMessage = error.localizedDescription
            debugPrint("❌ Badge generation error: \(error)")
        }
    }

    func generateBadgeForShelter(_ shelterName: String) async {
        isGenerating = true
        errorMessage = nil
        defer { isGenerating = false }

        do {
            let result = try await badgeGenerator.generateBadgeForShelter(shelterName)

            generatedBadgeUrl = result.imageUrl
            generatedPrompt = result.prompt

            debugPrint("✅ Badge generated for shelter: \(shelterName)")
        } catch {
            errorMessage = error.localizedDescription
            debugPrint("❌ Badge generation error: \(error)")
        }
    }

    func reset() {
        generatedBadgeUrl = nil
        generatedPrompt = nil
        errorMessage = nil
    }
}
