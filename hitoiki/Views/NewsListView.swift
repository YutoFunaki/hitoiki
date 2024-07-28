//
//  NewsListView.swift
//  hitoiki
//
//  Created by 船木勇斗 on 2024/07/27.
//

import SwiftUI

struct NewsListView: View {
    let newsItems: [NewsItem]
    
    var body: some View {
        List(newsItems) { item in
            VStack(alignment: .leading) {
                Text(item.title)
                    .font(.headline)
                Text(item.description)
                    .font(.subheadline)
                Text(item.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 4)
        }
    }
}
