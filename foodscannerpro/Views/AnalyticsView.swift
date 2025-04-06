import SwiftUI
import Charts

struct AnalyticsView: View {
    @ObservedObject private var analyticsService = AnalyticsService.shared
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedDateRange: DateRange = .week
    @State private var showingFilters = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                if analyticsService.isLoading {
                    ProgressView("Loading analytics...")
                        .padding()
                } else if analyticsService.dailyCalorieIntake.isEmpty {
                    EmptyAnalyticsStateView()
                } else {
                    VStack(spacing: 20) {
                        // Date Range Picker
                        Picker("Date Range", selection: $selectedDateRange) {
                            ForEach(DateRange.allCases) { range in
                                Text(range.rawValue).tag(range)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal)
                        
                        // Calorie Chart
                        CalorieChartView(data: analyticsService.getDataForRange(selectedDateRange))
                            .frame(height: 200)
                            .padding()
                        
                        // Macronutrient Distribution
                        MacronutrientDistributionView(distribution: analyticsService.macronutrientDistribution)
                            .frame(height: 200)
                            .padding()
                        
                        // Frequent Foods
                        FrequentFoodsView(foods: analyticsService.frequentFoods)
                            .frame(height: 200)
                            .padding()
                        
                        // Meal Type Distribution
                        MealTypeDistributionView(data: analyticsService.mealTypeDistribution)
                            .frame(height: 200)
                            .padding()
                        
                        // Health Insights
                        if !analyticsService.healthInsights.isEmpty {
                            VStack(alignment: .leading) {
                                Text("Health Insights")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                ForEach(analyticsService.healthInsights) { insight in
                                    InsightCardView(insight: insight)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Analytics")
            .onAppear {
                analyticsService.analyzeData(in: viewContext)
            }
        }
    }
}

struct EmptyAnalyticsStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            Text("No Data Available")
                .font(.title2)
            Text("Start logging your meals to see analytics")
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

struct CalorieChartView: View {
    let data: [DailyNutritionData]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Calorie Intake")
                .font(.headline)
            
            Chart {
                ForEach(data) { item in
                    LineMark(
                        x: .value("Date", item.date),
                        y: .value("Calories", item.calories)
                    )
                    .foregroundStyle(.blue)
                    
                    if let average = item.caloriesMovingAverage {
                        LineMark(
                            x: .value("Date", item.date),
                            y: .value("Average", average)
                        )
                        .foregroundStyle(.red)
                    }
                }
            }
        }
    }
}

struct MacronutrientDistributionView: View {
    let distribution: MacronutrientDistribution
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Macronutrient Distribution")
                .font(.headline)
            
            Chart {
                SectorMark(
                    angle: .value("Protein", distribution.proteinPercentage),
                    innerRadius: .ratio(0.6),
                    angularInset: 1.0
                )
                .foregroundStyle(.blue)
                
                SectorMark(
                    angle: .value("Carbs", distribution.carbsPercentage),
                    innerRadius: .ratio(0.6),
                    angularInset: 1.0
                )
                .foregroundStyle(.green)
                
                SectorMark(
                    angle: .value("Fats", distribution.fatsPercentage),
                    innerRadius: .ratio(0.6),
                    angularInset: 1.0
                )
                .foregroundStyle(.orange)
            }
        }
    }
}

struct FrequentFoodsView: View {
    let foods: [FrequentFoodItem]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Frequent Foods")
                .font(.headline)
            
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(foods.prefix(5)) { food in
                        HStack {
                            Text(food.name)
                            Spacer()
                            Text("\(food.count)x")
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
    }
}

struct MealTypeDistributionView: View {
    let data: [MealTypeData]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Meal Type Distribution")
                .font(.headline)
            
            Chart {
                ForEach(data) { item in
                    BarMark(
                        x: .value("Type", item.type),
                        y: .value("Count", item.count)
                    )
                    .foregroundStyle(by: .value("Type", item.type))
                }
            }
        }
    }
}

struct InsightCardView: View {
    let insight: HealthInsight
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: insight.type.icon)
                .foregroundColor(insight.type.color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.headline)
                Text(insight.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

#Preview {
    AnalyticsView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 