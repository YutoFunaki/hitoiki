//
//  NewsListView.swift
//  hitoiki
//
//  Created by 船木勇斗 on 2024/07/27.
//

import SwiftUI

extension String {
    /// Truncate the string to a specified length, adding trailing characters if needed.
    func truncated(to length: Int, trailing: String = "...") -> String {
        if self.count > length {
            return String(self.prefix(length)) + trailing
        } else {
            return self
        }
    }
}

struct NewsListView: View {
    var newsItems: [NewsItem]
    @State private var selectedCategory: Int? = nil
    
    let categories: [String: Int] = ["全て": 0, "猫": 1, "犬": 2, "小動物": 3, "赤ちゃん": 4, "エンタメ": 5]
    
    var filteredNewsItems: [NewsItem] {
        guard let category = selectedCategory, category != 0 else {
            return newsItems
        }
        return newsItems.filter { $0.category.contains(category) }
    }
    
    var body: some View {
        VStack {
            categoryScrollView
            articlesList
        }
    }
    
    var categoryScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(categories.sorted(by: { $0.value < $1.value }).map { $0.key }, id: \.self) { key in
                    Button(action: {
                        self.selectedCategory = self.categories[key]
                    }) {
                        Text(key)
                            .padding(.vertical, -10) // 縦方向のパディングを小さく
                            .padding(.horizontal, 0) // 横方向のパディングも小さく設定
                            .padding()
                            .background(selectedCategory == categories[key] ? Color.blue : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    var articlesList: some View {
        List(filteredNewsItems, id: \.id) { item in
            NavigationLink(destination: ArticleContentView(article: item)) {
                ArticleRow(item: item)
            }
        }
        .listStyle(.inset)
    }
}

struct ArticleRow: View {
    var item: NewsItem
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(item.title.truncated(to: 35))
                    .font(.headline)
                HStack {
                    Text(item.publicDate, formatter: DateFormatter.japaneseShort)
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("Views: \(item.accessTotal ?? 0)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            VStack(spacing: 16) {
                if let url = URL(string: item.imageUrl.first ?? "") {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Color.gray
                    }
                    .frame(width: 70, height: 70)
                    .clipped()
                    .cornerRadius(8)
                }
                Text("\(item.likeTotal ?? 0) いいね")
                    .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }
}

extension DateFormatter {
    static var japaneseShort: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        return formatter
    }
}
