//
//  SerchView.swift
//  hitoiki
//
//  Created by 船木勇斗 on 2024/07/28.
//

import SwiftUI
import FirebaseFirestore

struct SearchView: View {
    @State private var searchText = ""
    @State private var searchResults: [NewsItem] = []
    
    var body: some View {
        VStack {
            SearchBar(text: $searchText, onSearchButtonClicked: search)
            NewsListView(newsItems: searchResults) // 検索結果を表示するNewsListView
                .listStyle(.inset)
        }
        .onChange(of: searchText) { _ in
            search()  // 検索テキストが変更されたときに検索をトリガー
        }
    }
    
    func search() {
        let db = Firestore.firestore()
        db.collection("articles")
            .whereField("public_status", isEqualTo: true)
            .whereField("deleted_at", isEqualTo: NSNull())
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Error getting articles: \(error)")
                    return
                }
                guard let documents = querySnapshot?.documents else {
                    print("No documents found")
                    return
                }
                
                let allNewsItems = documents.compactMap { document -> NewsItem? in
                    try? document.data(as: NewsItem.self)
                }
                
                // タイトルやコンテンツに検索テキストが含まれる記事をフィルタリング
                self.searchResults = allNewsItems.filter {
                    $0.title.localizedCaseInsensitiveContains(self.searchText) ||
                    $0.content.localizedCaseInsensitiveContains(self.searchText)
                }
            }
    }
}

struct SearchBar: UIViewRepresentable {
    @Binding var text: String
    var onSearchButtonClicked: () -> Void
    
    class Coordinator: NSObject, UISearchBarDelegate {
        @Binding var text: String
        var onSearchButtonClicked: () -> Void
        
        init(text: Binding<String>, onSearchButtonClicked: @escaping () -> Void) {
            _text = text
            self.onSearchButtonClicked = onSearchButtonClicked
        }
        
        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            text = searchText
        }
        
        func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
            searchBar.resignFirstResponder()
            onSearchButtonClicked()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(text: $text, onSearchButtonClicked: onSearchButtonClicked)
    }
    
    func makeUIView(context: Context) -> UISearchBar {
        let searchBar = UISearchBar(frame: .zero)
        searchBar.delegate = context.coordinator
        return searchBar
    }
    
    func updateUIView(_ uiView: UISearchBar, context: Context) {
        uiView.text = text
    }
}

#Preview {
    SearchView()
}
