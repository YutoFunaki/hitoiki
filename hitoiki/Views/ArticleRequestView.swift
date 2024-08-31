//
//  ArticleRequestView.swift
//  hitoiki
//
//  Created by 船木勇斗 on 2024/08/25.
//

import SwiftUI
import Firebase
import PhotosUI
import FirebaseStorage

struct ArticleRequestView: View {
    @State private var title: String = ""
    @State private var selectedCategories: Set<String> = []
    @State private var content: String = ""
    @State private var mediaItems: [UIImage?] = [nil, nil, nil, nil]
    @State private var videoURLs: [URL?] = [nil, nil, nil, nil]
    @State private var isPublishingAllowed: Bool = false
    @State private var isImagePickerPresented = false
    @State private var isSubmitting = false
    @State private var showModal = false
    @State private var showMainView = false
    @State private var showArticleRequestView = false
    
    let categories: [String: Int] = ["猫": 1, "犬": 2, "小動物": 3, "赤ちゃん": 4, "エンタメ": 5]
    
    var body: some View {
        ScrollView {
            ZStack {
                VStack(alignment: .leading, spacing: 20) {
                    TextField("記事タイトル (必須)", text: $title)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.bottom)
                    
                    Text("カテゴリ (複数選択可)")
                        .font(.headline)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(categories.keys.sorted(), id: \.self) { category in
                                Button(action: {
                                    if selectedCategories.contains(category) {
                                        selectedCategories.remove(category)
                                    } else {
                                        selectedCategories.insert(category)
                                    }
                                }) {
                                    Text(category)
                                        .padding(.vertical, -10) // 縦方向のパディングを小さく
                                        .padding(.horizontal, 0) // 横方向のパディングも小さく設定
                                        .padding()
                                        .background(selectedCategories.contains(category) ? Color.blue : Color.gray)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom)
                    
                    Text("記事の内容")
                        .font(.headline)
                    TextEditor(text: $content)
                        .frame(height: 200)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                        .padding(.bottom)
                        .overlay(alignment: .topLeading) {
                            if content.isEmpty {
                                Text("ここに内容を入力してください。")
                                    .foregroundColor(Color(uiColor: .placeholderText))
                                    .padding(6)
                            }
                        }
                    
                    Button("画像/動画を選択") {
                        isImagePickerPresented = true
                    }
                    .padding()
                    
                    // 選択されたメディアのプレビュー
                    ForEach(0..<4, id: \.self) { index in
                        if let media = mediaItems[index] {
                            Image(uiImage: media)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .cornerRadius(8)
                        } else if let videoURL = videoURLs[index] {
                            Text("動画が選択されました")
                                .frame(width: 100, height: 100)
                                .background(Color.gray.opacity(0.3))
                                .cornerRadius(8)
                        }
                    }
                    
                    Toggle(isOn: $isPublishingAllowed) {
                        Text("掲載許可と同意 (必須)")
                    }
                    .padding(.bottom)
                    
                    // 送信とキャンセルボタンの追加
                    VStack {
                        
                        Button("送信") {
                            submitArticle()
                        }
                        .disabled(!isPublishingAllowed || title.isEmpty || content.isEmpty || selectedCategories.isEmpty)
                        .padding()
                        .background(isPublishingAllowed && !title.isEmpty && !content.isEmpty && !selectedCategories.isEmpty ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        
                        Button("キャンセル") {
                            showMainView = true
                        }
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding()
                
                
                // 送信中のローディングインジケーターを中央に表示
                if isSubmitting {
                    VStack {
                        Spacer() // 上部スペース
                        ProgressView("送信中...")
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(radius: 10)
                        Spacer() // 下部スペース
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.4).edgesIgnoringSafeArea(.all))
                }
            }
        }
        .navigationTitle("記事投稿申請")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isImagePickerPresented) {
            PHPickerViewControllerView(mediaItems: $mediaItems, videoURLs: $videoURLs)
        }
        .fullScreenCover(isPresented: $showMainView) {
            MainView()
        }
        .fullScreenCover(isPresented: $showArticleRequestView) {
            ArticleRequestView()
        }
        .alert(isPresented: $showModal) {
            Alert(
                title: Text("送信完了"),
                message: Text("投稿が完了しました。続けて投稿しますか？"),
                primaryButton: .default(Text("続けて投稿")) {
                    showArticleRequestView = true
                },
                secondaryButton: .cancel(Text("TOPに戻る")) {
                    showMainView = true
                }
            )
        }
    }
    
    private func submitArticle() {
        isSubmitting = true
        
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        let document = db.collection("articles").document()
        
        let selectedCategoryIDs = selectedCategories.compactMap { categories[$0] }
        var articleData: [String: Any] = [
            "title": title,
            "category": selectedCategoryIDs,
            "content": content,
            "created_at": Timestamp(date: Date()),
            "created_user_id": userID,
            "public_status": false,
            "public_date": Timestamp(date: Date()),
            "deleted_at": NSNull()
        ]
        
        uploadAllMedia(documentID: document.documentID) { urls in
            if !urls.isEmpty {
                articleData["image_file"] = urls
            } else {
                articleData["image_file"] = NSNull()
            }
            document.setData(articleData) { error in
                if error == nil {
                    self.postUploadTasks(documentID: document.documentID)
                }
            }
        }
    }
    
    private func postUploadTasks(documentID: String) {
        let db = Firestore.firestore()
        let timestamp = Timestamp(date: Date())
        
        let aggregateData: [String: Any] = [
            "article_id": documentID,
            "access_daily": 0,
            "access_weekly": 0,
            "access_monthly": 0,
            "access_total": 0,
            "like_daily": 0,
            "like_weekly": 0,
            "like_monthly": 0,
            "like_total": 0,
            "created_at": timestamp,
            "updated_at": timestamp
        ]
        db.collection("aggregate_points").document(documentID).setData(aggregateData)
        
        let ratingData: [String: Any] = [
            "article_id": documentID,
            "access_count": 0,
            "like_count": 0
        ]
        db.collection("daily_rating").document(documentID).setData(ratingData)
        db.collection("history_rating").document(documentID).setData(ratingData)
        
        isSubmitting = false
        showModal = true
    }
    
    private func uploadAllMedia(documentID: String, completion: @escaping ([String]) -> Void) {
        var uploadedURLs = [String]()
        let group = DispatchGroup()
        
        for i in 0..<4 {
            if mediaItems[i] != nil || videoURLs[i] != nil {
                group.enter()
                uploadMedia(image: mediaItems[i], videoURL: videoURLs[i], documentID: documentID) { url in
                    if !url.isEmpty {
                        uploadedURLs.append(url)
                    }
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) {
            completion(uploadedURLs)
        }
    }
    
    private func uploadMedia(image: UIImage? = nil, videoURL: URL? = nil, documentID: String, completion: @escaping (String) -> Void) {
        let storageRef = Storage.storage().reference()
        let mediaRef = storageRef.child("media/\(documentID)/\(UUID().uuidString)")
        
        if let image = image, let imageData = image.jpegData(compressionQuality: 0.8) {
            let imageRef = mediaRef.child("media.jpg")
            imageRef.putData(imageData, metadata: nil) { _, error in
                if let error = error {
                    print("Failed to upload image: \(error.localizedDescription)")
                    completion("")
                    return
                }
                imageRef.downloadURL { url, error in
                    guard let url = url else {
                        print("Failed to get download URL: \(error?.localizedDescription ?? "Unknown error")")
                        completion("")
                        return
                    }
                    completion(url.absoluteString)
                }
            }
        } else if let videoURL = videoURL {
            let videoRef = mediaRef.child("media.mov")
            videoRef.putFile(from: videoURL, metadata: nil) { _, error in
                if let error = error {
                    print("Failed to upload video: \(error.localizedDescription)")
                    completion("")
                    return
                }
                videoRef.downloadURL { url, error in
                    guard let url = url else {
                        print("Failed to get download URL: \(error?.localizedDescription ?? "Unknown error")")
                        completion("")
                        return
                    }
                    completion(url.absoluteString)
                }
            }
        } else {
            completion("")
        }
    }
}


#Preview {
    ArticleRequestView()
}
