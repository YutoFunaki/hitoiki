//
//  ContentView.swift
//  hitoiki
//
//  Created by 船木勇斗 on 2024/07/21.
//

import SwiftUI
import FirebaseAuth  // FirebaseAuth をインポートする

struct ContentView: View {
    @State private var isLoggedIn = false
    @State private var isLoading = true
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .onAppear(perform: checkAuthentication)
            } else {
                if isLoggedIn {
                    MainView()
                } else {
                    LoginView(isLoggedIn: $isLoggedIn)
                }
            }
        }
    }
    
    private func checkAuthentication() {
        Auth.auth().addStateDidChangeListener { auth, user in
            if let user = user {
                // ユーザーがログインしている場合
                self.isLoggedIn = true
            } else {
                // ユーザーがログインしていない場合
                self.isLoggedIn = false
            }
            self.isLoading = false
        }
    }
}

#Preview {
    ContentView()
}
