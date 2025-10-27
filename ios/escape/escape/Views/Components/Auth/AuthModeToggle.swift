//
//  AuthModeToggle.swift
//  escape
//
//  Created by Thanasan Kumdee on 27/10/2568 BE.
//

import SwiftUI

struct AuthModeToggle: View {
    @Binding var usePasswordAuth: Bool
    let onPasswordAuthChange: (Bool) -> Void

    var body: some View {
        Picker("", selection: $usePasswordAuth) {
            Text("auth.magic_link").tag(false)
            Text("auth.password").tag(true)
        }
        .pickerStyle(.segmented)
        .onChange(of: usePasswordAuth) { _, newValue in
            onPasswordAuthChange(newValue)
        }
    }
}
