//
//  LoginView.swift
//  hitoiki
//
//  Created by 船木勇斗 on 2024/07/21.
//

import SwiftUI
import FirebaseAuthUI
import FirebaseGoogleAuthUI
import FirebaseOAuthUI
import FirebaseFirestore // これを追加

struct LoginView: UIViewControllerRepresentable {
    @Binding var isLoggedIn: Bool
    
    func makeUIViewController(context: Context) -> UINavigationController {
        let authUI = FUIAuth.defaultAuthUI()!
        authUI.delegate = context.coordinator
        
        // ログイン方法を選択
        let providers: [FUIAuthProvider] = [
            FUIGoogleAuth(authUI: authUI),
            FUIOAuth.appleAuthProvider(),
        ]
        authUI.providers = providers
        
        // FirebaseUIを表示する
        let authViewController = authUI.authViewController()
        
        return authViewController
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        // 処理なし
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, FUIAuthDelegate {
        var parent: LoginView
        
        init(_ parent: LoginView) {
            self.parent = parent
        }
        
        func authUI(_ authUI: FUIAuth, didSignInWith authDataResult: AuthDataResult?, error: Error?) {
            if let error = error {
                print("Error during sign in: \(error.localizedDescription)")
                return
            }
            
            guard let user = authDataResult?.user else { return }
            parent.isLoggedIn = true
            
            let db = Firestore.firestore()
            let usersRef = db.collection("users").document(user.uid)
            
            usersRef.getDocument { (document, error) in
                if let error = error {
                    print("Error getting user document: \(error.localizedDescription)")
                    return
                }
                
                if let document = document, document.exists {
                    // ユーザーが既に存在する場合は何もしない
                    print("User already exists in Firestore.")
                } else {
                    // ユーザーが存在しない場合、新しいユーザーデータを追加
                    let userData: [String: Any] = [
                        "uid": user.uid,
                        "display_name": user.displayName ?? "",
                        "email": user.email ?? "",
                        "phone_number": user.phoneNumber ?? "",
                        "provider_data": user.providerData.map { $0.providerID }.joined(separator: ", "),
                        "created_at": Timestamp(date: Date())  // 作成日時
                    ]
                    
                    usersRef.setData(userData) { error in
                        if let error = error {
                            print("Error saving user data: \(error.localizedDescription)")
                        } else {
                            print("User data added to Firestore successfully.")
                        }
                    }
                }
            }
        }

        
        func authPickerViewController(forAuthUI authUI: FUIAuth) -> FUIAuthPickerViewController {
            print("CustomAuthViewController is being used")  // デバッグプリント
            
            let controller = CustomAuthViewController(authUI: authUI)
            
            // ナビゲーションバーの背景色を白に設定
            if let navController = controller.navigationController {
                navController.navigationBar.barTintColor = UIColor.white
            }
            
            // ビューの背景色を再帰的に白に設定
            setBackgroundColor(view: controller.view, color: UIColor.white)
            
            return controller
        }
        
        func setBackgroundColor(view: UIView, color: UIColor) {
            // ボタンとそのサブビューの背景色を変更しない
            if !(view is UIButton) && !(view is UIStackView) && !(view is UIControl) {
                view.backgroundColor = color
                for subview in view.subviews {
                    setBackgroundColor(view: subview, color: color)
                }
            }
        }
    }
}

#Preview {
    LoginView(isLoggedIn: .constant(false))
}
