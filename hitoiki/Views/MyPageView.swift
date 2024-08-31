//
//  MyPageView.swift
//  hitoiki
//
//  Created by 船木勇斗 on 2024/07/28.
//

import SwiftUI
import FirebaseAuth

struct MyPageView: View {
    @State private var isDeveloper = false
    
    var body: some View {
        List {
            NavigationLink(destination: ArticleRequestView()) {
                Text("記事投稿申請")
            }
            
            // 開発者専用のリスト項目
            if isDeveloper {
                NavigationLink(destination: DeveloperArticleManagementView()) {
                    Text("記事管理")
                }
            }
        }
        .listStyle(.inset)
        .navigationTitle("マイページ")
        .onAppear {
            checkIfDeveloper()
        }
    }
    
    private func checkIfDeveloper() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        if userID == "el2lxKLiMkby6rzuBiqcRG6iTZ23" {
            isDeveloper = true
        }
    }
}

#Preview {
    MyPageView()
}
