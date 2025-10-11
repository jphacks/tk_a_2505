import Foundation
import Supabase

class EdgeFunctions {
    // Initialize your Supabase client
    // Replace with your actual Supabase URL and anon key
    private let supabase = SupabaseClient(
        supabaseURL: URL(string: "https://YOUR_PROJECT_ID.supabase.co")!,
        supabaseKey: "YOUR_ANON_KEY"
    )
    
    // MARK: - Generate Image with Replicate
    
    /// Generates an image using the Replicate edge function
    /// - Parameter prompt: The text prompt for image generation
    /// - Returns: The URL of the generated image
    func generateImage(prompt: String) async throws -> String {
        // Prepare the request body
        let requestBody: [String: String] = [
            "prompt": prompt
        ]
        
        // Call the edge function
        let response = try await supabase.functions.invoke(
            "your-function-name",  // Replace with your actual function name
            options: FunctionInvokeOptions(
                body: requestBody
            )
        )
        
        // Decode the response
        struct ImageResponse: Codable {
            let imageUrl: String
            let prompt: String
        }
        
        let decoder = JSONDecoder()
        let imageResponse = try decoder.decode(ImageResponse.self, from: response.data)
        
        return imageResponse.imageUrl
    }
    
    // MARK: - Generate Scenario with Gemini (your existing function)
    
    /// Generates a scenario using the Gemini edge function
    /// - Parameter prompt: The text prompt for scenario generation
    /// - Returns: The generated scenario text
    func generateScenario(prompt: String) async throws -> String {
        let requestBody: [String: String] = [
            "prompt": prompt
        ]
        
        let response = try await supabase.functions.invoke(
            "gemini-function-name",  // Replace with your Gemini function name
            options: FunctionInvokeOptions(
                body: requestBody
            )
        )
        
        struct ScenarioResponse: Codable {
            let scenario: String
        }
        
        let decoder = JSONDecoder()
        let scenarioResponse = try decoder.decode(ScenarioResponse.self, from: response.data)
        
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
            case .serverError(let message):
                return "Server error: \(message)"
            }
        }
    }
}