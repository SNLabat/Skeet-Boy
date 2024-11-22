import SwiftUI

struct ContentView: View {
    @StateObject private var authModel = AuthModel()
    
    var body: some View {
        ZStack {
            // Background
            Color.black.edgesIgnoringSafeArea(.all)
            
            if authModel.isAuthenticated {
                MainContainerView(authModel: authModel)
            } else {
                LoginView(authModel: authModel)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            authModel.getStoredCredentials()
        }
    }
}

#Preview {
    ContentView()
}
