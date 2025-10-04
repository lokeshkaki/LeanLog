//
//  SettingsView.swift
//  LeanLog
//
//  Created by Lokesh Kaki on 9/21/25.
//  Updated: Removed Daily Goals (now in Goals tab), clean settings only
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            Form {
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Developer")
                        Spacer()
                        Text("LeanLog Team")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("App")
                        Spacer()
                        Text("LeanLog")
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section("Data") {
                    Button("Export All Data") {
                        // Export functionality
                    }
                    .foregroundStyle(.blue)
                    
                    Button("Clear All Data") {
                        // Clear data functionality with confirmation
                    }
                    .foregroundStyle(.red)
                }
                
                Section {
                    Link(destination: URL(string: "https://github.com/LightYagamiTheDev/LeanLog")!) {
                        HStack {
                            Text("Source Code")
                            Spacer()
                            Image(systemName: "arrow.up.forward.square")
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Link(destination: URL(string: "https://github.com/LightYagamiTheDev/LeanLog/issues")!) {
                        HStack {
                            Text("Report Issue")
                            Spacer()
                            Image(systemName: "arrow.up.forward.square")
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Support")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Settings")
                        .font(AppTheme.Typography.title3)
                        .foregroundStyle(AppTheme.Colors.labelPrimary)
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
