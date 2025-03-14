import SwiftUI

struct GridOverlayView: View {
    var isVisible: Bool
    
    var body: some View {
        if isVisible {
            ZStack {
                // Vertical lines
                ForEach(1..<3) { index in
                    Rectangle()
                        .fill(Color.white.opacity(0.5))
                        .frame(width: 1)
                        .position(x: UIScreen.main.bounds.width / 3 * CGFloat(index), y: UIScreen.main.bounds.height / 2)
                }
                
                // Horizontal lines
                ForEach(1..<3) { index in
                    Rectangle()
                        .fill(Color.white.opacity(0.5))
                        .frame(height: 1)
                        .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 3 * CGFloat(index))
                }
            }
        }
    }
}

struct GridOverlayView_Previews: PreviewProvider {
    static var previews: some View {
        GridOverlayView(isVisible: true)
            .background(Color.black)
            .previewLayout(.sizeThatFits)
    }
} 