import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: UserSettings
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("Interface") {
                    Toggle("CRT Mode", isOn: $settings.isCRTModeEnabled)
                    Toggle("Sound Effects", isOn: $settings.isSoundEnabled)
                }
                
                Section("About") {
                    Text("Version 1.0.0")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
} 