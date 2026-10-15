//
//  ContentView.swift
//  SubTracker
//
//  Created by Karol on 02/05/2026.
//

import SwiftUI
import SwiftData
import UserNotifications
import Charts

// MARK: - MODEL
@Model
class Subscription {
    var id: String
    var name: String
    var price: Double
    var renewalDate: Date
    var category: String
    var recurrence: String
    var createdAt: Date
    
    init(name: String, price: Double, renewalDate: Date, category: String, recurrence: String) {
        self.id = UUID().uuidString
        self.name = name
        self.price = price
        self.renewalDate = renewalDate
        self.category = category
        self.recurrence = recurrence
        self.createdAt = Date()
    }
    
    var monthlyCost: Double {
        switch recurrence {
        case "Weekly": return (price * 52.0) / 12.0
        case "Yearly": return price / 12.0
        default: return price
        }
    }
    
    var daysLeft: Int {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let startOfRenewal = calendar.startOfDay(for: renewalDate)
        return calendar.dateComponents([.day], from: startOfToday, to: startOfRenewal).day ?? 0
    }
}

// MARK: - HAPTICS
struct Haptics {
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    static func lightClick() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}

// MARK: - ONBOARDING VIEW (INSTRUKCJA)
struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @Environment(\.colorScheme) var colorScheme
    
    var themeAccent: Color { colorScheme == .dark ? Color(hex: "FF4C4C") : Color(hex: "8A1C1C") }
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            VStack(spacing: 15) {
                Image("logo") // Używa Twojego logo z Assets!
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                Text("Welcome to SubTracker")
                    .font(.largeTitle)
                    .bold()
                    .multilineTextAlignment(.center)
            }
            
            VStack(alignment: .leading, spacing: 30) {
                FeatureRow(icon: "plus.circle.fill", title: "Manage Subscriptions", desc: "Add your recurring expenses and never lose track of your money.")
                FeatureRow(icon: "hand.draw.fill", title: "Smart Payments", desc: "Swipe right to mark as paid. We'll automatically calculate the next date.")
                FeatureRow(icon: "chart.pie.fill", title: "Visual Analytics", desc: "Check your spending habits on beautiful, interactive charts.")
            }
            .padding(.horizontal, 30)
            
            Spacer()
            
            Button(action: {
                Haptics.success()
                hasSeenOnboarding = true // Zamyka ekran na zawsze
            }) {
                Text("Get Started")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(themeAccent)
                    .cornerRadius(15)
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 50)
        }
    }
}

struct FeatureRow: View {
    var icon: String
    var title: String
    var desc: String
    @Environment(\.colorScheme) var colorScheme
    var themeAccent: Color { colorScheme == .dark ? Color(hex: "FF4C4C") : Color(hex: "8A1C1C") }
    
    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundColor(themeAccent)
                .frame(width: 50)
            VStack(alignment: .leading, spacing: 4) {
                Text(LocalizedStringKey(title)).font(.headline)
                Text(LocalizedStringKey(desc)).font(.subheadline).foregroundColor(.gray)
            }
        }
    }
}

// MARK: - MAIN VIEW
struct ContentView: View {
    @AppStorage("chartMode") private var chartMode = "Categories"
    @AppStorage("sortOption") private var sortOption = "Date"
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    
    var body: some View {
        TabView {
            SubscriptionListView(sortOption: sortOption)
                .tabItem { Label("List", systemImage: "list.bullet") }
            
            AnalyticsView(chartMode: chartMode)
                .tabItem { Label("Analysis", systemImage: "chart.pie.fill") }
            
            SettingsView(chartMode: $chartMode, sortOption: $sortOption)
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .fullScreenCover(isPresented: Binding(get: { !hasSeenOnboarding }, set: { _ in })) {
            OnboardingView()
        }
    }
}

// MARK: - LIST VIEW
struct SubscriptionListView: View {
    @Query var mySubscriptions: [Subscription]
    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) var colorScheme
    
    @State private var showingAddView = false
    @State private var isHeaderExpanded = false
    @State private var selectedFilter = "All"
    
    @AppStorage("currency") private var currency = "PLN"
    
    var sortOption: String
    
    var processedSubscriptions: [Subscription] {
        let filtered = mySubscriptions.filter { sub in
            selectedFilter == "All" ? true : sub.category == selectedFilter
        }
        switch sortOption {
        case "Price": return filtered.sorted { $0.price > $1.price }
        case "Name": return filtered.sorted { $0.name < $1.name }
        default: return filtered.sorted { $0.renewalDate < $1.renewalDate }
        }
    }
    
    var groupedSubscriptions: [String: [Subscription]] { Dictionary(grouping: processedSubscriptions, by: { $0.category }) }
    var subscriptionsByRecurrence: [String: [Subscription]] { Dictionary(grouping: mySubscriptions, by: { $0.recurrence }) }
    var totalSum: Double { mySubscriptions.reduce(0) { $0 + $1.monthlyCost } }
    
    var themeAccent: Color { colorScheme == .dark ? Color(hex: "FF4C4C") : Color(hex: "8A1C1C") }
    var themeBg: Color { colorScheme == .dark ? Color(hex: "18181B") : Color(hex: "F4F1EA") }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    Button(action: {
                        Haptics.lightClick()
                        withAnimation(.spring()) { isHeaderExpanded.toggle() }
                    }) {
                        HStack {
                            Text("Total Monthly:").foregroundColor(.gray)
                            Spacer()
                            Text("\(String(format: "%.2f", totalSum)) \(currency)").font(.title2).bold().foregroundColor(themeAccent)
                            Image(systemName: "chevron.right").rotationEffect(.degrees(isHeaderExpanded ? 90 : 0)).foregroundColor(.gray).padding(.leading, 5)
                        }.padding()
                    }
                    if isHeaderExpanded {
                        VStack(spacing: 12) {
                            Divider().padding(.horizontal)
                            ForEach(subscriptionsByRecurrence.keys.sorted(), id: \.self) { rec in
                                // POPRAWKA: Używamy bezpiecznego ( ... ?? [] ) zamiast wykrzyknika
                                let recSum = (subscriptionsByRecurrence[rec] ?? []).reduce(0) { $0 + $1.monthlyCost }
                                HStack {
                                    Text(LocalizedStringKey(rec)).font(.subheadline)
                                    Spacer()
                                    Text("\(String(format: "%.2f", recSum)) \(currency) / mo").font(.subheadline).bold()
                                }.padding(.horizontal)
                            }
                        }.padding(.bottom, 15)
                    }
                }
                .background(themeBg).cornerRadius(15).padding(.horizontal).padding(.top, 10).padding(.bottom, 15)
                
                List {
                    ForEach(groupedSubscriptions.keys.sorted(), id: \.self) { categoryName in
                        Section(header: Text(LocalizedStringKey(categoryName)).bold()) {
                            // POPRAWKA: Używamy bezpiecznego ( ... ?? [] ) zamiast wykrzyknika
                            ForEach(groupedSubscriptions[categoryName] ?? []) { sub in
                                SubscriptionRow(sub: sub, accent: themeAccent)
                                    .swipeActions(edge: .leading) {
                                        Button {
                                            Haptics.success()
                                            markAsPaid(sub)
                                        } label: { Label("Paid", systemImage: "checkmark") }.tint(.green)
                                    }
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            // Dodatkowa mała wibracja przy usuwaniu
                                            Haptics.lightClick()
                                            context.delete(sub)
                                        } label: { Label("Delete", systemImage: "trash") }
                                    }
                            }
                        }
                    }
                }.listStyle(.insetGrouped)
            }
            .navigationTitle("SubTracker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack {
                        Menu {
                            Button("All") { selectedFilter = "All" }
                            Divider()
                            let categories = Set(mySubscriptions.map { $0.category }).sorted()
                            ForEach(categories, id: \.self) { cat in
                                Button(LocalizedStringKey(cat)) { selectedFilter = cat }
                            }
                        } label: {
                            Image(systemName: selectedFilter == "All" ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                                .foregroundColor(themeAccent)
                        }
                        Button(action: { showingAddView = true }) {
                            Image(systemName: "plus.circle.fill").font(.title3).foregroundColor(themeAccent)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddView) { AddSubscriptionView() }
        }
    }
    
    func markAsPaid(_ sub: Subscription) {
        let calendar = Calendar.current
        var comp: Calendar.Component = .month
        if sub.recurrence == "Weekly" { comp = .weekday }
        if sub.recurrence == "Yearly" { comp = .year }
        if let next = calendar.date(byAdding: comp, value: 1, to: sub.renewalDate) {
            sub.renewalDate = next
        }
    }
}

// MARK: - ANALYTICS VIEW
struct AnalyticsView: View {
    @Query var subscriptions: [Subscription]
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("currency") private var currency = "EUR"
    
    var chartMode: String
    
    var categoryChartData: [(category: String, total: Double)] {
        Dictionary(grouping: subscriptions, by: { $0.category }).map { ($0.key, $0.value.reduce(0) { $0 + $1.monthlyCost }) }.sorted { $0.total > $1.total }
    }
    var themeAccent: Color { colorScheme == .dark ? Color(hex: "FF4C4C") : Color(hex: "8A1C1C") }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 30) {
                    if subscriptions.isEmpty {
                        Text("No data").padding().foregroundColor(.gray)
                    } else {
                        Chart {
                            if chartMode == "Categories" {
                                ForEach(categoryChartData, id: \.category) { item in
                                    SectorMark(angle: .value("Amount", item.total), innerRadius: .ratio(0.65), angularInset: 2)
                                        .foregroundStyle(by: .value("Category", item.category))
                                }
                            } else {
                                ForEach(subscriptions) { sub in
                                    SectorMark(angle: .value("Amount", sub.monthlyCost), innerRadius: .ratio(0.65), angularInset: 1)
                                        .foregroundStyle(by: .value("Category", sub.category))
                                        .annotation(position: .overlay) { Text(sub.name).font(.system(size: 10)).bold().foregroundColor(.white) }
                                }
                            }
                        }
                        .frame(height: 300).padding(.top, 20).chartLegend(Visibility.hidden)
                        
                        if chartMode == "Categories" {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 20) {
                                    ForEach(categoryChartData, id: \.category) { item in
                                        HStack(spacing: 6) {
                                            Circle().fill(themeAccent).frame(width: 12, height: 12)
                                            Text(LocalizedStringKey(item.category)).font(.footnote).bold()
                                            Text("\(String(format: "%.0f", item.total))").font(.footnote).foregroundColor(.gray)
                                        }
                                    }
                                }.padding(.horizontal)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 0) {
                            Text("PAYMENT RANKING").font(.caption2).tracking(1.5).foregroundColor(.gray).padding(.leading).padding(.top, 10).padding(.bottom, 10)
                            ForEach(subscriptions.sorted(by: { $0.price > $1.price })) { sub in
                                HStack {
                                    Text(sub.name).font(.headline)
                                    Spacer()
                                    Text("\(String(format: "%.2f", sub.price)) \(currency)").bold().foregroundColor(themeAccent)
                                }.padding().background(Color.gray.opacity(0.05)).cornerRadius(10).padding(.horizontal).padding(.bottom, 5)
                            }
                        }
                    }
                }
            }
            .navigationTitle("SubTracker")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - ADD VIEW
struct AddSubscriptionView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \Subscription.createdAt, order: .reverse) var allSubs: [Subscription]
    
    @State private var name = ""
    @State private var price = ""
    @State private var date = Date()
    @State private var selectedCategory = ""
    @State private var customCategory = ""
    @State private var recurrence = "Monthly"
    
    var dynamicCategories: [String] {
        let base = ["Entertainment", "Work", "Health", "Home", "Education"]
        let used = Set(allSubs.map { $0.category })
        var combined = Array(Set(base).union(used)).sorted()
        if let last = allSubs.first?.category {
            combined.removeAll { $0 == last }
            combined.insert(last, at: 0)
        }
        combined.append("Custom...")
        return combined
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Basics") {
                    TextField("Name", text: $name)
                    TextField("Price", text: $price).keyboardType(.decimalPad)
                    DatePicker("Payment Date", selection: $date, displayedComponents: .date)
                }
                Section("Logic") {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(dynamicCategories, id: \.self) { cat in
                            HStack {
                                if cat == allSubs.first?.category { Image(systemName: "clock.arrow.circlepath") }
                                Text(LocalizedStringKey(cat))
                            }.tag(cat)
                        }
                    }
                    if selectedCategory == "Custom..." { TextField("Custom category name", text: $customCategory) }
                    Picker("Billing Cycle", selection: $recurrence) {
                        ForEach(["Weekly", "Monthly", "Yearly"], id: \.self) { Text(LocalizedStringKey($0)) }
                    }
                }
            }
            .onAppear { if selectedCategory.isEmpty { selectedCategory = dynamicCategories.first ?? "Entertainment" } }
            .navigationTitle("Add New")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("Save") {
                    let safePrice = price.replacingOccurrences(of: ",", with: ".")
                    if let p = Double(safePrice) {
                        Haptics.success()
                        let cat = selectedCategory == "Custom..." ? customCategory : selectedCategory
                        let new = Subscription(name: name, price: p, renewalDate: date, category: cat, recurrence: recurrence)
                        context.insert(new)
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - SETTINGS (TERAZ Z WYBOREM WALUTY)
struct SettingsView: View {
    @Binding var chartMode: String
    @Binding var sortOption: String
    @AppStorage("currency") private var currency = "EUR"
    
    var body: some View {
        NavigationStack {
            List {
                Section("Analytics Preferences") {
                    Picker("Chart Grouping", selection: $chartMode) {
                        Text("Categories").tag("Categories")
                        Text("Individual").tag("Subscriptions")
                    }.pickerStyle(.segmented)
                }
                Section("List Order") {
                    Picker("Sort subscriptions by:", selection: $sortOption) {
                        Text("Payment Date").tag("Date")
                        Text("Price (Highest first)").tag("Price")
                        Text("Name (A-Z)").tag("Name")
                    }
                }
                Section("Currency") {
                    Picker("Default Currency", selection: $currency) {
                        Text("PLN (zł)").tag("PLN")
                        Text("EUR (€)").tag("EUR")
                        Text("USD ($)").tag("USD")
                        Text("GBP (£)").tag("GBP")
                    }
                }
                Section("System") {
                    HStack { Text("Version"); Spacer(); Text("2.1.0").foregroundColor(.gray) }
                }
            }
            .navigationTitle("SubTracker")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - ROW
struct SubscriptionRow: View {
    let sub: Subscription
    let accent: Color
    @AppStorage("currency") private var currency = "EUR"
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(sub.name).font(.headline)
                Text(sub.daysLeft >= 0 ? "In \(sub.daysLeft) days" : "Overdue").font(.caption).foregroundColor(sub.daysLeft >= 0 ? .blue : .red)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text("\(String(format: "%.2f", sub.price)) \(currency)").bold().foregroundColor(accent)
                Text(LocalizedStringKey(sub.recurrence)).font(.caption2).foregroundColor(.gray)
            }
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue:  Double(b) / 255, opacity: Double(a) / 255)
    }
}
