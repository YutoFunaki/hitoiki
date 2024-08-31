//
//  ArticleContentView.swift
//  hitoiki
//
//  Created by 船木勇斗 on 2024/07/28.
//

import SwiftUI
import Firebase
import AVKit

struct ArticleContentView: View {
    var article: NewsItem
    @State private var isLiked = false // いいね状態を管理する
    @State private var likeCount: Int = 0 // 現在のいいね数
    @State private var accessCount: Int = 0 // 現在の閲覧数
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(article.title)
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .center)
                
                HStack {
                    Text("公開日: \(article.publicDate, formatter: DateFormatter.japaneseShort)")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer()
                    Text("閲覧数: \(accessCount)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Divider()
                
                Text(article.content)
                    .font(.body)
                
                // メディア表示部分（画像と動画）
                mediaSection
                
                // いいねボタン
                Button(action: {
                    likeArticle()
                }) {
                    HStack {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .foregroundColor(isLiked ? .red : .gray)
                            .scaleEffect(isLiked ? 1.2 : 1.0)
                            .animation(.spring(), value: isLiked)
                        Text("いいね (\(likeCount))")
                            .font(.subheadline)
                            .foregroundColor(isLiked ? .red : .gray)
                    }
                }
                .padding()
            }
            .padding()
            .onAppear {
                fetchArticleData()
                increaseAccessCount()
            }
        }
        .navigationTitle("記事の詳細")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // メディア表示用のセクション
    @ViewBuilder
    var mediaSection: some View {
        ForEach(article.imageUrl, id: \.self) { url in
            if let mediaUrl = URL(string: url) {
                if mediaUrl.pathExtension == "mp4" {
                    // 動画の場合
                    VideoPlayer(player: AVPlayer(url: mediaUrl))
                        .frame(height: 300)
                        .cornerRadius(8)
                } else {
                    // 画像の場合
                    AsyncImage(url: mediaUrl) { image in
                        image
                            .resizable()
                            .scaledToFit()
                    } placeholder: {
                        Color.gray
                    }
                    .frame(maxWidth: .infinity)
                    .cornerRadius(8)
                }
            }
        }
    }
    
    // いいね数と閲覧数を `history_rating` から取得する
    func fetchArticleData() {
        guard let articleID = article.id else { return }
        let db = Firestore.firestore()
        
        db.collection("history_rating").document(articleID).getDocument { (document, error) in
            if let document = document, document.exists {
                likeCount = document.data()?["like_count"] as? Int ?? 0
                accessCount = document.data()?["access_count"] as? Int ?? 0
            }
        }
    }
    
    // いいね数を1追加し、`user_likes` にもデータを追加する
    func likeArticle() {
        guard let articleID = article.id, let userID = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let historyRatingRef = db.collection("history_rating").document(articleID)
        let dailyRatingRef = db.collection("daily_rating").document(articleID)
        let userLikesRef = db.collection("user_likes").document("\(articleID)_\(userID)")
        
        isLiked = true
        
        // `history_rating` をまず更新してから `daily_rating` を更新
        historyRatingRef.updateData([
            "like_count": FieldValue.increment(Int64(1))
        ]) { error in
            if let error = error {
                print("Error updating history like count: \(error)")
                return
            }
            
            // `history_rating` の更新が成功した後で `daily_rating` を更新
            dailyRatingRef.updateData([
                "like_count": FieldValue.increment(Int64(1))
            ]) { error in
                if let error = error {
                    print("Error updating daily like count: \(error)")
                }
                likeCount += 1
            }
        }
        
        // `user_likes` コレクションにデータを追加または更新
        userLikesRef.getDocument { (document, error) in
            if let document = document, document.exists {
                // すでにいいねしている場合は `count` を増やす
                userLikesRef.updateData([
                    "count": FieldValue.increment(Int64(1))
                ]) { error in
                    if let error = error {
                        print("Error updating user like count: \(error)")
                    }
                }
            } else {
                // 初めていいねする場合は新規ドキュメントを作成
                userLikesRef.setData([
                    "article_id": articleID,
                    "uid": userID,
                    "count": 1
                ]) { error in
                    if let error = error {
                        print("Error adding user like data: \(error)")
                    }
                }
            }
        }
    }
    
    // 閲覧数を1追加する
    func increaseAccessCount() {
        guard let articleID = article.id else { return }
        let db = Firestore.firestore()
        let historyRatingRef = db.collection("history_rating").document(articleID)
        let dailyRatingRef = db.collection("daily_rating").document(articleID)
        
        // `history_rating` をまず更新してから `daily_rating` を更新
        historyRatingRef.updateData([
            "access_count": FieldValue.increment(Int64(1))
        ]) { error in
            if let error = error {
                print("Error updating history access count: \(error)")
                return
            }
            
            // `history_rating` の更新が成功した後で `daily_rating` を更新
            dailyRatingRef.updateData([
                "access_count": FieldValue.increment(Int64(1))
            ]) { error in
                if let error = error {
                    print("Error updating daily access count: \(error)")
                }
                accessCount += 1
            }
        }
    }
}
