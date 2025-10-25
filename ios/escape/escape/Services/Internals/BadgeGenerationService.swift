//
//  BadgeGenerationService.swift
//  escape
//
//  Created by YoungJune Kang on 2025/10/25.
//

import Foundation
import Supabase

class BadgeGenerator {
    private let edgeFunctions = EdgeFunctionsSupabase()

    // MARK: - Prompts Configuration

    private struct PromptsConfig: Codable {
        struct BadgeGeneration: Codable {
            let systemPrompt: String
            let queryTemplate: String
            let locationDetailsPrompt: String
        }

        let badgeGeneration: BadgeGeneration
    }

    private lazy var prompts: PromptsConfig.BadgeGeneration = {
        guard let url = Bundle.main.url(forResource: "Prompts", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let config = try? JSONDecoder().decode(PromptsConfig.self, from: data)
        else {
            fatalError("Failed to load Prompts.json")
        }
        return config.badgeGeneration
    }()

    // MARK: - Badge Generation

    /// Generates a collectible badge for a given location/shelter
    /// - Parameters:
    ///   - locationName: The name of the location/shelter (e.g., "後楽園")
    ///   - locationDescription: Brief description of the location's characteristics
    ///   - colorTheme: Optional color theme (e.g., "blues and greens", "reds and golds")
    /// - Returns: Tuple containing the badge image URL and the prompt used
    func generateBadge(
        locationName: String,
        locationDescription: String,
        colorTheme: String? = nil
    ) async throws -> (imageUrl: String, prompt: String) {
        // Step 1: Generate the optimized prompt using Gemini
        let badgePrompt = try await generateBadgePrompt(
            locationName: locationName,
            locationDescription: locationDescription,
            colorTheme: colorTheme
        )

        // Step 2: Generate the badge image using Flux Schnell
        let imageUrl = try await edgeFunctions.generateImage(prompt: badgePrompt)

        return (imageUrl, badgePrompt)
    }

    // MARK: - Private Helper Methods

    /// Fetches the shelter address from Supabase by name
    /// - Parameter locationName: The name of the shelter
    /// - Returns: The address string, or empty string if not found
    private func fetchShelterAddress(locationName: String) async -> String {
        do {
            struct Shelter: Codable {
                let address: String
            }

            let response: [Shelter] = try await supabase
                .from("shelters")
                .select("address")
                .eq("name", value: locationName)
                .limit(1)
                .execute()
                .value

            return response.first?.address ?? ""
        } catch {
            debugPrint("⚠️ Failed to fetch shelter address: \(error)")
            return ""
        }
    }

    /// Uses AI to generate location description and color theme from just the location name
    /// - Parameter locationName: The name of the location
    /// - Returns: Tuple containing (locationDescription, colorTheme)
    private func generateLocationDetails(locationName: String) async throws -> (description: String, colorTheme: String) {
        // Fetch the address from the shelters table
        let address = await fetchShelterAddress(locationName: locationName)

        // Build the prompt with both name and address
        var locationInfo = "Given the location name \"\(locationName)\""
        if !address.isEmpty {
            locationInfo += " at address \"\(address)\""
        }

        let locationDetailsPrompt = prompts.locationDetailsPrompt
            .replacingOccurrences(of: "{LOCATION_INFO}", with: locationInfo)

        // Call Gemini to generate location details
        let response = try await edgeFunctions.generateScenario(prompt: locationDetailsPrompt)

        // Parse the response
        let (description, colorTheme) = parseLocationDetails(from: response)

        return (description, colorTheme)
    }

    /// Parses the AI response to extract description and color theme
    private func parseLocationDetails(from response: String) -> (description: String, colorTheme: String) {
        let lines = response.components(separatedBy: .newlines)

        var description = "A notable location"
        var colorTheme = "vibrant and diverse colors"

        for line in lines {
            if line.hasPrefix("DESCRIPTION:") {
                description = line.replacingOccurrences(of: "DESCRIPTION:", with: "").trimmingCharacters(in: .whitespaces)
            } else if line.hasPrefix("COLOR_THEME:") {
                colorTheme = line.replacingOccurrences(of: "COLOR_THEME:", with: "").trimmingCharacters(in: .whitespaces)
            }
        }

        return (description, colorTheme)
    }

    /// Generates an optimized prompt for badge creation using Gemini LLM
    private func generateBadgePrompt(
        locationName: String,
        locationDescription: String,
        colorTheme: String?
    ) async throws -> String {
        // Build the user query
        var userQuery = prompts.queryTemplate.replacingOccurrences(
            of: "{LOCATION_NAME}",
            with: locationName
        )

        // Add location details
        let locationInfo = """

        Location details: \(locationDescription)
        \(colorTheme.map { "Color theme: \($0)" } ?? "")
        """

        userQuery += locationInfo

        // Combine system prompt and user query
        let fullPrompt = """
        \(prompts.systemPrompt)

        \(userQuery)
        """

        // Call Gemini to generate the optimized prompt
        let generatedPrompt = try await edgeFunctions.generateScenario(prompt: fullPrompt)

        return generatedPrompt
    }

    // MARK: - Convenience Methods

    /// Generates a badge using AI to create locationDescription and colorTheme from just the location name
    /// - Parameter locationName: The name of the location (e.g., "後楽園", "Tokyo Tower")
    /// - Returns: Tuple containing the badge image URL and the prompt used
    func generateBadgeFromLocationName(_ locationName: String) async throws -> (imageUrl: String, prompt: String) {
        // Step 1: Use AI to generate location description and color theme
        let (locationDescription, colorTheme) = try await generateLocationDetails(locationName: locationName)

        // Step 2: Generate the badge using the AI-generated details
        return try await generateBadge(
            locationName: locationName,
            locationDescription: locationDescription,
            colorTheme: colorTheme
        )
    }

    /// Quick badge generation with preset location data
    func generateBadgeForShelter(_ shelterName: String) async throws -> (imageUrl: String, prompt: String) {
        // You can add a dictionary of preset locations here
        let locationInfo = getShelterInfo(shelterName)

        return try await generateBadge(
            locationName: shelterName,
            locationDescription: locationInfo.description,
            colorTheme: locationInfo.colorTheme
        )
    }

    /// Get predefined shelter information
    private func getShelterInfo(_ shelterName: String) -> (description: String, colorTheme: String?) {
        // Add your shelter database here
        let shelterDatabase: [String: (String, String?)] = [
            "後楽園": (
                "Features the iconic Tokyo Dome stadium, Kōrakuen Garden with traditional Japanese elements like bridges and ginkgo trees, and amusement park rides including Ferris wheels and roller coasters",
                "modern urban blues and greys for the Dome, traditional greens, reds, and golds for the garden elements"
            ),
            // Add more shelters as needed
        ]

        return shelterDatabase[shelterName] ?? (
            "A notable shelter location in Tokyo",
            nil
        )
    }
}
