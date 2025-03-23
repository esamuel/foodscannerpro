import SwiftUI

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

struct HistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \FoodRecognitionHistory.timestamp, ascending: false)],
        animation: .default)
    private var historyItems: FetchedResults<FoodRecognitionHistory>
    
    var body: some View {
        List {
            ForEach(historyItems) { item in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(item.foodName ?? "Unknown Food")
                            .font(.headline)
                        
                        Spacer()
                        
                        Text("\(Int((item.confidence * 100).rounded()))% match")
                            .font(.subheadline)
                            .foregroundColor(
                                item.confidence > 0.7 ? .green :
                                item.confidence > 0.5 ? .orange : .red
                            )
                    }
                    
                    if let timestamp = item.timestamp {
                        Text(timestamp, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let nutritionInfo = item.nutritionInfo {
                        HStack(spacing: 16) {
                            NutritionBadge(label: "Calories", value: "\(nutritionInfo.calories)")
                            NutritionBadge(label: "Protein", value: "\(Int(nutritionInfo.protein))g")
                            NutritionBadge(label: "Carbs", value: "\(Int(nutritionInfo.carbs))g")
                            NutritionBadge(label: "Fat", value: "\(Int(nutritionInfo.fat))g")
                        }
                        .padding(.vertical, 4)
                        
                        if let fiber = nutritionInfo.fiber?.doubleValue {
                            DetailRow(label: "Fiber", value: "\(Int(fiber))g")
                        }
                        
                        if let sugar = nutritionInfo.sugar?.doubleValue {
                            DetailRow(label: "Sugar", value: "\(Int(sugar))g")
                        }
                        
                        if let sodium = nutritionInfo.sodium?.doubleValue {
                            DetailRow(label: "Sodium", value: "\(Int(sodium))mg")
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            .onDelete(perform: deleteItems)
        }
        .navigationTitle("Recognition History")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { historyItems[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                print("Failed to delete history items: \(error)")
            }
        }
    }
}

// Preview provider
struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            HistoryView()
                .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        }
    }
} 