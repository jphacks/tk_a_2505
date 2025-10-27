//
//  ButtonStyle.swift
//  escape
//
//  Created by Thanasan Kumdee on 27/10/2568 BE.
//

import SwiftUI

// MARK: - Primary Button Style

enum PrimaryButtonStyle {
    static let verticalPadding: CGFloat = 14
    static let cornerRadius: CGFloat = 8
    static let fontSize: CGFloat = 16
    static let disabledColor = Color(.systemGray4)
}

// MARK: - Reusable Primary Button Component

struct PrimaryButton: View {
    let title: LocalizedStringKey
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text(title)
                        .font(.system(size: PrimaryButtonStyle.fontSize, weight: .medium))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, PrimaryButtonStyle.verticalPadding)
            .background(isDisabled ? PrimaryButtonStyle.disabledColor : Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(PrimaryButtonStyle.cornerRadius)
        }
        .disabled(isDisabled)
    }
}
