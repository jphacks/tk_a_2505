//
//  AuthToggleLink.swift
//  escape
//
//  Created by Thanasan Kumdee on 27/10/2568 BE.
//
import SwiftUI

struct AuthToggleLink: View {
    let isSignUp: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(isSignUp ? "auth.already_have_account" : "auth.need_account")
                .font(.system(size: 13))
                .foregroundColor(.accentColor.opacity(0.9))
        }
        .padding(.top, 2)
    }
}
