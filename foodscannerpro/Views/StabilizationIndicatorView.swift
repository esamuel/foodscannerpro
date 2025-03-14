import SwiftUI
import CoreMotion

class StabilizationManager: ObservableObject {
    private let motionManager = CMMotionManager()
    @Published var isStable = false
    @Published var stabilityPercentage: Double = 0
    
    private let stabilityThreshold: Double = 0.05
    private var timer: Timer?
    
    init() {
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    func startMonitoring() {
        guard motionManager.isDeviceMotionAvailable else { return }
        
        motionManager.deviceMotionUpdateInterval = 0.1
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] (motion, error) in
            guard let self = self, let motion = motion, error == nil else { return }
            
            // Calculate total acceleration magnitude
            let x = motion.userAcceleration.x
            let y = motion.userAcceleration.y
            let z = motion.userAcceleration.z
            
            let totalAcceleration = sqrt(x*x + y*y + z*z)
            
            // Calculate stability percentage (inverse of acceleration)
            let stability = max(0, min(1, 1 - (totalAcceleration / self.stabilityThreshold)))
            self.stabilityPercentage = stability
            
            // Device is considered stable if acceleration is below threshold
            self.isStable = totalAcceleration < self.stabilityThreshold
        }
    }
    
    func stopMonitoring() {
        motionManager.stopDeviceMotionUpdates()
        timer?.invalidate()
        timer = nil
    }
}

struct StabilizationIndicatorView: View {
    @ObservedObject var stabilizationManager: StabilizationManager
    var isVisible: Bool
    
    var body: some View {
        if isVisible {
            VStack {
                HStack {
                    Spacer()
                    
                    VStack(spacing: 5) {
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .frame(width: 100, height: 8)
                                .opacity(0.3)
                                .cornerRadius(4)
                            
                            Rectangle()
                                .frame(width: 100 * CGFloat(stabilizationManager.stabilityPercentage), height: 8)
                                .foregroundColor(stabilizationManager.isStable ? Color.green : Color.orange)
                                .cornerRadius(4)
                        }
                        
                        Text(stabilizationManager.isStable ? "Stable" : "Hold Steady")
                            .font(.caption)
                            .foregroundColor(stabilizationManager.isStable ? .green : .orange)
                    }
                    .padding(8)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(8)
                    .padding(.trailing, 16)
                }
                
                Spacer()
            }
            .padding(.top, 16)
        }
    }
}

struct StabilizationIndicatorView_Previews: PreviewProvider {
    static var previews: some View {
        StabilizationIndicatorView(stabilizationManager: StabilizationManager(), isVisible: true)
            .background(Color.black.opacity(0.3))
            .previewLayout(.sizeThatFits)
    }
} 