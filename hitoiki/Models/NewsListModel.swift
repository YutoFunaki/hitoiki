//
//  NewsListModel.swift
//  hitoiki
//
//  Created by 船木勇斗 on 2024/07/27.
//

import Foundation

struct NewsItem: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let date: Date
}
