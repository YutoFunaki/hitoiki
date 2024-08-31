//
//  ArticleEditView.swift
//  hitoiki
//
//  Created by 船木勇斗 on 2024/08/31.
//

import SwiftUI
import Firebase
import AVKit

struct ArticleEditView: View {
    @Binding var article: NewsItem
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var isSubmitting: Bool = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                TextField("記事タイトル", text: $title)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                TextEditor(text: $content)
                    .frame(height: 200)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray, lineWidth: 1))
                
                // 画像と動画の表示
                ForEach(article.imageUrl, id: \.self) { url in
                    if isVideoURL(url) {
                        VideoPlayer(player: AVPlayer(url: URL(string: url)!))
                            .frame(height: 200)
                            .cornerRadius(8)
                    } else {
                        AsyncImage(url: URL(string: url)) { image in
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(height: 200)
                                .cornerRadius(8)
                        } placeholder: {
                            ProgressView()
                        }
                    }
                }
                
                HStack {
                    Button(action: {
                        updateArticle(isPublished: true)
                    }) {
                        Text("公開する")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    
                    Button(action: {
                        updateArticle(isPublished: false)
                    }) {
                        Text("投稿を許可しない")
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            }
            .padding()
            .onAppear {
                title = article.title
                content = article.content
            }
        }
        .navigationTitle("記事編集")
        .navigationBarTitleDisplayMode(.inline)
        .overlay(
            isSubmitting ? ProgressView("更新中...")
                .background(Color.white)
                .cornerRadius(8)
                .shadow(radius: 10)
                .padding()
                .background(Color.black.opacity(0.5))
                .edgesIgnoringSafeArea(.all) : nil
        )
    }
    
    // メディアが動画かどうかを判定する関数
    func isVideoURL(_ url: String) -> Bool {
        let videoExtensions = ["mp4", "mov", "avi"]
        return videoExtensions.contains { url.lowercased().hasSuffix($0) }
    }
    
    func updateArticle(isPublished: Bool) {
        isSubmitting = true
        
        guard let articleID = article.id else { return }
        
        let db = Firestore.firestore()
        var updateData: [String: Any] = [
            "title": title,
            "content": content,
            "public_status": isPublished,
            "deleted_at": NSNull()
        ]
        
        if isPublished {
            updateData["public_date"] = Timestamp(date: Date())
        }
        
        db.collection("articles").document(articleID).updateData(updateData) { error in
            isSubmitting = false
            if let error = error {
                print("Error updating article: \(error)")
            } else {
                sendNotificationToUser(userID: article.createdUserID, isPublished: isPublished)
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
    
    func sendNotificationToUser(userID: String, isPublished: Bool) {
        let db = Firestore.firestore()
        
        let notificationMessage = isPublished ? "あなたの記事が公開されました。" : "あなたの記事の投稿が許可されませんでした。"
        let notificationData: [String: Any] = [
            "user_id": userID,
            "message": notificationMessage,
            "timestamp": Timestamp(date: Date())
        ]
        
        db.collection("notifications").addDocument(data: notificationData) { error in
            if let error = error {
                print("Error sending notification: \(error)")
            }
        }
    }
}
