import Foundation
import Supabase

class BadgeGenerator {
    private let edgeFunctions = EdgeFunctions()
    
    // MARK: - Prompt File Paths
    private let systemPromptPath = "prompts/badgeprompts/system_prompt.md"
    private let queryPromptPath = "prompts/badgeprompts/query_prompt.md"
    
    // MARK: - Prompt Loading
    
    /// Loads the content of a markdown file from the bundle
    private func loadPromptFile(_ filename: String) throws -> String {
        guard let fileURL = Bundle.main.url(forResource: filename.replacingOccurrences(of: ".md", with: ""), withExtension: "md", subdirectory: "prompts/badgeprompts") else {
            throw BadgeGeneratorError.promptFileNotFound(filename)
        }
        
        do {
            let content = try String(contentsOf: fileURL, encoding: .utf8)
            return content.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            throw BadgeGeneratorError.promptFileReadError(filename, error)
        }
    }
    
    /// Loads system and query prompts
    private func loadPrompts() throws -> (systemPrompt: String, queryPrompt: String) {
        let systemPrompt = try loadPromptFile("system_prompt.md")
        let queryPrompt = try loadPromptFile("query_prompt.md")
        return (systemPrompt, queryPrompt)
    }
    
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
        
        // Load prompts from markdown files
        let prompts = try loadPrompts()
        
        // Build the user query by replacing placeholders in query_prompt.md
        var userQuery = prompts.queryPrompt
        
        // Replace location name placeholder
        userQuery = userQuery.replacingOccurrences(of: "\"後楽園\"", with: "\"\(locationName)\"")
        
        // Add location description
        let locationInfo = """
        
        Location details: \(locationDescription)
        \(colorTheme.map { "Color theme: \($0)" } ?? "")
        """
        
        // Insert location info after the shelter name line
        if let range = userQuery.range(of: "shelter, that represents") {
            let insertPosition = userQuery.index(range.upperBound, offsetBy: 0)
            userQuery.insert(contentsOf: locationInfo, at: insertPosition)
        }
        
        let fullPrompt = """
        \(prompts.systemPrompt)
        
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

// MARK: - Error Handling

extension BadgeGenerator {
    enum BadgeGeneratorError: LocalizedError {
        case promptFileNotFound(String)
        case promptFileReadError(String, Error)
        
        var errorDescription: String? {
            switch self {
            case .promptFileNotFound(let filename):
                return "Prompt file not found: \(filename)"
            case .promptFileReadError(let filename, let error):
                return "Failed to read prompt file \(filename): \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - Usage Example in a View Model or Controller

class BadgeViewModel {
    private let badgeGenerator = BadgeGenerator()
    
    @Published var isGenerating = false
    @Published var generatedBadgeUrl: String?
    @Published var errorMessage: String?
    
    func createBadgeForLocation(name: String, description: String) {
        isGenerating = true
        errorMessage = nil
        
        Task {
            do {
                let result = try await badgeGenerator.generateBadge(
                    locationName: name,
                    locationDescription: description
                )
                
                await MainActor.run {
                    self.generatedBadgeUrl = result.imageUrl
                    self.isGenerating = false
                }
                
                print("Generated badge with prompt: \(result.prompt)")
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isGenerating = false
                }
            }
        }
    }
    
    func createBadgeForShelter(name: String) {
        isGenerating = true
        errorMessage = nil
        
        Task {
            do {
                let result = try await badgeGenerator.generateBadgeForShelter(name)
                
                await MainActor.run {
                    self.generatedBadgeUrl = result.imageUrl
                    self.isGenerating = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isGenerating = false
                }
            }
        }
    }
}