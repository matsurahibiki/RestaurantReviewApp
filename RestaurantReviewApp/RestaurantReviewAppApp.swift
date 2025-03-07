//
//  RestaurantReviewAppApp.swift
//  RestaurantReviewApp
//
//  Created by k20108kk on 2025/03/07.
//

import SwiftUI
import RealmSwift

@main
struct RestaurantReviewApp: SwiftUI.App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // Realmの初期化と設定
                    initializeRealm()
                }
        }
    }

    func initializeRealm() {
        let config = Realm.Configuration(
            schemaVersion: 1,
            migrationBlock: { migration, oldSchemaVersion in
                // 将来的なスキーマ変更のためのマイグレーション処理
            }
        )
        Realm.Configuration.defaultConfiguration = config
    }
}
