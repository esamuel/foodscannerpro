import SwiftUI
import Charts
import UIKit

enum TimeRange: String, CaseIterable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
    case year = "Year"
    
    var calendarComponent: Calendar.Component {
        switch self {
        case .day:
            return .hour
        case .week:
            return .day
        case .month:
            return .day
        case .year:
            return .month
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct StatisticView: View {
    let value: Double
    let label: String
    let color: Color
    
    var body: some View {
        VStack {
            Text("\(Int(value))%")
                .font(.title)
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct FeedbackAnalysisView: View {
    @EnvironmentObject var feedbackManager: FeedbackManager
    @State private var showingExportSheet = false
    @State private var exportURL: URL? = nil
    
    var body: some View {
        // Simplified view to avoid type-checking issues
        NavigationView {
            VStack {
                Text("Feedback Analysis")
                    .font(.title)
                    .padding()
                
                Text("This feature is temporarily disabled")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .navigationTitle("Feedback Analysis")
        }
    }
}

struct FeedbackAnalysisView_Previews: PreviewProvider {
    static var previews: some View {
        FeedbackAnalysisView()
            .environmentObject(FeedbackManager())
    }
} 