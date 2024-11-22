import SwiftUI
import AVFoundation

// Add UserSettings class
final class UserSettings: ObservableObject {
    @Published var isSoundEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isSoundEnabled, forKey: "isSoundEnabled")
        }
    }
    @Published var isCRTModeEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isCRTModeEnabled, forKey: "isCRTModeEnabled")
        }
    }
    
    init() {
        self.isSoundEnabled = UserDefaults.standard.bool(forKey: "isSoundEnabled", defaultValue: true)
        self.isCRTModeEnabled = UserDefaults.standard.bool(forKey: "isCRTModeEnabled", defaultValue: false)
    }
}

// Add UserDefaults extension
extension UserDefaults {
    func bool(forKey defaultName: String, defaultValue: Bool) -> Bool {
        if object(forKey: defaultName) == nil {
            set(defaultValue, forKey: defaultName)
            return defaultValue
        }
        return bool(forKey: defaultName)
    }
}

// Add CRTOverlay view
struct CRTOverlay: View {
    var body: some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.green.opacity(0.1),
                            Color.green.opacity(0.05)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.black.opacity(0.3), Color.black.opacity(0.1)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
            
            // Scanlines
            VStack(spacing: 2) {
                ForEach(0..<Int(geometry.size.height/2), id: \.self) { _ in
                    Color.black.opacity(0.1)
                        .frame(height: 1)
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// Add SettingsView
struct SettingsView: View {
    @ObservedObject var settings: UserSettings
    @ObservedObject var authModel: AuthModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("Interface") {
                    Toggle("CRT Mode", isOn: $settings.isCRTModeEnabled)
                    Toggle("Sound Effects", isOn: $settings.isSoundEnabled)
                    Button(role: .destructive) {
                        authModel.logout()
                        dismiss()
                    } label: {
                        Text("Logout")
                    }
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

struct MainTabBar: View {
    let systemImage: String
    let isSelected: Bool
    
    var body: some View {
        Image(systemName: systemImage)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 24, height: 24)
            .foregroundColor(isSelected ? .green : .green.opacity(0.5))
    }
}

struct MainContainerView: View {
    @ObservedObject var authModel: AuthModel
    @StateObject private var settings = UserSettings()
    @State private var selectedTab = 0
    @State private var audioPlayer: AVAudioPlayer?
    @State private var showSettings = false
    
    func playSound() {
        guard settings.isSoundEnabled else { return }
        guard let soundURL = Bundle.main.url(forResource: "ui_skeetboy_select", withExtension: "wav") else { return }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.play()
        } catch {
            print("Error playing sound: \(error)")
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                TimelineView(authModel: authModel)
                    .tag(0)
                
                SearchView(authModel: authModel)
                    .tag(1)
                
                ChatView(authModel: authModel)
                    .tag(2)
                
                NotificationView(authModel: authModel)
                    .tag(3)
                
                ProfileView(
                    did: UserDefaults.standard.string(forKey: "userDID") ?? "",
                    handle: UserDefaults.standard.string(forKey: "handle") ?? ""
                )
                .tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .overlay(
                Button(action: {
                    showSettings = true
                }) {
                    Image(systemName: "display")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                        .foregroundColor(.green)
                        .padding()
                }
                .sheet(isPresented: $showSettings) {
                    SettingsView(settings: settings, authModel: authModel)
                }
                , alignment: .topTrailing
            )
            
            if settings.isCRTModeEnabled {
                CRTOverlay()
            }
            
            // Custom Tab Bar
            HStack(spacing: 0) {
                ForEach(0..<5) { index in
                    Button(action: {
                        playSound()
                        selectedTab = index
                    }) {
                        switch index {
                        case 0:
                            MainTabBar(systemImage: "house.fill", isSelected: selectedTab == index)
                        case 1:
                            MainTabBar(systemImage: "magnifyingglass", isSelected: selectedTab == index)
                        case 2:
                            MainTabBar(systemImage: "bubble.left.fill", isSelected: selectedTab == index)
                        case 3:
                            MainTabBar(systemImage: "bell.fill", isSelected: selectedTab == index)
                        case 4:
                            MainTabBar(systemImage: "person.fill", isSelected: selectedTab == index)
                        default:
                            EmptyView()
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.95))
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.green.opacity(0.3)),
                alignment: .top
            )
        }
    }
}

#Preview {
    MainContainerView(authModel: AuthModel())
        .preferredColorScheme(.dark)
}
