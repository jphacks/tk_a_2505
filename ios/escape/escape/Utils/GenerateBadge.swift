import Foundation
import Supabase

class BadgeGenerator {
    private let edgeFunctions = EdgeFunctions()

    // MARK: - Prompts

    private let systemPrompt = """
    You are an expert prompt engineer specializing in creating detailed, artistic prompts for image generation models like Flux Schnell. Your task is to transform brief location descriptions into vivid, highly detailed prompts that will generate beautiful collectible badges.

    Key requirements:
    - Create prompts that describe circular badge designs
    - Include specific visual elements from the location
    - Specify art style (modern, minimalist, detailed illustration)
    - Mention color schemes and lighting
    - Keep the final prompt concise but descriptive (2-3 sentences)
    - Focus on creating a collectible, game-like badge aesthetic
    """

    private let queryPromptTemplate = """
    Create a detailed image generation prompt for a circular collectible badge for the "{LOCATION_NAME}" shelter, that represents this location's unique characteristics.

    The prompt should describe:
    - A circular badge design with the location's iconic elements
    - Artistic style (illustration, modern, minimalist)
    - Color palette and visual theme
    - Composition and layout

    Return ONLY the image generation prompt, no explanation.
    """

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

    /// Generates an optimized prompt for badge creation using Gemini LLM
    private func generateBadgePrompt(
        locationName: String,
        locationDescription: String,
        colorTheme: String?
    ) async throws -> String {
        // Build the user query
        var userQuery = queryPromptTemplate.replacingOccurrences(
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
        \(systemPrompt)

        \(userQuery)
        """

        // Call Gemini to generate the optimized prompt
        let generatedPrompt = try await edgeFunctions.generateScenario(prompt: fullPrompt)

        return generatedPrompt
    }

    // MARK: - Convenience Methods

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
