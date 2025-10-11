import Foundation
import Supabase

class EdgeFunctions {
    // MARK: - Generate Image with Replicate

    /// Generates an image using the Replicate edge function
    /// - Parameter prompt: The text prompt for image generation
    /// - Returns: The URL of the generated image
    func generateImage(prompt: String) async throws -> String {
        // Prepare the request body
        let requestBody: [String: String] = [
            "prompt": prompt,
        ]

        // Define the response type
        struct ImageResponse: Codable {
            let imageUrl: String
            let prompt: String
        }

        // Call the edge function and decode directly
        let imageResponse: ImageResponse = try await supabase.functions.invoke(
            "flux-schnell",
            options: FunctionInvokeOptions(body: requestBody)
        )

        return imageResponse.imageUrl
    }

    // MARK: - Generate Scenario with Gemini (your existing function)

    /// Generates a scenario using the Gemini edge function
    /// - Parameter prompt: The text prompt for scenario generation
    /// - Returns: The generated scenario text
    func generateScenario(prompt: String) async throws -> String {
        let requestBody: [String: String] = [
            "prompt": prompt,
        ]

        struct ScenarioResponse: Codable {
            let scenario: String
        }

        // Call the edge function and decode directly
        let scenarioResponse: ScenarioResponse = try await supabase.functions.invoke(
            "gemini-llm",
            options: FunctionInvokeOptions(body: requestBody)
        )

        return scenarioResponse.scenario
    }
}

// MARK: - Error Handling Extension

extension EdgeFunctions {
    enum EdgeFunctionError: LocalizedError {
        case networkError
        case decodingError
        case serverError(String)

        var errorDescription: String? {
            switch self {
            case .networkError:
                return "Network connection failed"
            case .decodingError:
                return "Failed to decode response"
            case let .serverError(message):
                return "Server error: \(message)"
            }
        }
    }
}
