//
//  ContentView.swift
//  Plan4Retirement
//
//  Created by Gilbert Hong on 7/14/26.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab: TabItem = .dataInput

    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Data Input
            DataInputView()
                .tabItem {
                    Label("Data Input", systemImage: "pencil.and.list.clipboard")
                }
                .tag(TabItem.dataInput)

            // Tab 2: Assumptions
            AssumptionsView()
                .tabItem {
                    Label("Assumptions", systemImage: "slider.horizontal.3")
                }
                .tag(TabItem.assumptions)

            // Tab 3: Dashboard
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "gauge")
                }
                .tag(TabItem.dashboard)

            // Tab 4: Projections
            ProjectionsView()
                .tabItem {
                    Label("Projections", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(TabItem.projections)

            // Tab 5: Settings
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(TabItem.settings)
        }
    }
}

enum TabItem {
    case dataInput
    case assumptions
    case dashboard
    case projections
    case settings
}

#Preview {
    ContentView()
        .environmentObject(SettingsService())
}
