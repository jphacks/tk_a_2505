//
//  MissionResultView.swift
//  escape
//
//  Created for mission result and badge management
//

import Supabase
import SwiftUI

struct MissionResultView: View {
    let mission: Mission
    let shelter: Shelter

    @State private var badgeController = BadgeController()
    @State private var badgeService = BadgeService()
    @State private var isGeneratingBadge = false
    @State private var isBadgeGenerated = false
    @State private var showSuccessAlert = false
    @State private var errorMessage: String?
    @State private var generatedBadgeUrl: String?
    @State private var isFirstVisitor = false
    @State private var showDescriptionInput = false
    @State private var userDescription = ""
    @State private var acquiredBadge: Badge?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Mission Completion Header with Badge
                    VStack(spacing: 16) {
                        // Badge Display
                        if let badge = acquiredBadge {
                            InteractiveBadgeView(badge: badge)
                        } else if isGeneratingBadge {
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
                        isGeneratingBadge: $isGeneratingBadge,
                        isBadgeGenerated: $isBadgeGenerated,
                        isFirstVisitor: $isFirstVisitor,
                        generatedBadgeUrl: $generatedBadgeUrl,
                        errorMessage: $errorMessage,
                        badgeController: badgeController,
                        showDescriptionInput: $showDescriptionInput,
                        userDescription: $userDescription,
                        acquiredBadge: $acquiredBadge,
                        onGenerateBadge: generateBadgeWithDescription
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
            .alert("result.badge_generated", isPresented: $showSuccessAlert) {
                Button("result.ok") {}
            } message: {
                Text(isFirstVisitor ? "result.first_visitor_message" : "result.badge_unlocked_message")
            }
            .task {
                await handleMissionCompletion()
            }
        }
    }

    private func handleMissionCompletion() async {
        do {
            isGeneratingBadge = true

            // Convert shelter.id (String) to UUID
            guard let shelterUUID = UUID(uuidString: shelter.id) else {
                errorMessage = "Invalid shelter ID format"
                isGeneratingBadge = false
                return
            }

            // Step 1: Check if badge exists for this shelter in shelter_badges table
            let existingBadge = try await badgeService.getBadgeForShelter(shelterId: shelterUUID)

            if let badge = existingBadge {
                // Badge exists in shelter_badges table
                // Convert to Badge UI model and display immediately
                acquiredBadge = createBadgeUIModel(from: badge, shelter: shelter)
                generatedBadgeUrl = badge.getImageUrl()

                // Add to user_shelter_badges table (if not already added)
                try? await badgeService.unlockBadge(badgeId: badge.id)

                isBadgeGenerated = true
                isGeneratingBadge = false
            } else {
                // No badge exists in shelter_badges table - user is first visitor
                isFirstVisitor = true
                showDescriptionInput = true
                isGeneratingBadge = false
            }

        } catch {
            errorMessage = error.localizedDescription
            isGeneratingBadge = false
        }
    }

    private func generateBadgeWithDescription() async {
        isGeneratingBadge = true
        showDescriptionInput = false

        do {
            // Generate badge using devtools method with user description
            await badgeController.generateBadge(
                locationName: shelter.name,
                locationDescription: userDescription.isEmpty ? "A notable shelter location" : userDescription,
                colorTheme: nil
            )

            if let badgeUrl = badgeController.generatedBadgeUrl {
                generatedBadgeUrl = badgeUrl

                // Convert shelter.id to UUID
                guard let shelterUUID = UUID(uuidString: shelter.id) else {
                    errorMessage = "Invalid shelter ID format"
                    isGeneratingBadge = false
                    return
                }

                // Step 1: Create shelter badge in shelter_badges table
                let createdBadge = try await badgeService.createShelterBadge(
                    badgeName: "First Visit: \(shelter.name)",
                    shelterId: shelterUUID,
                    firstUserId: await supabase.auth.session.user.id
                )

                // Step 2: Add to user_shelter_badges table
                try await badgeService.unlockBadge(badgeId: createdBadge.id)

                // Step 3: Create Badge UI model and display
                acquiredBadge = createBadgeUIModel(from: createdBadge, shelter: shelter, imageUrl: badgeUrl)

                isBadgeGenerated = true
                showSuccessAlert = true
            } else if let error = badgeController.errorMessage {
                errorMessage = error
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isGeneratingBadge = false
    }

    // Helper function to create Badge UI model
    private func createBadgeUIModel(from shelterBadge: ShelterBadge, shelter: Shelter, imageUrl: String? = nil) -> Badge {
        Badge(
            id: shelterBadge.id.uuidString,
            name: shelter.name,
            icon: "star.fill",
            color: .orange,
            isUnlocked: true,
            imageName: nil,
            imageUrl: imageUrl ?? shelterBadge.getImageUrl(),
            badgeNumber: shelter.commonId,
            address: shelter.address,
            municipality: shelter.municipality,
            isShelter: shelter.isShelter ?? false,
            isFlood: shelter.isFlood ?? false,
            isLandslide: shelter.isLandslide ?? false,
            isStormSurge: shelter.isStormSurge ?? false,
            isEarthquake: shelter.isEarthquake ?? false,
            isTsunami: shelter.isTsunami ?? false,
            isFire: shelter.isFire ?? false,
            isInlandFlood: shelter.isInlandFlood ?? false,
            isVolcano: shelter.isVolcano ?? false,
            latitude: shelter.latitude,
            longitude: shelter.longitude,
            firstUserName: "You"
        )
    }
}

// MARK: - Supporting Views

struct InteractiveBadgeView: View {
    let badge: Badge
    @State private var rotationX: Double = 0
    @State private var rotationY: Double = 0
    @State private var dragOffset = CGSize.zero
    @State private var isPressed = false
    @State private var showingDetail = false

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                // 背景の影（3D効果）
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.black.opacity(0.4),
                                Color.black.opacity(0.1),
                                Color.clear,
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 65
                        )
                    )
                    .frame(width: 130, height: 130)
                    .offset(x: 4, y: 4)
                    .blur(radius: 3)

                // メインのバッジ表示
                if let imageUrl = badge.imageUrl, !imageUrl.isEmpty {
                    // Use AsyncImage for remote URLs
                    AsyncImage(url: URL(string: imageUrl)) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(width: 100, height: 100)
                        case let .success(image):
                            ZStack {
                                // 画像用の背景円
                                Circle()
                                    .fill(
                                        RadialGradient(
                                            gradient: Gradient(colors: [
                                                badge.color.opacity(0.3),
                                                badge.color.opacity(0.1),
                                                Color.clear,
                                            ]),
                                            center: .center,
                                            startRadius: 0,
                                            endRadius: 60
                                        )
                                    )
                                    .frame(width: 120, height: 120)
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [
                                                        Color.white.opacity(0.6),
                                                        Color.white.opacity(0.2),
                                                        Color.clear,
                                                        Color.black.opacity(0.1),
                                                    ]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 2
                                            )
                                    )

                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                                    .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 3)
                            }
                        case .failure:
                            // Fallback to imageName if URL fails
                            if let imageName = badge.imageName, !imageName.isEmpty {
                                ZStack {
                                    // 画像用の背景円
                                    Circle()
                                        .fill(
                                            RadialGradient(
                                                gradient: Gradient(colors: [
                                                    badge.color.opacity(0.3),
                                                    badge.color.opacity(0.1),
                                                    Color.clear,
                                                ]),
                                                center: .center,
                                                startRadius: 0,
                                                endRadius: 60
                                            )
                                        )
                                        .frame(width: 120, height: 120)
                                        .overlay(
                                            Circle()
                                                .stroke(
                                                    LinearGradient(
                                                        gradient: Gradient(colors: [
                                                            Color.white.opacity(0.6),
                                                            Color.white.opacity(0.2),
                                                            Color.clear,
                                                            Color.black.opacity(0.1),
                                                        ]),
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    ),
                                                    lineWidth: 2
                                                )
                                        )

                                    Image(imageName)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                        .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 3)
                                }
                            } else {
                                fallbackBadgeCircle
                            }
                        @unknown default:
                            fallbackBadgeCircle
                        }
                    }
                } else if let imageName = badge.imageName, !imageName.isEmpty {
                    // Fallback to local image
                    ZStack {
                        // 画像用の背景円
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        badge.color.opacity(0.3),
                                        badge.color.opacity(0.1),
                                        Color.clear,
                                    ]),
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 60
                                )
                            )
                            .frame(width: 120, height: 120)
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.white.opacity(0.6),
                                                Color.white.opacity(0.2),
                                                Color.clear,
                                                Color.black.opacity(0.1),
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 2
                                    )
                            )

                        Image(imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 3)
                    }
                } else {
                    // No image available
                    fallbackBadgeCircle
                }

                // ハイライト効果
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.7),
                                Color.white.opacity(0.3),
                                Color.clear,
                            ]),
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: 40
                        )
                    )
                    .frame(width: 70, height: 70)
                    .offset(x: -18, y: -18)
                    .opacity(0.8)
            }
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .rotation3DEffect(
                .degrees(rotationX),
                axis: (x: 1, y: 0, z: 0)
            )
            .rotation3DEffect(
                .degrees(rotationY),
                axis: (x: 0, y: 1, z: 0)
            )
            .gesture(
                DragGesture(minimumDistance: 10)
                    .onChanged { value in
                        isPressed = true
                        dragOffset = value.translation

                        // 回転角度を制限（-45度から45度）、感度を上げる
                        let maxRotation: Double = 45
                        let sensitivity = 0.5
                        rotationY = min(max(Double(dragOffset.width) * sensitivity, -maxRotation), maxRotation)
                        rotationX = min(max(Double(-dragOffset.height) * sensitivity, -maxRotation), maxRotation)
                    }
                    .onEnded { _ in
                        isPressed = false
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            rotationX = 0
                            rotationY = 0
                            dragOffset = .zero
                        }
                    }
            )
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            .allowsHitTesting(true)
            .simultaneousGesture(
                TapGesture()
                    .onEnded { _ in
                        showingDetail = true
                    }
            )

            Text(badge.name)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(width: 140, height: 170)
        .sheet(isPresented: $showingDetail) {
            BadgeDetailView(badge: badge)
        }
    }

    // Fallback view when no image is available
    private var fallbackBadgeCircle: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            badge.color.opacity(0.9),
                            badge.color.opacity(0.7),
                            badge.color.opacity(0.5),
                            badge.color.opacity(0.3),
                        ]),
                        center: .topLeading,
                        startRadius: 10,
                        endRadius: 60
                    )
                )
                .frame(width: 120, height: 120)
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.8),
                                    Color.white.opacity(0.3),
                                    Color.clear,
                                    Color.black.opacity(0.2),
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                )

            Image(systemName: badge.icon)
                .font(.system(size: 30))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 2)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.orange)

            Text(value)
                .font(.title3)
                .fontWeight(.semibold)

            Text(LocalizedStringKey(title))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ShelterInfoCard: View {
    let shelter: Shelter

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "house.fill")
                    .foregroundColor(.orange)
                Text("result.shelter_reached")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(shelter.name)
                    .font(.title3)
                    .fontWeight(.semibold)

                Text(shelter.address)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if !shelter.supportedDisasterTypes.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("result.supported_disasters")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                            ForEach(shelter.supportedDisasterTypes, id: \.self) { disasterType in
                                HStack(spacing: 4) {
                                    Image(systemName: DisasterType(rawValue: disasterType)?.iconName ?? "questionmark")
                                        .font(.caption)
                                    Text(disasterType)
                                        .font(.caption2)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(.systemGray5))
                                .cornerRadius(8)
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct BadgeGenerationSection: View {
    let shelter: Shelter
    @Binding var isGeneratingBadge: Bool
    @Binding var isBadgeGenerated: Bool
    @Binding var isFirstVisitor: Bool
    @Binding var generatedBadgeUrl: String?
    @Binding var errorMessage: String?
    let badgeController: BadgeController
    @Binding var showDescriptionInput: Bool
    @Binding var userDescription: String
    @Binding var acquiredBadge: Badge?
    let onGenerateBadge: () async -> Void

    var body: some View {
        VStack(spacing: 16) {
            if showDescriptionInput {
                // Description input for first visitors
                VStack(spacing: 16) {
                    VStack(spacing: 8) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.orange)
                            .background(
                                Circle()
                                    .fill(.orange.opacity(0.1))
                                    .frame(width: 80, height: 80)
                            )

                        Text("result.first_visitor_title")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)

                        Text("result.first_visitor_description")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("result.description_prompt")
                            .font(.headline)
                            .foregroundColor(.primary)

                        TextField("result.description_placeholder", text: $userDescription, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(3 ... 6)
                    }

                    HStack(spacing: 12) {
                        Button("result.skip") {
                            userDescription = ""
                            Task {
                                await onGenerateBadge()
                            }
                        }
                        .foregroundColor(.secondary)

                        Button("result.generate_special_badge") {
                            Task {
                                await onGenerateBadge()
                            }
                        }
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(.orange)
                        .cornerRadius(10)
                    }
                }
                .padding(20)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            } else if let error = errorMessage {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.title2)
                        .foregroundColor(.red)

                    Text("result.badge_error")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text(error)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(20)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
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
