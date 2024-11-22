import SwiftUI

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