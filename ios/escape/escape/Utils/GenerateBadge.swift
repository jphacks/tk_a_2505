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

        let locationDetailsPrompt = """
        \(locationInfo), generate a detailed description and color theme for creating a collectible badge.

        Provide your response in the following format:
        DESCRIPTION: [A detailed description of the location's key visual characteristics, iconic elements, architectural features, natural elements, or cultural significance. 2-3 sentences.]
        COLOR_THEME: [Specific color palette that represents this location, e.g., "modern urban blues and greys, traditional greens and reds"]

        Here is an example:

        Input: Location name "後楽園" at address "Tokyo, Bunkyo City, Koraku 1-3-61"
        Output:
        DESCRIPTION: Features the iconic Tokyo Dome stadium, Kōrakuen Garden with traditional Japanese elements like bridges and ginkgo trees, and amusement park rides including Ferris wheels and roller coasters
        COLOR_THEME: modern urban blues and greys for the Dome, traditional greens, reds, and golds for the garden elements

        Now generate the description and color theme for the given location. Be specific and visual in your descriptions. Focus on elements that would make a great badge design.
        """

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
