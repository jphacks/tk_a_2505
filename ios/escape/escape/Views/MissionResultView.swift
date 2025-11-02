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
    let missionResult: MissionResult?

    @State private var badgeViewModel = BadgeViewModel()
    @State private var viewModel: MissionResultViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.missionStateService) var missionStateService

    init(mission: Mission, shelter: Shelter, missionResult: MissionResult? = nil) {
        self.mission = mission
        self.shelter = shelter
        self.missionResult = missionResult

        // Create BadgeViewModel and pass it to MissionResultViewModel
        let badge = BadgeViewModel()
        _badgeViewModel = State(initialValue: badge)
        _viewModel = State(initialValue: MissionResultViewModel(badgeViewModel: badge, initialMissionResult: missionResult))
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
                                value: viewModel.missionResult?.formattedSteps ?? "N/A",
                                icon: "figure.walk"
                            )

                            StatCard(
                                title: "result.distance",
                                value: viewModel.missionResult?.formattedDistance ?? "N/A",
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

                        // Animated Score Display
                        if let result = viewModel.missionResult {
                            AnimatedScoreBreakdownView(missionResult: result)
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
                        // Reset mission state when closing result view
                        missionStateService.resetMission()
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

// MARK: - Animated Score Breakdown View

struct AnimatedScoreBreakdownView: View {
    let missionResult: MissionResult

    @State private var animateScore = false
    @State private var showBreakdown = false
    @State private var baseProgress: CGFloat = 0
    @State private var distanceProgress: CGFloat = 0
    @State private var bonusProgress: CGFloat = 0
    @State private var multiplierScale: CGFloat = 0
    @State private var finalScoreValue: Int = 0
    @State private var showConfetti = false

    private let maxBarWidth: CGFloat = 280

    var body: some View {
        ZStack {
            VStack(spacing: 24) {
                // Final Score - Animated Counter
                VStack(spacing: 8) {
                    Text("🏆 Final Score")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("\(finalScoreValue)")
                        .font(.system(size: 64, weight: .heavy, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color("brandOrange"), Color("brandRed")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .scaleEffect(animateScore ? 1.0 : 0.5)
                        .opacity(animateScore ? 1.0 : 0.0)
                }
                .padding(.vertical, 12)

                Divider()

                // Score Breakdown
                if showBreakdown {
                    VStack(spacing: 20) {
                        Text("Score Breakdown")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        // Base Points
                        ScoreBarView(
                            icon: "star.fill",
                            title: "Base Points",
                            points: Int(missionResult.basePoints ?? 0),
                            color: Color("brandMediumBlue"),
                            progress: baseProgress,
                            maxWidth: maxBarWidth
                        )

                        // Distance Points
                        ScoreBarView(
                            icon: "figure.walk",
                            title: "Distance Points",
                            points: Int(missionResult.distancePoints ?? 0),
                            color: Color("brandOrange"),
                            progress: distanceProgress,
                            maxWidth: maxBarWidth
                        )

                        // Bonus Points
                        if let bonus = missionResult.bonusPoints, bonus > 0 {
                            ScoreBarView(
                                icon: "trophy.fill",
                                title: "New Badge Bonus",
                                points: Int(bonus),
                                color: Color.yellow,
                                progress: bonusProgress,
                                maxWidth: maxBarWidth
                            )
                        }

                        Divider()
                            .padding(.vertical, 4)

                        // Route Efficiency Multiplier
                        HStack {
                            Image(systemName: "arrow.triangle.branch")
                                .foregroundColor(Color("brandPeach"))
                                .font(.title3)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Route Efficiency")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)

                                Text(missionResult.routeEfficiencyPercentage)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Text("×\(String(format: "%.2f", missionResult.routeEfficiencyMultiplier ?? 1.0))")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(Color("brandRed"))
                                .scaleEffect(multiplierScale)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color("brandPeach").opacity(0.1))
                        )
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [Color("brandOrange").opacity(0.5), Color("brandRed").opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            )

            // Confetti Effect
            if showConfetti {
                ConfettiView()
            }
        }
        .onAppear {
            startAnimations()
        }
    }

    private func startAnimations() {
        let finalScore = Int(missionResult.finalPoints ?? 0)
        let basePoints = Int(missionResult.basePoints ?? 0)
        let distancePoints = Int(missionResult.distancePoints ?? 0)
        let bonusPoints = Int(missionResult.bonusPoints ?? 0)
        let totalBeforeMultiplier = basePoints + distancePoints + bonusPoints

        // Animate final score counter
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
            animateScore = true
        }

        // Count up animation
        let steps = 30
        let stepDuration = 1.5 / Double(steps)

        for i in 0 ... steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(i)) {
                finalScoreValue = Int(Double(finalScore) * (Double(i) / Double(steps)))
            }
        }

        // Show breakdown after score animates
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showBreakdown = true
            }
        }

        // Animate bars sequentially
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.7)) {
                baseProgress = totalBeforeMultiplier > 0
                    ? CGFloat(basePoints) / CGFloat(totalBeforeMultiplier)
                    : 0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.7)) {
                distanceProgress = totalBeforeMultiplier > 0
                    ? CGFloat(distancePoints) / CGFloat(totalBeforeMultiplier)
                    : 0
            }
        }

        if bonusPoints > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                withAnimation(.spring(response: 0.7, dampingFraction: 0.7)) {
                    bonusProgress = totalBeforeMultiplier > 0
                        ? CGFloat(bonusPoints) / CGFloat(totalBeforeMultiplier)
                        : 0
                }
            }
        }

        // Animate multiplier
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.1) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                multiplierScale = 1.2
            }

            withAnimation(.spring(response: 0.3, dampingFraction: 0.7).delay(0.1)) {
                multiplierScale = 1.0
            }
        }

        // Show confetti celebration
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showConfetti = true
        }

        // Hide confetti after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            withAnimation {
                showConfetti = false
            }
        }
    }
}

// MARK: - Score Bar View

struct ScoreBarView: View {
    let icon: String
    let title: String
    let points: Int
    let color: Color
    let progress: CGFloat
    let maxWidth: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                Text("+\(points)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }

            // Progress Bar
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 12)

                // Foreground Progress
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: maxWidth * progress, height: 12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
            }
            .frame(maxWidth: maxWidth)
        }
    }
}

// MARK: - Confetti View

struct ConfettiView: View {
    @State private var confettiPieces: [ConfettiPiece] = []

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(confettiPieces) { piece in
                    ConfettiPieceView(piece: piece)
                }
            }
            .onAppear {
                generateConfetti(in: geometry.size)
            }
        }
        .allowsHitTesting(false)
    }

    private func generateConfetti(in size: CGSize) {
        let colors: [Color] = [
            Color("brandOrange"),
            Color("brandRed"),
            Color("brandMediumBlue"),
            Color("brandPeach"),
            Color.yellow,
            Color.green,
        ]

        for i in 0 ..< 50 {
            let piece = ConfettiPiece(
                id: UUID(),
                x: CGFloat.random(in: 0 ... size.width),
                y: -20,
                color: colors.randomElement()!,
                size: CGFloat.random(in: 6 ... 12),
                rotation: Double.random(in: 0 ... (2 * .pi)),
                velocity: CGFloat.random(in: 100 ... 200),
                delay: Double(i) * 0.02
            )
            confettiPieces.append(piece)
        }
    }
}

struct ConfettiPiece: Identifiable {
    let id: UUID
    let x: CGFloat
    let y: CGFloat
    let color: Color
    let size: CGFloat
    let rotation: Double
    let velocity: CGFloat
    let delay: Double
}

struct ConfettiPieceView: View {
    let piece: ConfettiPiece
    @State private var yOffset: CGFloat = 0
    @State private var rotation: Double = 0
    @State private var opacity: Double = 1

    var body: some View {
        Circle()
            .fill(piece.color)
            .frame(width: piece.size, height: piece.size)
            .rotationEffect(.degrees(rotation))
            .offset(x: piece.x, y: piece.y + yOffset)
            .opacity(opacity)
            .onAppear {
                withAnimation(
                    .linear(duration: 3.0)
                        .delay(piece.delay)
                ) {
                    yOffset = piece.velocity * 4
                }

                withAnimation(
                    .linear(duration: 3.0)
                        .repeatCount(20, autoreverses: false)
                        .delay(piece.delay)
                ) {
                    rotation = piece.rotation * 360
                }

                withAnimation(
                    .easeIn(duration: 2.5)
                        .delay(piece.delay + 0.5)
                ) {
                    opacity = 0
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
            status: .completed,
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
