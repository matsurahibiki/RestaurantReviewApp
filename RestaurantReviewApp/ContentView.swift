//
//  ContentView.swift
//  RestaurantReviewApp
//
//  Created by k20108kk on 2025/03/07.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("ホーム", systemImage: "house")
                }
                .tag(0)

            RestaurantListView()
                .tabItem {
                    Label("レストラン", systemImage: "fork.knife")
                }
                .tag(1)

            DishListView()
                .tabItem {
                    Label("料理", systemImage: "star")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label("設定", systemImage: "gear")
                }
                .tag(3)
        }
        .onAppear {
            // 初期データのセットアップ
            DataManager.shared.setupInitialDataIfNeeded()
        }
    }
}

#Preview {
    ContentView()
}
