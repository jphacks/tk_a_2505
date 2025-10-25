//
//  MissionGenerationService.swift
//  escape
//
//  Created by YoungJune Kang on 2025/10/25.
//

import Foundation
import Supabase

class MissionGenerator {
    private let edgeFunctions = EdgeFunctionsSupabase()

    // MARK: - Request/Response Types

    /// Request body for mission generation
    struct MissionRequest: Codable {
        let context: String?
        let disasterTypeHint: String?
        let steps: Int64?
        let distances: Double?

        enum CodingKeys: String, CodingKey {
            case context
            case disasterTypeHint = "disaster_type_hint"
            case steps
            case distances
        }
    }

    /// Response from mission generation edge function
    struct MissionResponse: Codable {
        let mission: Mission
        let generatedPrompt: String?

        enum CodingKeys: String, CodingKey {
            case mission
            case generatedPrompt = "generated_prompt"
        }
    }

    // MARK: - Mission Generation

    /// Generates a mission using the Supabase edge function
    /// - Parameters:
    ///   - context: Optional context for mission generation
    ///   - disasterTypeHint: Optional disaster type hint to focus on
    ///   - steps: Optional step count to associate with the mission
    ///   - distances: Optional distance to associate with the mission
    /// - Returns: The generated Mission object
    func generateMission(
        context: String? = nil,
        disasterTypeHint: DisasterType? = nil,
        steps: Int64? = nil,
        distances: Double? = nil
    ) async throws -> Mission {
        // Prepare the request body
        let requestBody = MissionRequest(
            context: context,
            disasterTypeHint: disasterTypeHint?.rawValue,
            steps: steps,
            distances: distances
        )

        // Call the edge function and decode directly
        let missionResponse: MissionResponse = try await supabase.functions.invoke(
            "generate_mission",
            options: FunctionInvokeOptions(body: requestBody)
        )

        return missionResponse.mission
    }

    // MARK: - Convenience Methods

    /// Generates a mission with a specific disaster type
    func generateMissionForDisasterType(_ disasterType: DisasterType) async throws -> Mission {
        return try await generateMission(disasterTypeHint: disasterType)
    }

    /// Generates a mission with context and activity data
    func generateMissionWithActivityData(
        context: String,
        steps: Int64,
        distances: Double
    ) async throws -> Mission {
        return try await generateMission(
            context: context,
            steps: steps,
            distances: distances
        )
    }

    /// Generates a random mission (no parameters)
    func generateRandomMission() async throws -> Mission {
        return try await generateMission()
    }
}

// MARK: - Error Handling Extension

extension MissionGenerator {
    enum MissionGenerationError: LocalizedError {
        case networkError
        case decodingError
        case serverError(String)
        case invalidResponse
        case authenticationRequired

        var errorDescription: String? {
            switch self {
            case .networkError:
                return "Network connection failed"
            case .decodingError:
                return "Failed to decode mission response"
            case let .serverError(message):
                return "Server error: \(message)"
            case .invalidResponse:
                return "Received invalid response from server"
            case .authenticationRequired:
                return "Authentication is required to generate missions"
            }
        }
    }
}
