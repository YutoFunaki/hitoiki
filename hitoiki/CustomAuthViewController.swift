//
//  CustomAuthViewController.swift
//  hitoiki
//
//  Created by 船木勇斗 on 2024/07/21.
//

import UIKit
import FirebaseAuthUI

class CustomAuthViewController: FUIAuthPickerViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 背景色を白に設定
        self.view.backgroundColor = UIColor.white
        print("CustomAuthViewController viewDidLoad called")  // デバッグプリント
        
        // ナビゲーションバーのカスタマイズ
        if let navBar = self.navigationController?.navigationBar {
            navBar.barTintColor = UIColor.white
            navBar.isTranslucent = false
        }
        
        // カスタムビューの追加
        addCustomLabel()
    }
    
    func addCustomLabel() {
        // 中央に配置するラベルを作成
        let label = UILabel()
        label.text = "ホッとひといき"
        label.textColor = UIColor.gray
        label.textAlignment = .natural
        label.font = UIFont.systemFont(ofSize: 40, weight: .heavy)
        label.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(label)
        
        // 制約を設定して中央に配置
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: self.view.centerYAnchor)
        ])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // ナビゲーションバーのタイトルを非表示に設定
        self.navigationItem.title = ""
        
        // キャンセルボタンを非表示に設定
        self.navigationItem.leftBarButtonItem = nil
    }
}

