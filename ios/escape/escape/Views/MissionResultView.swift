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

    @State private var badgeViewModel = BadgeViewModel()
    @State private var viewModel: MissionResultViewModel
    // Track whether we are currently assembling share content to avoid double taps.
    @State private var isPreparingShare = false
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
