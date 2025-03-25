import SwiftUI

struct NutritionRow: View {
    let title: String
    let value: String
    var unit: String?
    
    init(title: String, value: String, unit: String? = nil) {
        self.title = title
        self.value = value
        self.unit = unit
    }
    
    init(title: String, value: Int, unit: String) {
        self.title = title
        self.value = "\(value)"
        self.unit = unit
    }
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .fontWeight(.medium)
                if let unit = unit {
                    Text(unit)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .font(.subheadline)
    }
} 