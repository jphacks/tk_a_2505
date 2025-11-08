//
//  HapticFeedback.swift
//  escape
//
//  Created for haptic feedback implementation
//

import UIKit

/// Centralized haptic feedback manager for consistent tactile responses throughout the app
class HapticFeedback {
    /// Shared singleton instance
    static let shared = HapticFeedback()

    // Pre-initialized feedback generators for minimal latency
    private let lightImpactGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpactGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpactGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let selectionGenerator = UISelectionFeedbackGenerator()
    private let notificationGenerator = UINotificationFeedbackGenerator()

    private init() {
        // Prepare generators on initialization for better performance
        lightImpactGenerator.prepare()
        mediumImpactGenerator.prepare()
        heavyImpactGenerator.prepare()
        selectionGenerator.prepare()
        notificationGenerator.prepare()
    }

    // MARK: - Impact Feedback

    /// Triggers light impact haptic (for subtle interactions like taps)
    func lightImpact() {
        lightImpactGenerator.impactOccurred()
        lightImpactGenerator.prepare() // Prepare for next use
    }

    /// Triggers medium impact haptic (for standard button presses)
    func mediumImpact() {
        mediumImpactGenerator.impactOccurred()
        mediumImpactGenerator.prepare()
    }

    /// Triggers heavy impact haptic (for significant actions)
    func heavyImpact() {
        heavyImpactGenerator.impactOccurred()
        heavyImpactGenerator.prepare()
    }

    // MARK: - Selection Feedback

    /// Triggers selection changed haptic (for picker/segmented control changes)
    func selection() {
        selectionGenerator.selectionChanged()
        selectionGenerator.prepare()
    }

    // MARK: - Notification Feedback

    /// Triggers success notification haptic (for successful task completion)
    func success() {
        notificationGenerator.notificationOccurred(.success)
        notificationGenerator.prepare()
    }

    /// Triggers warning notification haptic (for warnings or destructive actions)
    func warning() {
        notificationGenerator.notificationOccurred(.warning)
        notificationGenerator.prepare()
    }

    /// Triggers error notification haptic (for errors or failures)
    func error() {
        notificationGenerator.notificationOccurred(.error)
        notificationGenerator.prepare()
    }
}
