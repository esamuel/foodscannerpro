import SwiftUI
import CoreData

struct EnhancedHistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedFilter: MealFilter = .all
    @State private var searchText = ""
    @State private var showingAddMeal = false
    @State private var showingDatePicker = false
    @State private var selectedDate = Date()
    @State private var dateRange: DateRangeFilter = .week
    
    // Computed property for filtered meals
    private var filteredMeals: [Meal] {
        let fetchRequest: NSFetchRequest<Meal> = Meal.fetchRequest()
        
        // Apply date filter
        var predicates: [NSPredicate] = []
        
        if let dateRangePredicate = getDateRangePredicate() {
            predicates.append(dateRangePredicate)
        }
        
        // Apply meal type filter
        if selectedFilter != .all {
            predicates.append(NSPredicate(format: "type == %@", selectedFilter.rawValue))
        }
        
        // Apply search filter if text is not empty
        if !searchText.isEmpty {
            let searchPredicate = NSPredicate(format: "name CONTAINS[cd] %@ OR ANY foodItems.name CONTAINS[cd] %@", searchText, searchText)
            predicates.append(searchPredicate)
        }
        
        // Combine predicates if needed
        if !predicates.isEmpty {
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }
        
        // Sort by date, most recent first
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Meal.date, ascending: false)]
        
        do {
            return try viewContext.fetch(fetchRequest)
        } catch {
            print("Error fetching meals: \(error)")
            return []
        }
    }
    
    // Group meals by date
    private var groupedMeals: [String: [Meal]] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        
        var groups: [String: [Meal]] = [:]
        
        for meal in filteredMeals {
            guard let date = meal.date else { continue }
            let dateString = dateFormatter.string(from: date)
            
            if groups[dateString] == nil {
                groups[dateString] = []
            }
            
            groups[dateString]?.append(meal)
        }
        
        return groups
    }
    
    // Get sorted date keys
    private var sortedDateKeys: [String] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        
        return groupedMeals.keys.sorted { key1, key2 in
            guard let date1 = dateFormatter.date(from: key1),
                  let date2 = dateFormatter.date(from: key2) else {
                return key1 > key2
            }
            return date1 > date2
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search meals or food items", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(MealFilter.allCases) { filter in
                            FilterChip(
                                title: filter.rawValue,
                                isSelected: selectedFilter == filter
                            ) {
                                selectedFilter = filter
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                }
                
                // Date range selector
                HStack {
                    Text("Time Period:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Picker("Date Range", selection: $dateRange) {
                        ForEach(DateRangeFilter.allCases) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    Spacer()
                    
                    if dateRange == .custom {
                        Button(action: {
                            showingDatePicker = true
                        }) {
                            HStack {
                                Image(systemName: "calendar")
                                Text(formatDate(date: selectedDate))
                                    .font(.subheadline)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color(.systemGray5))
                            .cornerRadius(8)
                        }
                    }
                }
                .padding(.horizontal)
                
                Divider()
                    .padding(.vertical, 5)
                
                // Meal list
                if filteredMeals.isEmpty {
                    EmptyHistoryView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 20, pinnedViews: [.sectionHeaders]) {
                            ForEach(sortedDateKeys, id: \.self) { dateKey in
                                Section(header: 
                                    Text(dateKey)
                                        .font(.headline)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal)
                                        .padding(.vertical, 5)
                                        .background(Color(.systemBackground))
                                ) {
                                    ForEach(groupedMeals[dateKey] ?? [], id: \.id) { meal in
                                        NavigationLink(destination: EnhancedMealDetailView(meal: meal)) {
                                            MealRowView(meal: meal)
                                                .padding(.horizontal)
                                                .padding(.vertical, 8)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("Meal History")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddMeal = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddMeal) {
                AddMealView()
            }
            .sheet(isPresented: $showingDatePicker) {
                DatePickerView(selectedDate: $selectedDate, isPresented: $showingDatePicker)
            }
        }
    }
    
    private func formatDate(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func getDateRangePredicate() -> NSPredicate? {
        let calendar = Calendar.current
        let now = Date()
        
        switch dateRange {
        case .today:
            let startOfDay = calendar.startOfDay(for: now)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            return NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
            
        case .week:
            let startOfWeek = calendar.date(byAdding: .day, value: -7, to: now)!
            return NSPredicate(format: "date >= %@", startOfWeek as NSDate)
            
        case .month:
            let startOfMonth = calendar.date(byAdding: .month, value: -1, to: now)!
            return NSPredicate(format: "date >= %@", startOfMonth as NSDate)
            
        case .threeMonths:
            let startDate = calendar.date(byAdding: .month, value: -3, to: now)!
            return NSPredicate(format: "date >= %@", startDate as NSDate)
            
        case .sixMonths:
            let startDate = calendar.date(byAdding: .month, value: -6, to: now)!
            return NSPredicate(format: "date >= %@", startDate as NSDate)
            
        case .year:
            let startDate = calendar.date(byAdding: .year, value: -1, to: now)!
            return NSPredicate(format: "date >= %@", startDate as NSDate)
            
        case .custom:
            let startOfSelectedDay = calendar.startOfDay(for: selectedDate)
            let endOfSelectedDay = calendar.date(byAdding: .day, value: 1, to: startOfSelectedDay)!
            return NSPredicate(format: "date >= %@ AND date < %@", startOfSelectedDay as NSDate, endOfSelectedDay as NSDate)
            
        case .all:
            return nil
        }
    }
    
    private func deleteMeal(_ meal: Meal) {
        viewContext.delete(meal)
        
        do {
            try viewContext.save()
        } catch {
            print("Error deleting meal: \(error)")
        }
    }
}

// MARK: - Supporting Views

struct MealRowView: View {
    let meal: Meal
    
    private var totalCalories: Double {
        let foodItems = meal.foodItems as? Set<FoodItem> ?? []
        return foodItems.reduce(0) { $0 + $1.calories }
    }
    
    private var foodItemsCount: Int {
        let foodItems = meal.foodItems as? Set<FoodItem> ?? []
        return foodItems.count
    }
    
    var body: some View {
        HStack(spacing: 15) {
            // Meal icon based on type
            ZStack {
                Circle()
                    .fill(getMealTypeColor(type: meal.type))
                    .frame(width: 50, height: 50)
                
                Image(systemName: getMealTypeIcon(type: meal.type))
                    .font(.system(size: 20))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(meal.name ?? "Unknown Meal")
                    .font(.headline)
                
                HStack {
                    Text(meal.type ?? "Other")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(getMealTypeColor(type: meal.type).opacity(0.2))
                        .cornerRadius(4)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text(formatTime(date: meal.date))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text("\(Int(totalCalories)) calories • \(foodItemsCount) items")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
    
    private func formatTime(date: Date?) -> String {
        guard let date = date else { return "Unknown time" }
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        
        return formatter.string(from: date)
    }
    
    private func getMealTypeColor(type: String?) -> Color {
        guard let type = type else { return .gray }
        
        switch type {
        case "Breakfast":
            return .orange
        case "Lunch":
            return .green
        case "Dinner":
            return .blue
        case "Snack":
            return .purple
        default:
            return .gray
        }
    }
    
    private func getMealTypeIcon(type: String?) -> String {
        guard let type = type else { return "circle" }
        
        switch type {
        case "Breakfast":
            return "sunrise.fill"
        case "Lunch":
            return "sun.max.fill"
        case "Dinner":
            return "moon.stars.fill"
        case "Snack":
            return "carrot.fill"
        default:
            return "circle"
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.green : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

struct EmptyHistoryView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "fork.knife")
                .font(.system(size: 60))
                .foregroundColor(.green.opacity(0.7))
            
            Text("No Meals Found")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Start tracking your meals by scanning food or adding meals manually.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct DatePickerView: View {
    @Binding var selectedDate: Date
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            VStack {
                DatePicker(
                    "Select Date",
                    selection: $selectedDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(GraphicalDatePickerStyle())
                .padding()
                
                Button(action: {
                    isPresented = false
                }) {
                    Text("Done")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
            }
            .navigationTitle("Select Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

// MARK: - Add Meal View

struct AddMealView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var mealName = ""
    @State private var mealType = "Lunch"
    @State private var mealDate = Date()
    @State private var foodItems: [TempFoodItem] = []
    @State private var showingAddFood = false
    
    private let mealTypes = ["Breakfast", "Lunch", "Dinner", "Snack"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Meal Details")) {
                    TextField("Meal Name", text: $mealName)
                    
                    Picker("Meal Type", selection: $mealType) {
                        ForEach(mealTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    
                    DatePicker("Date & Time", selection: $mealDate)
                }
                
                Section(header: Text("Food Items")) {
                    ForEach(foodItems.indices, id: \.self) { index in
                        HStack {
                            VStack(alignment: .leading) {
                                TextField("Food Name", text: $foodItems[index].name)
                                    .font(.headline)
                                
                                HStack {
                                    TextField("Calories", value: $foodItems[index].calories, format: .number)
                                        .keyboardType(.numberPad)
                                    
                                    Text("kcal")
                                        .foregroundColor(.secondary)
                                }
                                .font(.subheadline)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                foodItems.remove(at: index)
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    
                    Button(action: {
                        foodItems.append(TempFoodItem(name: "", calories: 0, protein: 0, carbs: 0, fats: 0))
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Food Item")
                        }
                    }
                }
                
                Section {
                    Button(action: saveMeal) {
                        Text("Save Meal")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                            .padding(.vertical, 8)
                            .background(Color.green)
                            .cornerRadius(8)
                    }
                    .disabled(mealName.isEmpty || foodItems.isEmpty || foodItems.contains(where: { $0.name.isEmpty }))
                }
            }
            .navigationTitle("Add Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func saveMeal() {
        let meal = Meal(context: viewContext)
        meal.id = UUID()
        meal.name = mealName
        meal.date = mealDate
        meal.type = mealType
        
        for tempFood in foodItems {
            let food = FoodItem(context: viewContext)
            food.id = UUID()
            food.name = tempFood.name
            food.calories = tempFood.calories
            food.protein = tempFood.protein
            food.carbs = tempFood.carbs
            food.fats = tempFood.fats
            food.dateScanned = mealDate
            
            meal.addToFoodItems(food)
        }
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Error saving meal: \(error)")
        }
    }
}

// MARK: - Enhanced Meal Detail View

struct EnhancedMealDetailView: View {
    let meal: Meal
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteAlert = false
    @State private var showingEditMeal = false
    
    private var foodItems: [FoodItem] {
        let items = meal.foodItems as? Set<FoodItem> ?? []
        return items.sorted { ($0.name ?? "") < ($1.name ?? "") }
    }
    
    private var totalNutrition: (calories: Double, protein: Double, carbs: Double, fats: Double) {
        var calories: Double = 0
        var protein: Double = 0
        var carbs: Double = 0
        var fats: Double = 0
        
        for item in foodItems {
            calories += item.calories
            protein += item.protein
            carbs += item.carbs
            fats += item.fats
        }
        
        return (calories, protein, carbs, fats)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Meal header
                VStack(spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(meal.name ?? "Unknown Meal")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(formatDate(date: meal.date))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        ZStack {
                            Circle()
                                .fill(getMealTypeColor(type: meal.type))
                                .frame(width: 50, height: 50)
                            
                            Image(systemName: getMealTypeIcon(type: meal.type))
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Nutrition summary
                    HStack(spacing: 15) {
                        NutritionSummaryItem(
                            title: "Calories",
                            value: Int(totalNutrition.calories),
                            unit: "kcal",
                            color: .blue
                        )
                        
                        NutritionSummaryItem(
                            title: "Protein",
                            value: Int(totalNutrition.protein),
                            unit: "g",
                            color: .red
                        )
                        
                        NutritionSummaryItem(
                            title: "Carbs",
                            value: Int(totalNutrition.carbs),
                            unit: "g",
                            color: .green
                        )
                        
                        NutritionSummaryItem(
                            title: "Fats",
                            value: Int(totalNutrition.fats),
                            unit: "g",
                            color: .yellow
                        )
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
                .background(Color(.systemGray6))
                .cornerRadius(15)
                .padding(.horizontal)
                
                // Food items
                VStack(alignment: .leading, spacing: 10) {
                    Text("Food Items")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ForEach(foodItems, id: \.id) { item in
                        FoodItemDetailRow(item: item)
                    }
                }
                .padding(.vertical)
                .background(Color(.systemGray6))
                .cornerRadius(15)
                .padding(.horizontal)
                
                // Actions
                HStack(spacing: 20) {
                    Button(action: {
                        showingEditMeal = true
                    }) {
                        Label("Edit", systemImage: "pencil")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        showingDeleteAlert = true
                    }) {
                        Label("Delete", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Meal Details")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete Meal", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteMeal()
            }
        } message: {
            Text("Are you sure you want to delete this meal and all its items?")
        }
    }
    
    private func formatDate(date: Date?) -> String {
        guard let date = date else { return "Unknown date" }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        
        return formatter.string(from: date)
    }
    
    private func getMealTypeColor(type: String?) -> Color {
        guard let type = type else { return .gray }
        
        switch type {
        case "Breakfast":
            return .orange
        case "Lunch":
            return .green
        case "Dinner":
            return .blue
        case "Snack":
            return .purple
        default:
            return .gray
        }
    }
    
    private func getMealTypeIcon(type: String?) -> String {
        guard let type = type else { return "circle" }
        
        switch type {
        case "Breakfast":
            return "sunrise.fill"
        case "Lunch":
            return "sun.max.fill"
        case "Dinner":
            return "moon.stars.fill"
        case "Snack":
            return "carrot.fill"
        default:
            return "circle"
        }
    }
    
    private func deleteMeal() {
        viewContext.delete(meal)
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Error deleting meal: \(error)")
        }
    }
}

struct FoodItemDetailRow: View {
    let item: FoodItem
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(item.name ?? "Unknown Food")
                        .font(.headline)
                    
                    Text("\(Int(item.calories)) calories")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if let imageData = item.image, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .cornerRadius(8)
                }
            }
            
            // Nutrition bars
            VStack(spacing: 8) {
                NutritionBar(title: "Protein", value: item.protein, color: .red)
                NutritionBar(title: "Carbs", value: item.carbs, color: .green)
                NutritionBar(title: "Fats", value: item.fats, color: .yellow)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

struct NutritionBar: View {
    let title: String
    let value: Double
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 50, alignment: .leading)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .frame(width: geometry.size.width, height: 8)
                        .opacity(0.2)
                        .foregroundColor(color)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .frame(width: min(CGFloat(value) / 50 * geometry.size.width, geometry.size.width), height: 8)
                        .foregroundColor(color)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
            
            Text("\(Int(value))g")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 30, alignment: .trailing)
        }
    }
}

struct NutritionSummaryItem: View {
    let title: String
    let value: Int
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 5) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("\(value)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(unit)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Supporting Models

struct TempFoodItem {
    var name: String
    var calories: Double
    var protein: Double
    var carbs: Double
    var fats: Double
}

enum MealFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case snack = "Snack"
    
    var id: String { self.rawValue }
}

enum DateRangeFilter: String, CaseIterable, Identifiable {
    case today = "Today"
    case week = "Last 7 Days"
    case month = "Last 30 Days"
    case threeMonths = "Last 3 Months"
    case sixMonths = "Last 6 Months"
    case year = "Last Year"
    case all = "All Time"
    case custom = "Custom"
    
    var id: String { self.rawValue }
    
    var title: String {
        return self.rawValue
    }
}

struct EnhancedHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        EnhancedHistoryView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
} 