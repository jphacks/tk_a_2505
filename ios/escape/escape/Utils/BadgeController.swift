//
//  BadgeController.swift
//  escape
//
//  Created for badge generation management
//

import Foundation
import SwiftUI

@MainActor
@Observable
class BadgeController {
    var generatedBadgeUrl: String?
    var generatedPrompt: String?
    var errorMessage: String?
    var isGenerating = false

    private let badgeGenerator = BadgeGenerator()

    func generateBadge(
        locationName: String,
        locationDescription: String,
        colorTheme: String? = nil
    ) async {
        isGenerating = true
        errorMessage = nil
        defer { isGenerating = false }

        do {
            let result = try await badgeGenerator.generateBadge(
                locationName: locationName,
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
