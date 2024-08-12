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
            List(searchResults) { item in
                VStack(alignment: .leading) {
                    Text(item.title)
                        .font(.headline)
                    Text(item.public_date, formatter: DateFormatter.japaneseShort)
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(item.content)
                        .font(.subheadline)
                }
                .padding(.vertical, 4)
            }
            .listStyle(.inset)
        }
    }
    
    func search() {
        let db = Firestore.firestore()
        
        db.collection("articles")
            .whereField("public_status", isEqualTo: true)
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Error getting documents: \(error)")
                } else {
                    let allNewsItems: [NewsItem] = querySnapshot?.documents.compactMap { document in
                        try? document.data(as: NewsItem.self)
                    } ?? []
                    
                    searchResults = allNewsItems.filter { $0.title.contains(searchText) || $0.content.contains(searchText) }
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
