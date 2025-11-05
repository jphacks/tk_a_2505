//
//  MissionResultView.swift
//  escape
//
//  Created for mission result and badge management
//

import LinkPresentation
import SwiftUI
import UIKit // Needed to hand images to the system share sheet.

struct MissionResultView: View {
    let mission: Mission
    let shelter: Shelter
    let missionResult: MissionResult?

    @State private var badgeViewModel = BadgeViewModel()
    @State private var viewModel: MissionResultViewModel
    // Track whether we are currently assembling share content to avoid double taps.
    @State private var isPreparingShare = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.missionStateService) var missionStateService

    init(mission: Mission, shelter: Shelter, missionResult: MissionResult? = nil) {
        self.mission = mission
        self.shelter = shelter
        self.missionResult = missionResult

        // Create BadgeViewModel and pass it to MissionResultViewModel
        let badge = BadgeViewModel()
        _badgeViewModel = State(initialValue: badge)
        _viewModel = State(initialValue: MissionResultViewModel(badgeViewModel: badge, missionId: mission.id, initialMissionResult: missionResult))
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
                            AnimatedScoreBreakdownView(
                                missionResult: result,
                                totalPoints: viewModel.currentUserPoints,
                                nationalRank: viewModel.currentUserRank
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
            .safeAreaInset(edge: .bottom) {
                Group {
                    if viewModel.sharePayload != nil {
                        Button {
                            Task {
                                await prepareAndPresentShare()
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 20, weight: .semibold))
                                // Pull the button title from localization so it adapts per language.
                                Text(String(localized: "result.share_button", table: "Localizable"))
                                    .font(.system(size: 22, weight: .semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                        }
                        .buttonStyle(ShareProminentButtonStyle())
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                        .background(.ultraThinMaterial)
                    }
                }
            }
        }
    }
}

// MARK: - Animated Score Breakdown View

struct AnimatedScoreBreakdownView: View {
    let missionResult: MissionResult
    let totalPoints: Int64
    let nationalRank: Int?

    @State private var animateScore = false
    @State private var showBreakdown = false
    @State private var baseProgress: CGFloat = 0
    @State private var distanceProgress: CGFloat = 0
    @State private var bonusProgress: CGFloat = 0
    @State private var multiplierScale: CGFloat = 0
    @State private var finalScoreValue: Int = 0
    @State private var showConfetti = false
    @State private var showTotalPoints = false

    private let maxBarWidth: CGFloat = 280

    var body: some View {
        ZStack {
            VStack(spacing: 24) {
                // Final Score - Animated Counter
                VStack(spacing: 8) {
                    Text("result.score.final_score")
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
                        Text("result.score.breakdown")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        // Base Points
                        ScoreBarView(
                            icon: "star.fill",
                            title: String(localized: "result.score.base_points"),
                            points: Int(missionResult.basePoints ?? 0),
                            color: Color("brandMediumBlue"),
                            progress: baseProgress,
                            maxWidth: maxBarWidth
                        )

                        // Distance Points
                        ScoreBarView(
                            icon: "figure.walk",
                            title: String(localized: "result.score.distance_points"),
                            points: Int(missionResult.distancePoints ?? 0),
                            color: Color("brandOrange"),
                            progress: distanceProgress,
                            maxWidth: maxBarWidth
                        )

                        // Bonus Points
                        if let bonus = missionResult.bonusPoints, bonus > 0 {
                            ScoreBarView(
                                icon: "trophy.fill",
                                title: String(localized: "result.score.new_badge_bonus"),
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
                                Text("result.score.route_efficiency")
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

                        // Total Points and National Rank
                        if showTotalPoints {
                            Divider()
                                .padding(.vertical, 4)

                            VStack(spacing: 12) {
                                // Total Points Row
                                HStack(spacing: 8) {
                                    Image(systemName: "star.fill")
                                        .font(.title2)
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [Color("brandOrange"), Color("brandRed")],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )

                                    Text("result.your_total_points")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)

                                    Spacer()

                                    Text("\(totalPoints)")
                                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [Color("brandOrange"), Color("brandRed")],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                }

                                // National Rank Row
                                if let rank = nationalRank {
                                    HStack(spacing: 8) {
                                        Image(systemName: "trophy.fill")
                                            .font(.title2)
                                            .foregroundColor(Color("brandMediumBlue"))

                                        Text("result.national_rank")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)

                                        Spacer()

                                        Text(String(format: NSLocalizedString("result.rank_format", comment: ""), rank))
                                            .font(.system(size: 24, weight: .heavy, design: .rounded))
                                            .foregroundColor(Color("brandMediumBlue"))
                                    }
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color("brandOrange").opacity(0.08),
                                                Color("brandRed").opacity(0.08),
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                Color("brandOrange").opacity(0.3),
                                                Color("brandRed").opacity(0.3),
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1.5
                                    )
                            )
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
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

        // Show total points and rank after multiplier
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showTotalPoints = true
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

// MARK: - Share Functionality

private extension MissionResultView {
    // Gather share content first, then present the sheet only when everything is ready.
    func prepareAndPresentShare() async {
        guard !isPreparingShare else { return }
        guard let items = await buildShareItems(), !items.isEmpty else { return }

        await MainActor.run {
            presentShareSheet(with: items)
        }
    }

    // Build out the array of share items (message + badge artwork/snapshot).
    func buildShareItems() async -> [Any]? {
        guard let payload = viewModel.sharePayload else { return nil }

        await MainActor.run {
            isPreparingShare = true
        }
        await viewModel.loadShareImageData()
        defer {
            Task { @MainActor in
                isPreparingShare = false
            }
        }

        var items: [Any] = []
        print("[Share] message: \(payload.message)")

        let badgeImage: UIImage? = {
            if let data = viewModel.shareImageData,
               let image = UIImage(data: data)
            {
                print("[Share] Loaded badge image data (\(data.count) bytes)")
                return image
            }
            print("[Share] No remote badge image available; will use snapshot fallback")
            return nil
        }()

        var shareImage = badgeImage
        if shareImage == nil {
            shareImage = await MainActor.run { captureShareSnapshot() }
        }

        if shareImage == nil,
           let snapshotData = viewModel.shareSnapshotData,
           let cachedSnapshot = UIImage(data: snapshotData)
        {
            shareImage = cachedSnapshot
        }

        let fallbackIcon = UIImage(named: "AppIcon") ?? UIImage(systemName: "square.and.arrow.up")
        let previewImage = shareImage ?? fallbackIcon

        let itemSource = BadgeShareActivityItemSource(
            message: payload.message,
            previewImage: previewImage,
            icon: fallbackIcon
        )
        items.append(itemSource)

        if let image = shareImage {
            print("[Share] Prepared share image with size: \(image.size)")
            items.append(image)
            await MainActor.run {
                viewModel.shareSnapshotData = image.pngData()
            }
        } else if let previewImage,
                  let data = previewImage.pngData()
        {
            await MainActor.run {
                viewModel.shareSnapshotData = data
            }
        }

        return items
    }

    // Present the UIKit activity controller with the fully prepared items.
    func presentShareSheet(with items: [Any]) {
        guard let controller = UIApplication.shared.firstKeyWindow?.rootViewController?.topMostViewController(),
              !items.isEmpty
        else {
            return
        }

        let activityController = UIActivityViewController(activityItems: items, applicationActivities: nil)
        if let popover = activityController.popoverPresentationController {
            // Anchor the popover to the current view on iPad to avoid crashes.
            popover.sourceView = controller.view
            popover.sourceRect = CGRect(
                x: controller.view.bounds.midX,
                y: controller.view.bounds.midY,
                width: 0,
                height: 0
            )
        }
        controller.present(activityController, animated: true)
    }

    // Render the key mission result details into a static image for richer sharing.
    func captureShareSnapshot() -> UIImage? {
        guard let badge = viewModel.acquiredBadge else { return nil }

        let renderer = ImageRenderer(
            content: MissionResultShareSnapshot(
                mission: mission,
                shelter: shelter,
                badge: badge,
                missionResult: viewModel.missionResult,
                badgeImage: viewModel.shareImageData.flatMap { UIImage(data: $0) }
            )
        )
        renderer.scale = UIScreen.main.scale
        return renderer.uiImage
    }
}

// Compact snapshot that mirrors the key information shown on the mission result screen.
private struct MissionResultShareSnapshot: View {
    let mission: Mission
    let shelter: Shelter
    let badge: Badge
    let missionResult: MissionResult?
    let badgeImage: UIImage?

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                if let badgeImage {
                    Image(uiImage: badgeImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 140, height: 140)
                        .clipShape(Circle())
                        .shadow(radius: 8)
                } else {
                    Image(systemName: badge.icon)
                        .font(.system(size: 60))
                        .foregroundColor(badge.color)
                        .frame(width: 140, height: 140)
                        .background(badge.color.opacity(0.15))
                        .clipShape(Circle())
                }

                Text(String(localized: "result.mission_completed"))
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text(String(localized: "result.congratulations"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            HStack {
                StatCard(
                    title: "result.steps",
                    value: missionResult?.formattedSteps ?? "N/A",
                    icon: "figure.walk"
                )

                StatCard(
                    title: "result.distance",
                    value: missionResult?.formattedDistance ?? "N/A",
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

            ShelterInfoCard(shelter: shelter)
        }
        .padding(24)
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 6)
    }
}

// Custom item source so we can supply share metadata (icon + preview image) while delivering the message text.
private final class BadgeShareActivityItemSource: NSObject, UIActivityItemSource {
    private let message: String
    private let previewImage: UIImage?
    private let icon: UIImage?

    init(message: String, previewImage: UIImage?, icon: UIImage?) {
        self.message = message
        self.previewImage = previewImage
        self.icon = icon
    }

    func activityViewControllerPlaceholderItem(_: UIActivityViewController) -> Any {
        message
    }

    func activityViewController(_: UIActivityViewController, itemForActivityType _: UIActivity.ActivityType?) -> Any? {
        message
    }

    func activityViewControllerLinkMetadata(_: UIActivityViewController) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        metadata.title = message

        if let previewImage {
            metadata.imageProvider = NSItemProvider(object: previewImage)
        }

        if let icon {
            metadata.iconProvider = NSItemProvider(object: icon)
        }

        return metadata
    }
}

// Custom button style keeps the brand color when pressed instead of flashing iOS blue.
private struct ShareProminentButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Color.white)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color("brandOrange"))
                    .opacity(configuration.isPressed ? 0.85 : 1.0)
            )
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// Locate the top-most view controller so we can present UIKit sheets from SwiftUI.
private extension UIApplication {
    var firstKeyWindow: UIWindow? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
}

// Walk through container controllers (navigation/tab) to find the visible controller.
private extension UIViewController {
    func topMostViewController() -> UIViewController {
        if let presented = presentedViewController {
            return presented.topMostViewController()
        }
        if let navigation = self as? UINavigationController,
           let visible = navigation.visibleViewController
        {
            return visible.topMostViewController()
        }
        if let tab = self as? UITabBarController,
           let selected = tab.selectedViewController
        {
            return selected.topMostViewController()
        }
        return self
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
