import SwiftUI

/// A badge-style view for displaying nutrition information
struct NutritionBadge: View {
    let label: String
    let value: String
    var icon: String? = nil
    
    var body: some View {
        VStack(spacing: 4) {
            if let icon = icon {
                HStack(spacing: 4) {
                    Image(systemName: icon)
                        .font(.system(size: 12))
                    Text(value)
                        .font(.system(size: 14, weight: .semibold))
                }
            } else {
                Text(value)
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.semibold)
            }
            
            Text(label)
                .font(icon == nil ? .caption : .system(size: 12))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: icon == nil ? .infinity : nil)
        .padding(.vertical, icon == nil ? 8 : 0)
        .background(icon == nil ? Color(.systemGray6) : Color.clear)
        .cornerRadius(icon == nil ? 8 : 0)
    }
} 