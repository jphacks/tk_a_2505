//
//  UIImage+AverageColor.swift
//  escape
//
//  Created by AI Assistant on 2025/11/07.
//

import SwiftUI
import UIKit

extension UIImage {
    /// Gets the average color of the image
    var averageColor: UIColor? {
        guard let inputImage = CIImage(image: self) else { return nil }

        let extentVector = CIVector(
            x: inputImage.extent.origin.x,
            y: inputImage.extent.origin.y,
            z: inputImage.extent.size.width,
            w: inputImage.extent.size.height
        )

        guard
            let filter = CIFilter(
                name: "CIAreaAverage",
                parameters: [kCIInputImageKey: inputImage, kCIInputExtentKey: extentVector]
            )
        else { return nil }
        guard let outputImage = filter.outputImage else { return nil }

        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [.workingColorSpace: kCFNull as Any])
        context.render(
            outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
            format: .RGBA8, colorSpace: nil
        )

        return UIColor(
            red: CGFloat(bitmap[0]) / 255.0,
            green: CGFloat(bitmap[1]) / 255.0,
            blue: CGFloat(bitmap[2]) / 255.0,
            alpha: CGFloat(bitmap[3]) / 255.0
        )
    }

    /// Gets the average color as SwiftUI Color
    var averageSwiftUIColor: Color {
        guard let uiColor = averageColor else {
            return Color(.systemBackground)
        }
        return Color(uiColor)
    }

    /// Gets a more vibrant version of the average color suitable for UI backgrounds
    var vibrantAverageColor: Color {
        guard let averageColor = averageColor else {
            return Color(.systemBackground)
        }

        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0

        averageColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

        // Boost saturation and control brightness for better visibility
        let enhancedSaturation = min(saturation * 1.8, 1.0) // Increased saturation boost
        let controlledBrightness = max(min(brightness * 1.2, 0.8), 0.4) // Better brightness range

        return Color(
            UIColor(
                hue: hue, saturation: enhancedSaturation, brightness: controlledBrightness, alpha: alpha
            ))
    }
}

extension Color {
    /// Creates a softer version of the color suitable for backgrounds
    func asBackgroundColor(opacity: Double = 0.15) -> Color {
        return self.opacity(opacity)
    }

    /// Creates a gradient-friendly lighter version of the color
    var lightened: Color {
        return opacity(0.3)
    }
}
