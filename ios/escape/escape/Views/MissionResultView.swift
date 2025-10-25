//
//  MissionResultView.swift
//  escape
//
//  Created for mission result and badge management
//

import SwiftUI

struct MissionResultView: View {
    let mission: Mission
    let shelter: Shelter

    @State private var badgeViewModel = BadgeViewModel()
    @State private var viewModel: MissionResultViewModel
    @Environment(\.dismiss) private var dismiss

    init(mission: Mission, shelter: Shelter) {
        self.mission = mission
        self.shelter = shelter

        // Create BadgeViewModel and pass it to MissionResultViewModel
        let badge = BadgeViewModel()
        _badgeViewModel = State(initialValue: badge)
        _viewModel = State(initialValue: MissionResultViewModel(badgeViewModel: badge))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Mission Completion Header with Badge
                    VStack(spacing: 16) {
                        // Badge Display
                        if let badge = viewModel.acquiredBadge {
                            InteractiveBadgeView(badge: badge)
                        } else if viewModel.isGeneratingBadge {
                            VStack(spacing: 12) {
                                ProgressView()
                                    .scaleEffect(1.5)
                                    .frame(width: 80, height: 80)

                                Text("result.loading_badge")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            // Placeholder while loading
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 30))
                                        .foregroundColor(.gray)
                                )
                        }

                        Text("result.mission_completed")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("result.congratulations")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)

                    // Mission Stats
                    VStack(spacing: 16) {
                        HStack {
                            StatCard(
                                title: "result.steps",
                                value: mission.steps.map { "\($0)" } ?? "0",
                                icon: "figure.walk"
                            )

                            StatCard(
                                title: "result.distance",
                                value: mission.distances.map { String(format: "%.1f km", $0 / 1000) } ?? "0 km",
                                icon: "map"
                            )
                        }

                        if let disasterType = mission.disasterType {
                            StatCard(
                                title: "result.disaster_type",
                                value: disasterType.localizedName,
                                icon: disasterType.iconName
                            )
                        }
                    }

                    // Shelter Information
                    ShelterInfoCard(shelter: shelter)

                    // Badge Generation Section
                    BadgeGenerationSection(
                        shelter: shelter,
                        isGeneratingBadge: $viewModel.isGeneratingBadge,
                        isBadgeGenerated: $viewModel.isBadgeGenerated,
                        isFirstVisitor: $viewModel.isFirstVisitor,
                        generatedBadgeUrl: $viewModel.generatedBadgeUrl,
                        errorMessage: $viewModel.errorMessage,
                        badgeViewModel: viewModel.badgeViewModel,
                        showDescriptionInput: $viewModel.showDescriptionInput,
                        userDescription: $viewModel.userDescription,
                        acquiredBadge: $viewModel.acquiredBadge,
                        onGenerateBadge: {
                            await viewModel.generateBadgeWithDescription(shelter: shelter)
                        }
                    )

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
            }
            .navigationTitle("result.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("result.close") {
                        dismiss()
                    }
                }
            }
            .alert("result.badge_generated", isPresented: $viewModel.showSuccessAlert) {
                Button("result.ok") {}
            } message: {
                Text(viewModel.isFirstVisitor ? "result.first_visitor_message" : "result.badge_unlocked_message")
            }
            .task {
                await viewModel.handleMissionCompletion(shelter: shelter)
            }
        }
    }
}

#Preview {
    MissionResultView(
        mission: Mission(
            id: UUID(),
            userId: UUID(),
            title: "避難訓練",
            overview: "地震の避難訓練",
            disasterType: .earthquake,
            evacuationRegion: "東京都",
            status: .completed,
            steps: 1234,
            distances: 850.0,
            createdAt: Date()
        ),
        shelter: Shelter(
            id: UUID().uuidString,
            number: 1,
            commonId: "TEST001",
            name: "後楽園避難所",
            address: "東京都文京区後楽1-3-61",
            municipality: "文京区",
            isShelter: true,
            isFlood: false,
            isLandslide: false,
            isStormSurge: false,
            isEarthquake: true,
            isTsunami: false,
            isFire: true,
            isInlandFlood: false,
            isVolcano: false,
            isSameAddressAsShelter: true,
            otherMunicipalNotes: nil,
            acceptedPeople: nil,
            latitude: 35.7056,
            longitude: 139.7519,
            remarks: nil,
            lastUpdated: Date()
        )
    )
}
