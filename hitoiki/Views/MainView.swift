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
    @State private var newsItems: [NewsItem] = []
    
    var body: some View {
        TabView {
            NavigationView {
                NewsListView(newsItems: newsItems)
                    .navigationTitle("最新のニュース")
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
        .onAppear(perform: fetchNewsItems)
        .refreshable {
            fetchNewsItems()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    func fetchNewsItems() {
        let db = Firestore.firestore()
        let group = DispatchGroup()
        var fetchedItems = [NewsItem]()
        
        db.collection("articles")
            .whereField("public_status", isEqualTo: true)
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Error getting articles: \(error)")
                    return
                }
                guard let documents = querySnapshot?.documents else {
                    print("No documents found")
                    return
                }
                
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
                    self.newsItems = fetchedItems
                    print("Fetched \(self.newsItems.count) items with aggregate data")
                }
            }
    }
    
    func fetchAggregateData(_ item: NewsItem, completion: @escaping (NewsItem?) -> Void) {
        guard let itemId = item.id else { return }
        let db = Firestore.firestore()
        
        db.collection("aggregate_points")
            .whereField("article_id", isEqualTo: itemId)
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

