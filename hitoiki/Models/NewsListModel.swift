//
//  NewsListModel.swift
//  hitoiki
//
//  Created by 船木勇斗 on 2024/07/27.
//

import Foundation
import FirebaseFirestoreSwift

struct NewsItem: Identifiable, Codable {
    @DocumentID var id: String?  // Firestore DocumentIDを使用
    var category: [Int] // Firestoreのcategoryフィールド
    var title: String
    var content: String // Firestoreのcontentフィールド
    var imageUrl: [String] // Firestoreのimage_fileフィールド
    var publicDate: Date // Firestoreのpublic_dateフィールド
    var accessTotal: Int?  // 集計データは別途追加
    var likeTotal: Int?    // 同上
    var createdUserID: String
    
    
    enum CodingKeys: String, CodingKey {
        case id
        case category
        case title
        case content
        case imageUrl = "image_file"
        case publicDate = "public_date"
        case createdUserID = "created_user_id"
    }
}
