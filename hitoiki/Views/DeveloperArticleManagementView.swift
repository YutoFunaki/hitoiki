//
//  DeveloperArticleManagementView.swift
//  hitoiki
//
//  Created by 船木勇斗 on 2024/08/25.
//

import SwiftUI
import FirebaseFirestore

struct DeveloperArticleManagementView: View {
    @State private var newsItems: [NewsItem] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            List($newsItems, id: \.id) { $item in
                NavigationLink(destination: ArticleEditView(article: $item)) {
                    // wrappedValue を削除して item をそのまま渡す
                    ArticleRow(item: item)
                }
            }
            .onAppear {
                fetchNewsItems()
            }
            .overlay {
                if isLoading {
                    ProgressView("Loading...")
                } else if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                }
            }
        }
        .navigationTitle("記事管理")
    }
    
    func fetchNewsItems() {
        isLoading = true
        errorMessage = nil
        
        let db = Firestore.firestore()
        let group = DispatchGroup()
        var fetchedItems = [NewsItem]()
        
        db.collection("articles")
            .whereField("public_status", isEqualTo: false)
            .whereField("deleted_at", isEqualTo: NSNull())
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    errorMessage = "Error getting articles: \(error.localizedDescription)"
                    isLoading = false
                    return
                }
                guard let documents = querySnapshot?.documents else {
                    errorMessage = "No documents found"
                    isLoading = false
                    return
                }
                
                for document in documents {
                    group.enter()
                    if var item = try? document.data(as: NewsItem.self) {
                        item.id = document.documentID
                        fetchAggregateData(item) { updatedItem in
                            if let updatedItem = updatedItem {
                                fetchedItems.append(updatedItem)
                            }
                            group.leave()
                        }
                    } else {
                        group.leave()
                    }
                }
                
                group.notify(queue: .main) {
                    self.newsItems = fetchedItems
                    self.isLoading = false
                    if self.newsItems.isEmpty {
                        self.errorMessage = "No articles found with aggregate data"
                    }
                }
            }
    }
    
    func fetchAggregateData(_ item: NewsItem, completion: @escaping (NewsItem?) -> Void) {
        let db = Firestore.firestore()
        
        db.collection("aggregate_points")
            .whereField("article_id", isEqualTo: item.id ?? "")
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Error getting aggregate data: \(error)")
                    completion(nil)
                } else {
                    if let document = querySnapshot?.documents.first, document.exists {
                        var updatedItem = item
                        let data = document.data()
                        updatedItem.accessTotal = data["access_total"] as? Int ?? 0
                        updatedItem.likeTotal = data["like_total"] as? Int ?? 0
                        completion(updatedItem)
                    } else {
                        print("No aggregate data found for item \(item.id ?? "unknown")")
                        completion(nil)
                    }
                }
            }
    }
}

#Preview {
    DeveloperArticleManagementView()
}
