//
//  SecondView.swift
//  hitoiki
//
//  Created by 船木勇斗 on 2024/07/21.
//

import SwiftUI

struct SecondView: View {
    var authenticationManager = AuthenticationManager()
    var body: some View {
        Button("ログアウト") {
            authenticationManager.signOut()
        }
    }
}


#Preview {
    SecondView()
}
