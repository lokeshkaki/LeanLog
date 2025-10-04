//
//  MainTabView.swift
//  LeanLog
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @Query private var profiles: [UserProfile]
    
    @State private var selectedTab = 0
    
    private var hasCompletedGoals: Bool {
        profiles.first?.isOnboardingComplete ?? false
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            GoalsView()
                .tabItem {
                    Label("Goals", systemImage: "target")
                }
                .tag(0)
            
            MealsView()
                .tabItem {
                    Label("Meals", systemImage: "fork.knife")
                }
                .tag(1)
            
            HomeView()
                .tabItem {
                    Label("Logs", systemImage: "list.clipboard")
                }
                .tag(2)
            
            WeeklyView()
                .tabItem {
                    Label("Progress", systemImage: "chart.bar")
                }
                .tag(3)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(4)
        }
        .onAppear {
            // Default to Goals if not set, otherwise Logs
            selectedTab = hasCompletedGoals ? 2 : 0
        }
    }
}
