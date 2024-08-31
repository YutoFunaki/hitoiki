//
//  MainView.swift
//  hitoiki
//
//  Created by 船木勇斗 on 2024/07/21.
//
import SwiftUI
import FirebaseFirestore
import FirebaseFirestoreSwift

struct MainView: View {
    @StateObject private var viewModel = NewsViewModel()
    
    var body: some View {
        TabView {
            NavigationView {
                NewsListView(newsItems: viewModel.newsItems)
                    .navigationTitle("最新のニュース")
                    .refreshable {
                        viewModel.refreshNewsItems() // 引っ張って更新
                    }
                    .onAppear {
                        viewModel.fetchNewsItems()
                    }
            }
            .tabItem {
                Image(systemName: "house.fill")
                Text("ホーム")
            }
            
            NavigationView {
                SearchView()
                    .navigationTitle("検索する")
            }
            .tabItem {
                Image(systemName: "magnifyingglass")
                Text("検索する")
            }
            
            NavigationView {
                RankingView()
                    .navigationTitle("ランキング")
            }
            .tabItem {
                Image(systemName: "crown.fill")
                Text("ランキング")
            }
            
            NavigationView {
                MyPageView()
                    .navigationTitle("マイページ")
            }
            .tabItem {
                Image(systemName: "person.fill")
                Text("マイページ")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

class NewsViewModel: ObservableObject {
    @Published var newsItems: [NewsItem] = []
    private var lastDocument: DocumentSnapshot? = nil
    private var isFetching = false
    private let pageSize = 30
    
    // ニュースアイテムを再取得して更新するための関数
    func refreshNewsItems() {
        // リストをクリアして再取得
        self.newsItems = []
        self.lastDocument = nil
        self.fetchNewsItems()
    }
    
    func fetchNewsItems() {
        guard !isFetching else { return }
        isFetching = true
        
        let db = Firestore.firestore()
        var query: Query = db.collection("articles")
            .whereField("public_status", isEqualTo: true)
            .whereField("deleted_at", isEqualTo: NSNull()) // deleted_at が null のみ取得
            .order(by: "public_date", descending: true) // 最新順に並べる
            .limit(to: pageSize)
        
        // lastDocument が存在する場合は、次のページを取得
        if let lastDoc = lastDocument {
            query = query.start(afterDocument: lastDoc)
        }
        
        query.getDocuments { (querySnapshot, error) in
            self.isFetching = false
            if let error = error {
                print("Error getting articles: \(error)")
                return
            }
            guard let documents = querySnapshot?.documents else {
                print("No documents found")
                return
            }
            
            // ページネーション用の lastDocument を更新
            if !documents.isEmpty {
                self.lastDocument = documents.last
            }
            
            let group = DispatchGroup()
            var fetchedItems = [NewsItem]()
            
            for document in documents {
                group.enter()
                var item = try? document.data(as: NewsItem.self)
                item?.id = document.documentID
                
                if let item = item {
                    self.fetchAggregateData(item) { updatedItem in
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
                // 同じ記事がすでにリストに存在する場合は置き換え、それ以外は追加
                for newItem in fetchedItems {
                    if let index = self.newsItems.firstIndex(where: { $0.id == newItem.id }) {
                        self.newsItems[index] = newItem
                    } else {
                        self.newsItems.append(newItem)
                    }
                }
                print("Fetched \(self.newsItems.count) items with aggregate data")
            }
        }
    }
    
    func fetchAggregateData(_ item: NewsItem, completion: @escaping (NewsItem?) -> Void) {
        guard let itemId = item.id else { return }
        let db = Firestore.firestore()
        
        db.collection("history_rating")
            .whereField("article_id", isEqualTo: itemId)
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Error getting aggregate data: \(error)")
                    completion(nil)
                } else {
                    if let document = querySnapshot?.documents.first, document.exists {
                        var updatedItem = item
                        let data = document.data()
                        updatedItem.accessTotal = data["access_count"] as? Int ?? 0
                        updatedItem.likeTotal = data["like_count"] as? Int ?? 0
                        completion(updatedItem)
                    } else {
                        print("No aggregate data found for item \(itemId)")
                        completion(nil)
                    }
                }
            }
    }
}

#Preview {
    MainView()
}
