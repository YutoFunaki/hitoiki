//
//  ContentView.swift
//  hitoiki
//
//  Created by 船木勇斗 on 2024/07/21.
//

import SwiftUI

struct ContentView: View {
    @State private var isLoggedIn = false
    var authenticationManager = AuthenticationManager()
    var body: some View {
        VStack {
            if authenticationManager.isSignIn == false {
                // ログインしていないとき
                LoginView(isLoggedIn: $isLoggedIn)
            } else {
                // ログインしているとき
                MainView()
            }
            Spacer()
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
