//
//  ArticleContentView.swift
//  hitoiki
//
//  Created by 船木勇斗 on 2024/07/28.
//

import SwiftUI

struct ArticleContentView: View {
    var article: NewsItem
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(article.title)
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .center) // Center the title within the full width
                HStack {
                    Text("公開日: \(article.publicDate, formatter: DateFormatter.japaneseShort)")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer() // Spacer to push the next item to the right
                    Text("閲覧数: \(article.accessTotal ?? 0)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Divider()
                Text(article.content)
                    .font(.body)
            }
            .padding()
        }
        .navigationTitle("記事の詳細")
        .navigationBarTitleDisplayMode(.inline)
    }
}
