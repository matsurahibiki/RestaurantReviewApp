//
//  Restaurant.swift
//  RestaurantReviewApp
//
//  Created by k20108kk on 2025/03/07.
//

// レストラン評価アプリ - フェーズ1実装
// （データモデル、基本UI、レストラン・料理登録機能、リスト表示機能）

import SwiftUI
import RealmSwift

// MARK: - データモデル

// Realmモデル - レストラン
class Restaurant: Object, Identifiable {
    @Persisted(primaryKey: true) var id: UUID = UUID()
    @Persisted var name: String = ""
    @Persisted var genre: String = ""
    @Persisted var address: String = ""
    @Persisted var url: String? = nil
    @Persisted var imagePath: String? = nil
    @Persisted var registrationDate: Date = Date()
    @Persisted var lastUpdateDate: Date = Date()
    @Persisted var isFavorite: Bool = false
    @Persisted var memo: String? = nil
    @Persisted var visitCount: Int = 0
    @Persisted var businessHours: String? = nil
    @Persisted var dishes: RealmSwift.List<Dish>

    // 初期化メソッド
    convenience init(name: String, genre: String, address: String) {
        self.init()
        self.name = name
        self.genre = genre
        self.address = address
        self.registrationDate = Date()
        self.lastUpdateDate = Date()
    }
}

// Realmモデル - 料理
class Dish: Object, Identifiable {
    @Persisted(primaryKey: true) var id: UUID = UUID()
    @Persisted var name: String = ""
    @Persisted var category: String = ""
    @Persisted var score: Int = 50 // デフォルト値は50点
    @Persisted var memo: String? = nil
    @Persisted var price: Int = 0
    @Persisted var isFavorite: Bool = false
    @Persisted var registrationDate: Date = Date()
    @Persisted var lastUpdateDate: Date = Date()
    @Persisted var orderCount: Int = 1
    @Persisted var imagePath: String? = nil
    @Persisted(originProperty: "dishes") var restaurant: LinkingObjects<Restaurant>

    // 初期化メソッド
    convenience init(name: String, category: String, price: Int, score: Int) {
        self.init()
        self.name = name
        self.category = category
        self.price = price
        self.score = score
        self.registrationDate = Date()
        self.lastUpdateDate = Date()
    }
}

// Realmモデル - カテゴリ
class Category: Object, Identifiable {
    @Persisted(primaryKey: true) var id: UUID = UUID()
    @Persisted var name: String = ""
    @Persisted var type: String = "" // "restaurant" または "dish"

    // 初期化メソッド
    convenience init(name: String, type: String) {
        self.init()
        self.name = name
        self.type = type
    }
}

// Realmモデル - ユーザー設定
class UserPreferences: Object, Identifiable {
    @Persisted(primaryKey: true) var id: UUID = UUID()
    @Persisted var defaultSortOrder: String = "name" // デフォルトは名前順
    @Persisted var defaultFilterGenre: String? = nil
    @Persisted var theme: String = "system" // system, light, dark

    // 初期化メソッド
    convenience init(defaultSortOrder: String, theme: String) {
        self.init()
        self.defaultSortOrder = defaultSortOrder
        self.theme = theme
    }
}

// MARK: - データ操作クラス

class DataManager {
    static let shared = DataManager()

    // レストランの保存
    func saveRestaurant(restaurant: Restaurant) {
        let realm = try! Realm()
        try! realm.write {
            realm.add(restaurant, update: .modified)
        }
    }

    // レストランの削除
    func deleteRestaurant(restaurant: Restaurant) {
        let realm = try! Realm()
        try! realm.write {
            realm.delete(restaurant)
        }
    }

    // 料理の保存（レストランに追加）
    func saveDish(dish: Dish, to restaurant: Restaurant) {
        let realm = try! Realm()
        try! realm.write {
            restaurant.dishes.append(dish)
            restaurant.lastUpdateDate = Date()
        }
    }

    // 料理の削除
    func deleteDish(dish: Dish) {
        let realm = try! Realm()
        try! realm.write {
            realm.delete(dish)
        }
    }

    // すべてのレストランを取得
    func getAllRestaurants() -> Results<Restaurant> {
        let realm = try! Realm()
        return realm.objects(Restaurant.self).sorted(byKeyPath: "name")
    }

    // ジャンル別にレストランを取得
    func getRestaurantsByGenre(genre: String) -> Results<Restaurant> {
        let realm = try! Realm()
        return realm.objects(Restaurant.self).filter("genre == %@", genre).sorted(byKeyPath: "name")
    }

    // レストランに関連する料理を取得
    func getDishes(for restaurant: Restaurant) -> RealmSwift.List<Dish> {
        return restaurant.dishes
    }

    // すべての料理カテゴリを取得
    func getAllDishCategories() -> Results<Category> {
        let realm = try! Realm()
        return realm.objects(Category.self).filter("type == 'dish'").sorted(byKeyPath: "name")
    }

    // すべてのレストランジャンルを取得
    func getAllRestaurantGenres() -> Results<Category> {
        let realm = try! Realm()
        return realm.objects(Category.self).filter("type == 'restaurant'").sorted(byKeyPath: "name")
    }

    // カテゴリの保存
    func saveCategory(category: Category) {
        let realm = try! Realm()
        try! realm.write {
            realm.add(category, update: .modified)
        }
    }

    // 初期データのセットアップ（初回起動時）
    func setupInitialDataIfNeeded() {
        let realm = try! Realm()

        // ユーザー設定の初期化
        if realm.objects(UserPreferences.self).isEmpty {
            let preferences = UserPreferences(defaultSortOrder: "name", theme: "system")
            try! realm.write {
                realm.add(preferences)
            }
        }

        // レストランジャンルの初期データ
        if realm.objects(Category.self).filter("type == 'restaurant'").isEmpty {
            let restaurantCategories = [
                "和食", "洋食", "中華", "イタリアン", "フレンチ", "アジア料理", "カフェ", "ファストフード", "その他"
            ]

            try! realm.write {
                for categoryName in restaurantCategories {
                    let category = Category(name: categoryName, type: "restaurant")
                    realm.add(category)
                }
            }
        }

        // 料理カテゴリの初期データ
        if realm.objects(Category.self).filter("type == 'dish'").isEmpty {
            let dishCategories = [
                "前菜", "メイン", "サイド", "デザート", "ドリンク", "その他"
            ]

            try! realm.write {
                for categoryName in dishCategories {
                    let category = Category(name: categoryName, type: "dish")
                    realm.add(category)
                }
            }
        }
    }
}

// MARK: - メイン画面とナビゲーション


// MARK: - ホーム画面

struct HomeView: View {
    @ObservedResults(Restaurant.self) var restaurants

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 最近追加したレストラン
                    if !restaurants.isEmpty {
                        RecentRestaurantsSection(restaurants: Array(restaurants.sorted(by: { $0.registrationDate > $1.registrationDate }).prefix(5)))
                    }

                    // お気に入りレストラン
                    let favoriteRestaurants = restaurants.filter { $0.isFavorite }
                    if !favoriteRestaurants.isEmpty {
                        FavoriteRestaurantsSection(restaurants: Array(favoriteRestaurants))
                    }

                    // 訪問頻度の高いレストラン
                    let frequentRestaurants = Array(restaurants.sorted(by: { $0.visitCount > $1.visitCount }).prefix(5))
                    if !frequentRestaurants.isEmpty {
                        FrequentRestaurantsSection(restaurants: frequentRestaurants)
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("マイレストラン")
        }
    }
}

struct RecentRestaurantsSection: View {
    var restaurants: [Restaurant]

    var body: some View {
        VStack(alignment: .leading) {
            Text("最近追加したレストラン")
                .font(.headline)
                .padding(.bottom, 5)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(restaurants) { restaurant in
                        NavigationLink(destination: RestaurantDetailView(restaurant: restaurant)) {
                            RestaurantCard(restaurant: restaurant)
                        }
                    }
                }
            }
        }
    }
}

struct FavoriteRestaurantsSection: View {
    var restaurants: [Restaurant]

    var body: some View {
        VStack(alignment: .leading) {
            Text("お気に入りレストラン")
                .font(.headline)
                .padding(.bottom, 5)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(restaurants) { restaurant in
                        NavigationLink(destination: RestaurantDetailView(restaurant: restaurant)) {
                            RestaurantCard(restaurant: restaurant)
                        }
                    }
                }
            }
        }
    }
}

struct FrequentRestaurantsSection: View {
    var restaurants: [Restaurant]

    var body: some View {
        VStack(alignment: .leading) {
            Text("よく行くレストラン")
                .font(.headline)
                .padding(.bottom, 5)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(restaurants) { restaurant in
                        NavigationLink(destination: RestaurantDetailView(restaurant: restaurant)) {
                            RestaurantCard(restaurant: restaurant)
                                .overlay(
                                    Text("\(restaurant.visitCount)回")
                                        .font(.caption)
                                        .padding(5)
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .clipShape(Capsule())
                                        .offset(x: 0, y: -60),
                                    alignment: .topTrailing
                                )
                        }
                    }
                }
            }
        }
    }
}

struct RestaurantCard: View {
    var restaurant: Restaurant

    var body: some View {
        VStack(alignment: .leading) {
            // レストラン画像
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 120, height: 80)
                .overlay(
                    Image(systemName: "photo")
                        .foregroundColor(.gray)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(restaurant.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Text(restaurant.genre)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(5)
        }
        .frame(width: 120)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}

// MARK: - レストラン一覧画面

struct RestaurantListView: View {
    @ObservedResults(Restaurant.self) var restaurants
    @State private var searchText = ""
    @State private var showingAddRestaurant = false
    @State private var selectedGenre: String? = nil
    @ObservedResults(Category.self) var restaurantCategories

    var filteredRestaurants: [Restaurant] {
        if searchText.isEmpty && selectedGenre == nil {
            return Array(restaurants)
        } else if !searchText.isEmpty && selectedGenre == nil {
            return restaurants.filter { $0.name.localizedCaseInsensitiveContains(searchText) || $0.address.localizedCaseInsensitiveContains(searchText) }
        } else if searchText.isEmpty && selectedGenre != nil {
            return restaurants.filter { $0.genre == selectedGenre }
        } else {
            return restaurants.filter {
                ($0.name.localizedCaseInsensitiveContains(searchText) || $0.address.localizedCaseInsensitiveContains(searchText)) &&
                $0.genre == selectedGenre
            }
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                // ジャンルフィルター
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        GenreFilterButton(title: "すべて", isSelected: selectedGenre == nil) {
                            selectedGenre = nil
                        }

                        ForEach(restaurantCategories.filter { $0.type == "restaurant" }) { category in
                            GenreFilterButton(title: category.name, isSelected: selectedGenre == category.name) {
                                selectedGenre = category.name
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                // レストランリスト
                List {
                    ForEach(filteredRestaurants) { restaurant in
                        NavigationLink(destination: RestaurantDetailView(restaurant: restaurant)) {
                            RestaurantRow(restaurant: restaurant)
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let restaurantToDelete = filteredRestaurants[index]
                            DataManager.shared.deleteRestaurant(restaurant: restaurantToDelete)
                        }
                    }
                }
                .searchable(text: $searchText, prompt: "レストラン名や住所で検索")
            }
            .navigationTitle("レストラン一覧")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddRestaurant = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddRestaurant) {
                NavigationView {
                    RestaurantFormView(mode: .add)
                        .navigationTitle("レストランを追加")
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("閉じる") {
                                    showingAddRestaurant = false
                                }
                            }
                        }
                }
            }
        }
    }
}

struct GenreFilterButton: View {
    var title: String
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

struct RestaurantRow: View {
    var restaurant: Restaurant

    var body: some View {
        HStack {
            // レストラン画像（プレースホルダー）
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 60, height: 60)
                .cornerRadius(6)
                .overlay(
                    Image(systemName: "photo")
                        .foregroundColor(.gray)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(restaurant.name)
                    .font(.headline)

                Text(restaurant.genre)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if let memo = restaurant.memo, !memo.isEmpty {
                    Text(memo)
                        .font(.caption)
                        .lineLimit(1)
                        .foregroundColor(.gray)
                }
            }

            Spacer()

            if restaurant.isFavorite {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - レストラン詳細画面

struct RestaurantDetailView: View {
    @ObservedRealmObject var restaurant: Restaurant
    @State private var showingEditSheet = false
    @State private var showingAddDish = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // ヘッダー部分（画像とデータ）
                RestaurantHeaderView(restaurant: restaurant)

                Divider()

                // 料理セクション
                DishesSection(restaurant: restaurant, showingAddDish: $showingAddDish)

                Divider()

                // 詳細情報
                RestaurantInfoSection(restaurant: restaurant)

                Spacer(minLength: 50)
            }
            .padding()
        }
        .navigationTitle(restaurant.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingEditSheet = true
                }) {
                    Text("編集")
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            NavigationView {
                RestaurantFormView(mode: .edit, existingRestaurant: restaurant)
                    .navigationTitle("レストランを編集")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("閉じる") {
                                showingEditSheet = false
                            }
                        }
                    }
            }
        }
        .sheet(isPresented: $showingAddDish) {
            NavigationView {
                DishFormView(restaurant: restaurant)
                    .navigationTitle("料理を追加")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("閉じる") {
                                showingAddDish = false
                            }
                        }
                    }
            }
        }
    }
}

struct RestaurantHeaderView: View {
    @ObservedRealmObject var restaurant: Restaurant

    var body: some View {
        VStack {
            // レストラン画像（プレースホルダー）
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 200)
                .overlay(
                    Image(systemName: "photo")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                )
                .cornerRadius(10)

            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(restaurant.name)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(restaurant.genre)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text(restaurant.address)
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer()

                Button(action: {
                    // Realmオブジェクトを更新
                    let realm = try! Realm()
                    try! realm.write {
                        restaurant.isFavorite.toggle()
                    }
                }) {
                    Image(systemName: restaurant.isFavorite ? "star.fill" : "star")
                        .font(.title2)
                        .foregroundColor(restaurant.isFavorite ? .yellow : .gray)
                }
            }
        }
    }
}

struct DishesSection: View {
    @ObservedRealmObject var restaurant: Restaurant
    @Binding var showingAddDish: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("料理")
                    .font(.headline)

                Spacer()

                Button(action: {
                    showingAddDish = true
                }) {
                    Label("追加", systemImage: "plus")
                        .font(.caption)
                }
            }

            if restaurant.dishes.isEmpty {
                Text("料理が登録されていません")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding()
            } else {
                ForEach(Array(restaurant.dishes)) { dish in
                    NavigationLink(destination: DishDetailView(dish: dish)) {
                        DishRow(dish: dish)
                    }
                }
            }
        }
    }
}

struct DishRow: View {
    var dish: Dish

    var body: some View {
        HStack {
            // 料理画像（プレースホルダー）
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 50, height: 50)
                .cornerRadius(6)
                .overlay(
                    Image(systemName: "photo")
                        .foregroundColor(.gray)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(dish.name)
                    .font(.headline)

                HStack {
                    Text("¥\(dish.price)")
                        .font(.subheadline)

                    Spacer()

                    Text("\(dish.score)点")
                        .font(.caption)
                        .padding(4)
                        .background(ratingColor(for: dish.score))
                        .foregroundColor(.white)
                        .cornerRadius(4)
                }
            }
            .padding(.leading, 5)
        }
        .padding(.vertical, 5)
    }

    // 評価点数に応じた色を返す
    func ratingColor(for score: Int) -> Color {
        switch score {
        case 0...20: return .red
        case 21...40: return .orange
        case 41...60: return .yellow
        case 61...80: return .green
        default: return .blue
        }
    }
}

struct RestaurantInfoSection: View {
    @ObservedRealmObject var restaurant: Restaurant

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("詳細情報")
                .font(.headline)

            if let url = restaurant.url, !url.isEmpty {
                HStack {
                    Image(systemName: "link")
                        .frame(width: 25)

                    Link(url, destination: URL(string: url) ?? URL(string: "https://example.com")!)
                        .lineLimit(1)
                }
            }

            HStack {
                Image(systemName: "number")
                    .frame(width: 25)

                Text("訪問回数: \(restaurant.visitCount)回")
            }

            if let businessHours = restaurant.businessHours, !businessHours.isEmpty {
                HStack {
                    Image(systemName: "clock")
                        .frame(width: 25)

                    Text("営業時間: \(businessHours)")
                }
            }

            HStack {
                Image(systemName: "calendar")
                    .frame(width: 25)

                Text("登録日: \(formattedDate(restaurant.registrationDate))")
            }

            if let memo = restaurant.memo, !memo.isEmpty {
                VStack(alignment: .leading, spacing: 5) {
                    Text("メモ")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text(memo)
                        .font(.body)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                .padding(.top, 5)
            }
        }
    }

    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}

// MARK: - レストラン登録/編集フォーム

enum FormMode {
    case add
    case edit
}

struct RestaurantFormView: View {
    var mode: FormMode
    var existingRestaurant: Restaurant?

    @State private var name: String = ""
    @State private var genre: String = ""
    @State private var address: String = ""
    @State private var url: String = ""
    @State private var memo: String = ""
    @State private var businessHours: String = ""
    @State private var isFavorite: Bool = false
    @State private var visitCount: Int = 0
    @State private var showingGenrePicker = false

    @ObservedResults(Category.self) var restaurantCategories
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        Form {
            Section(header: Text("基本情報")) {
                TextField("レストラン名", text: $name)

                HStack {
                    Text("ジャンル")
                    Spacer()
                    Text(genre.isEmpty ? "選択してください" : genre)
                        .foregroundColor(genre.isEmpty ? .gray : .primary)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    showingGenrePicker = true
                }

                TextField("住所", text: $address)
                TextField("URL", text: $url)
                TextField("営業時間", text: $businessHours)
            }

            Section(header: Text("追加情報")) {
                Toggle(isOn: $isFavorite) {
                    Text("お気に入り")
                }

                Stepper("訪問回数: \(visitCount)", value: $visitCount, in: 0...100)

                VStack(alignment: .leading) {
                    Text("メモ")
                    TextEditor(text: $memo)
                        .frame(minHeight: 100)
                }
            }

            Section {
                Button(action: saveRestaurant) {
                    Text(mode == .add ? "レストランを追加" : "変更を保存")
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .sheet(isPresented: $showingGenrePicker) {
            GenrePickerView(selectedGenre: $genre, genres: Array(restaurantCategories.filter { $0.type == "restaurant" }))
        }
        .onAppear {
            if mode == .edit, let restaurant = existingRestaurant {
                // 既存データを読み込む
                name = restaurant.name
                genre = restaurant.genre
                address = restaurant.address
                url = restaurant.url ?? ""
                memo = restaurant.memo ?? ""
                businessHours = restaurant.businessHours ?? ""
                isFavorite = restaurant.isFavorite
                visitCount = restaurant.visitCount
            }
        }
    }

    func saveRestaurant() {
        if mode == .add {
            // 新規レストランを作成
            let newRestaurant = Restaurant(name: name, genre: genre, address: address)
            newRestaurant.url = url.isEmpty ? nil : url
            newRestaurant.memo = memo.isEmpty ? nil : memo
            newRestaurant.businessHours = businessHours.isEmpty ? nil : businessHours
            newRestaurant.isFavorite = isFavorite
            newRestaurant.visitCount = visitCount

            DataManager.shared.saveRestaurant(restaurant: newRestaurant)
        } else if mode == .edit, let restaurant = existingRestaurant {
            // 既存レストランを更新
            let realm = try! Realm()
            try! realm.write {
                restaurant.name = name
                restaurant.genre = genre
                restaurant.address = address
                restaurant.url = url.isEmpty ? nil : url
                restaurant.memo = memo.isEmpty ? nil : memo
                restaurant.businessHours = businessHours.isEmpty ? nil : businessHours
                restaurant.isFavorite = isFavorite
                restaurant.visitCount = visitCount
                restaurant.lastUpdateDate = Date()
            }
        }

        presentationMode.wrappedValue.dismiss()
    }
}

struct GenrePickerView: View {
    @Binding var selectedGenre: String
    let genres: [Category]  // Array<Category>型に変更
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            List {
                ForEach(genres) { category in
                    Button(action: {
                        selectedGenre = category.name
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            Text(category.name)
                            Spacer()
                            if selectedGenre == category.name {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            .navigationTitle("ジャンルを選択")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - 料理一覧画面

struct DishListView: View {
    @ObservedResults(Restaurant.self) var restaurants
    @State private var searchText = ""
    @State private var selectedCategory: String? = nil
    @ObservedResults(Category.self) var dishCategories

    var allDishes: [Dish] {
        var dishes: [Dish] = []
        for restaurant in restaurants {
            dishes.append(contentsOf: restaurant.dishes)
        }
        return dishes
    }

    var filteredDishes: [Dish] {
        if searchText.isEmpty && selectedCategory == nil {
            return allDishes
        } else if !searchText.isEmpty && selectedCategory == nil {
            return allDishes.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        } else if searchText.isEmpty && selectedCategory != nil {
            return allDishes.filter { $0.category == selectedCategory }
        } else {
            return allDishes.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) && $0.category == selectedCategory
            }
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                // カテゴリフィルター
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        GenreFilterButton(title: "すべて", isSelected: selectedCategory == nil) {
                            selectedCategory = nil
                        }

                        ForEach(dishCategories.filter { $0.type == "dish" }) { category in
                            GenreFilterButton(title: category.name, isSelected: selectedCategory == category.name) {
                                selectedCategory = category.name
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                // 料理リスト
                List {
                    ForEach(filteredDishes) { dish in
                        NavigationLink(destination: DishDetailView(dish: dish)) {
                            DishListRow(dish: dish)
                        }
                    }
                }
                .searchable(text: $searchText, prompt: "料理名で検索")
            }
            .navigationTitle("料理一覧")
        }
    }
}

struct DishListRow: View {
    var dish: Dish

    var body: some View {
        HStack {
            // 料理画像（プレースホルダー）
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 60, height: 60)
                .cornerRadius(6)
                .overlay(
                    Image(systemName: "photo")
                        .foregroundColor(.gray)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(dish.name)
                    .font(.headline)

                Text(dish.category)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack {
                    Text("¥\(dish.price)")
                        .font(.caption)

                    Spacer()

                    Text("\(dish.score)点")
                        .font(.caption)
                        .padding(3)
                        .background(ratingColor(for: dish.score))
                        .foregroundColor(.white)
                        .cornerRadius(4)
                }
            }
            .padding(.leading, 5)

            Spacer()

            // レストラン名を表示
            if !dish.restaurant.isEmpty {
                VStack(alignment: .trailing) {
                    Text(dish.restaurant.first?.name ?? "")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.vertical, 4)
    }

    // 評価点数に応じた色を返す
    func ratingColor(for score: Int) -> Color {
        switch score {
        case 0...20: return .red
        case 21...40: return .orange
        case 41...60: return .yellow
        case 61...80: return .green
        default: return .blue
        }
    }
}

// MARK: - 料理詳細画面

struct DishDetailView: View {
    @ObservedRealmObject var dish: Dish
    @State private var showingEditSheet = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // ヘッダー部分（画像とデータ）
                DishHeaderView(dish: dish)

                Divider()

                // 詳細情報
                DishInfoSection(dish: dish)

                Divider()

                // レストラン情報
                if !dish.restaurant.isEmpty, let restaurant = dish.restaurant.first {
                    RestaurantLinkSection(restaurant: restaurant)
                }

                Spacer(minLength: 50)
            }
            .padding()
        }
        .navigationTitle(dish.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingEditSheet = true
                }) {
                    Text("編集")
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            NavigationView {
                if !dish.restaurant.isEmpty, let restaurant = dish.restaurant.first {
                    DishFormView(mode: .edit, restaurant: restaurant, existingDish: dish)
                        .navigationTitle("料理を編集")
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("閉じる") {
                                    showingEditSheet = false
                                }
                            }
                        }
                }
            }
        }
    }
}

struct DishHeaderView: View {
    @ObservedRealmObject var dish: Dish

    var body: some View {
        VStack {
            // 料理画像（プレースホルダー）
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 200)
                .overlay(
                    Image(systemName: "photo")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                )
                .cornerRadius(10)

            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(dish.name)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(dish.category)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text("¥\(dish.price)")
                        .font(.headline)
                }

                Spacer()

                VStack {
                    Text("\(dish.score)")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("点")
                        .font(.caption)
                }
                .padding()
                .background(ratingColor(for: dish.score))
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
    }

    // 評価点数に応じた色を返す
    func ratingColor(for score: Int) -> Color {
        switch score {
        case 0...20: return .red
        case 21...40: return .orange
        case 41...60: return .yellow
        case 61...80: return .green
        default: return .blue
        }
    }
}

struct DishInfoSection: View {
    @ObservedRealmObject var dish: Dish

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("詳細情報")
                .font(.headline)

            HStack {
                Image(systemName: "number")
                    .frame(width: 25)

                Text("注文回数: \(dish.orderCount)回")
            }

            HStack {
                Image(systemName: "calendar")
                    .frame(width: 25)

                Text("登録日: \(formattedDate(dish.registrationDate))")
            }

            if let memo = dish.memo, !memo.isEmpty {
                VStack(alignment: .leading, spacing: 5) {
                    Text("メモ")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text(memo)
                        .font(.body)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                .padding(.top, 5)
            }
        }
    }

    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}

struct RestaurantLinkSection: View {
    var restaurant: Restaurant

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("提供レストラン")
                .font(.headline)

            NavigationLink(destination: RestaurantDetailView(restaurant: restaurant)) {
                HStack {
                    // レストラン画像（プレースホルダー）
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 50, height: 50)
                        .cornerRadius(6)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(restaurant.name)
                            .font(.headline)

                        Text(restaurant.genre)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

// MARK: - 料理登録/編集フォーム

struct DishFormView: View {
    var mode: FormMode = .add
    var restaurant: Restaurant
    var existingDish: Dish?

    @State private var name: String = ""
    @State private var category: String = ""
    @State private var price: String = ""
    @State private var score: Double = 50
    @State private var memo: String = ""
    @State private var isFavorite: Bool = false
    @State private var orderCount: Int = 1
    @State private var showingCategoryPicker = false

    @ObservedResults(Category.self) var dishCategories
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        Form {
            Section(header: Text("基本情報")) {
                TextField("料理名", text: $name)

                HStack {
                    Text("カテゴリ")
                    Spacer()
                    Text(category.isEmpty ? "選択してください" : category)
                        .foregroundColor(category.isEmpty ? .gray : .primary)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    showingCategoryPicker = true
                }

                TextField("価格", text: $price)
                    .keyboardType(.numberPad)
            }

            Section(header: Text("評価")) {
                VStack {
                    Text("評価: \(Int(score))点")
                        .frame(maxWidth: .infinity, alignment: .center)

                    Slider(value: $score, in: 0...100, step: 1)
                        .accentColor(ratingColor(for: Int(score)))
                }

                Toggle(isOn: $isFavorite) {
                    Text("お気に入り")
                }

                Stepper("注文回数: \(orderCount)", value: $orderCount, in: 1...100)
            }

            Section(header: Text("メモ")) {
                TextEditor(text: $memo)
                    .frame(minHeight: 100)
            }

            Section {
                Button(action: saveDish) {
                    Text(mode == .add ? "料理を追加" : "変更を保存")
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .sheet(isPresented: $showingCategoryPicker) {
            CategoryPickerView(selectedCategory: $category, categories: dishCategories.filter { $0.type == "dish" })
        }
        .onAppear {
            if mode == .edit, let dish = existingDish {
                // 既存データを読み込む
                name = dish.name
                category = dish.category
                price = String(dish.price)
                score = Double(dish.score)
                memo = dish.memo ?? ""
                isFavorite = dish.isFavorite
                orderCount = dish.orderCount
            }
        }
    }

    func saveDish() {
        if mode == .add {
            // 新規料理を作成
            let newDish = Dish(name: name, category: category, price: Int(price) ?? 0, score: Int(score))
            newDish.memo = memo.isEmpty ? nil : memo
            newDish.isFavorite = isFavorite
            newDish.orderCount = orderCount

            DataManager.shared.saveDish(dish: newDish, to: restaurant)
        } else if mode == .edit, let dish = existingDish {
            // 既存料理を更新
            let realm = try! Realm()
            try! realm.write {
                dish.name = name
                dish.category = category
                dish.price = Int(price) ?? 0
                dish.score = Int(score)
                dish.memo = memo.isEmpty ? nil : memo
                dish.isFavorite = isFavorite
                dish.orderCount = orderCount
                dish.lastUpdateDate = Date()
            }
        }

        presentationMode.wrappedValue.dismiss()
    }

    // 評価点数に応じた色を返す
    func ratingColor(for score: Int) -> Color {
        switch score {
        case 0...20: return .red
        case 21...40: return .orange
        case 41...60: return .yellow
        case 61...80: return .green
        default: return .blue
        }
    }
}

struct CategoryPickerView: View {
    @Binding var selectedCategory: String
    let categories: [Category]  // Results<Category>からArray<Category>に変更
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            List {
                ForEach(categories) { category in
                    Button(action: {
                        selectedCategory = category.name
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            Text(category.name)
                            Spacer()
                            if selectedCategory == category.name {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            .navigationTitle("カテゴリを選択")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - 設定画面

struct SettingsView: View {
    @ObservedResults(UserPreferences.self) var preferences
    @State private var selectedTheme = "system"
    @State private var selectedSortOrder = "name"

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("表示設定")) {
                    Picker("テーマ", selection: $selectedTheme) {
                        Text("システム設定に合わせる").tag("system")
                        Text("ライトモード").tag("light")
                        Text("ダークモード").tag("dark")
                    }
                    .pickerStyle(DefaultPickerStyle())

                    Picker("デフォルト並び順", selection: $selectedSortOrder) {
                        Text("名前順").tag("name")
                        Text("登録日順").tag("date")
                        Text("評価順").tag("rating")
                    }
                    .pickerStyle(DefaultPickerStyle())
                }

                Section(header: Text("データ管理")) {
                    Button(action: {
                        // カテゴリ管理画面に遷移
                    }) {
                        Text("カテゴリ管理")
                    }

                    Button(action: {
                        // データバックアップ処理
                    }) {
                        Text("データのバックアップ")
                    }

                    Button(action: {
                        // データリストア処理
                    }) {
                        Text("データの復元")
                    }
                }

                Section(header: Text("アプリ情報")) {
                    HStack {
                        Text("バージョン")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.gray)
                    }

                    Button(action: {
                        // プライバシーポリシー表示
                    }) {
                        Text("プライバシーポリシー")
                    }

                    Button(action: {
                        // 利用規約表示
                    }) {
                        Text("利用規約")
                    }
                }
            }
            .navigationTitle("設定")
            .onChange(of: selectedTheme) { oldValue, newValue in
                savePreferences()
            }
            .onChange(of: selectedSortOrder) { oldValue, newValue in
                savePreferences()
            }
            .onAppear {
                // 設定データの読み込み
                if let userPreferences = preferences.first {
                    selectedTheme = userPreferences.theme
                    selectedSortOrder = userPreferences.defaultSortOrder
                }
            }
        }
    }

    func savePreferences() {
        let realm = try! Realm()

        if let userPreferences = preferences.first {
            try! realm.write {
                userPreferences.theme = selectedTheme
                userPreferences.defaultSortOrder = selectedSortOrder
            }
        } else {
            // 初期設定の作成
            let newPreferences = UserPreferences(defaultSortOrder: selectedSortOrder, theme: selectedTheme)
            try! realm.write {
                realm.add(newPreferences)
            }
        }
    }
}
