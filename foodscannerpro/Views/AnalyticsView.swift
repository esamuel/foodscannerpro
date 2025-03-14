import SwiftUI
import Charts

struct AnalyticsView: View {
    @ObservedObject private var analyticsService = AnalyticsService.shared
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedDateRange: DateRange = .month
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab selector
                Picker("", selection: $selectedTab) {
                    Text("Overview").tag(0)
                    Text("Trends").tag(1)
                    Text("Insights").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .padding(.top)
                
                // Date range selector
                Picker("Date Range", selection: $selectedDateRange) {
                    ForEach(DateRange.allCases) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding(.horizontal)
                .padding(.top, 8)
                
                if analyticsService.isLoading {
                    ProgressView("Analyzing data...")
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if analyticsService.dailyCalorieIntake.isEmpty {
                    EmptyAnalyticsView()
                } else {
                    TabView(selection: $selectedTab) {
                        // Overview Tab
                        ScrollView {
                            VStack(spacing: 20) {
                                // Calorie Intake Chart
                                CalorieChartView(
                                    data: analyticsService.getDataForRange(selectedDateRange),
                                    targetCalories: Double(HealthService.shared.healthProfile.dailyCalorieTarget)
                                )
                                
                                // Macronutrient Distribution
                                MacronutrientDistributionView(
                                    distribution: analyticsService.macronutrientDistribution
                                )
                                
                                // Frequent Foods
                                FrequentFoodsView(
                                    foods: analyticsService.frequentFoods.prefix(5).map { $0 }
                                )
                                
                                // Meal Type Distribution
                                if !analyticsService.mealTypeDistribution.isEmpty {
                                    MealTypeDistributionView(
                                        mealTypes: analyticsService.mealTypeDistribution
                                    )
                                }
                            }
                            .padding(.bottom, 20)
                        }
                        .tag(0)
                        
                        // Trends Tab
                        ScrollView {
                            VStack(spacing: 20) {
                                // Nutrition Trends
                                NutritionTrendsView(
                                    trends: analyticsService.nutritionTrends
                                )
                                
                                // Weekly Nutrition Chart
                                WeeklyNutritionChartView(
                                    weeklyData: analyticsService.nutritionTrends.weeklyData.suffix(8).map { $0 }
                                )
                                
                                // Calorie Trend Chart
                                CalorieTrendChartView(
                                    data: analyticsService.getDataForRange(selectedDateRange)
                                )
                            }
                            .padding(.bottom, 20)
                        }
                        .tag(1)
                        
                        // Insights Tab
                        ScrollView {
                            VStack(spacing: 15) {
                                ForEach(analyticsService.healthInsights) { insight in
                                    InsightCardView(insight: insight)
                                }
                                
                                if analyticsService.healthInsights.isEmpty {
                                    Text("No insights available yet")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        .padding(.top, 50)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 20)
                        }
                        .tag(2)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                }
            }
            .navigationTitle("Nutrition Analytics")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        analyticsService.analyzeData(in: viewContext)
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .onAppear {
                analyticsService.analyzeData(in: viewContext)
            }
        }
    }
}

// MARK: - Empty State View

struct EmptyAnalyticsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 60))
                .foregroundColor(.green.opacity(0.7))
            
            Text("No Data to Analyze")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Start scanning and saving meals to see analytics and insights about your nutrition habits.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            NavigationLink(destination: HistoryView()) {
                Text("View Meal History")
                    .fontWeight(.semibold)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top, 10)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Chart Views

struct CalorieChartView: View {
    let data: [DailyNutritionData]
    let targetCalories: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Calorie Intake")
                .font(.headline)
                .padding(.horizontal)
            
            Text("Daily calories consumed vs. target")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            if data.isEmpty {
                Text("No data available for selected period")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                Chart {
                    ForEach(data) { item in
                        BarMark(
                            x: .value("Date", item.shortDate),
                            y: .value("Calories", item.calories)
                        )
                        .foregroundStyle(Color.green.gradient)
                    }
                    
                    RuleMark(
                        y: .value("Target", targetCalories)
                    )
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                    .foregroundStyle(Color.red)
                    .annotation(position: .top, alignment: .trailing) {
                        Text("Target: \(Int(targetCalories)) kcal")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .chartYScale(domain: 0...(max(targetCalories * 1.5, data.map { $0.calories }.max() ?? 0) + 100))
                .frame(height: 220)
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .background(Color(.systemGray6))
        .cornerRadius(15)
        .padding(.horizontal)
    }
}

struct MacronutrientDistributionView: View {
    let distribution: MacronutrientDistribution
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Macronutrient Distribution")
                .font(.headline)
                .padding(.horizontal)
            
            HStack(alignment: .top, spacing: 15) {
                MacronutrientPieSlice(
                    title: "Protein",
                    percentage: distribution.proteinPercentage,
                    total: distribution.totalProtein,
                    color: .red
                )
                
                MacronutrientPieSlice(
                    title: "Carbs",
                    percentage: distribution.carbsPercentage,
                    total: distribution.totalCarbs,
                    color: .green
                )
                
                MacronutrientPieSlice(
                    title: "Fats",
                    percentage: distribution.fatsPercentage,
                    total: distribution.totalFats,
                    color: .yellow
                )
            }
            .padding()
        }
        .padding(.vertical)
        .background(Color(.systemGray6))
        .cornerRadius(15)
        .padding(.horizontal)
    }
}

struct MacronutrientPieSlice: View {
    let title: String
    let percentage: Double
    let total: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 10)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: min(CGFloat(percentage) / 100, 1.0))
                    .stroke(color, lineWidth: 10)
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 0) {
                    Text("\(Int(percentage))%")
                        .font(.system(size: 16, weight: .bold))
                    Text(title)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            
            Text("\(Int(total))g")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct FrequentFoodsView: View {
    let foods: [FrequentFoodItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Most Frequent Foods")
                .font(.headline)
                .padding(.horizontal)
            
            if foods.isEmpty {
                Text("No data available")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                VStack(spacing: 12) {
                    ForEach(foods) { food in
                        HStack {
                            Text(food.name)
                                .font(.subheadline)
                            
                            Spacer()
                            
                            Text("\(food.count) times")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("•")
                                .foregroundColor(.secondary)
                            
                            Text("\(Int(food.averageCalories)) kcal avg")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                        
                        if food.id != foods.last?.id {
                            Divider()
                                .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
        }
        .padding(.vertical)
        .background(Color(.systemGray6))
        .cornerRadius(15)
        .padding(.horizontal)
    }
}

struct MealTypeDistributionView: View {
    let mealTypes: [MealTypeData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Meal Type Distribution")
                .font(.headline)
                .padding(.horizontal)
            
            if mealTypes.isEmpty {
                Text("No data available")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                Chart {
                    ForEach(mealTypes) { mealType in
                        SectorMark(
                            angle: .value("Count", mealType.count),
                            innerRadius: .ratio(0.5),
                            angularInset: 1.5
                        )
                        .cornerRadius(5)
                        .foregroundStyle(by: .value("Type", mealType.type))
                    }
                }
                .frame(height: 200)
                .padding(.horizontal)
                
                VStack(spacing: 8) {
                    ForEach(mealTypes) { mealType in
                        HStack {
                            Circle()
                                .fill(Color.green.opacity(Double(mealTypes.firstIndex(where: { $0.id == mealType.id })!) * 0.2 + 0.3))
                                .frame(width: 10, height: 10)
                            
                            Text(mealType.type)
                                .font(.caption)
                            
                            Spacer()
                            
                            Text("\(mealType.count) meals")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("•")
                                .foregroundColor(.secondary)
                            
                            Text("\(Int(mealType.averageCalories)) kcal avg")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .background(Color(.systemGray6))
        .cornerRadius(15)
        .padding(.horizontal)
    }
}

struct NutritionTrendsView: View {
    let trends: NutritionTrends
    @ObservedObject private var analyticsService = AnalyticsService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Nutrition Trends")
                .font(.headline)
                .padding(.horizontal)
            
            Text("Changes since you started tracking")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            VStack(spacing: 15) {
                TrendRowView(
                    title: "Calories",
                    value: trends.caloriesTrend,
                    icon: "flame.fill"
                )
                
                Divider()
                    .padding(.horizontal)
                
                TrendRowView(
                    title: "Protein",
                    value: trends.proteinTrend,
                    icon: "p.circle.fill"
                )
                
                Divider()
                    .padding(.horizontal)
                
                TrendRowView(
                    title: "Carbs",
                    value: trends.carbsTrend,
                    icon: "c.circle.fill"
                )
                
                Divider()
                    .padding(.horizontal)
                
                TrendRowView(
                    title: "Fats",
                    value: trends.fatsTrend,
                    icon: "f.circle.fill"
                )
            }
            .padding(.vertical)
        }
        .padding(.vertical)
        .background(Color(.systemGray6))
        .cornerRadius(15)
        .padding(.horizontal)
    }
}

struct TrendRowView: View {
    let title: String
    let value: Double
    let icon: String
    @ObservedObject private var analyticsService = AnalyticsService.shared
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(analyticsService.getTrendColor(value: value))
            
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            Text(analyticsService.getFormattedTrend(value: value))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(analyticsService.getTrendColor(value: value))
        }
        .padding(.horizontal)
    }
}

struct WeeklyNutritionChartView: View {
    let weeklyData: [WeeklyNutritionData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Weekly Nutrition")
                .font(.headline)
                .padding(.horizontal)
            
            if weeklyData.isEmpty {
                Text("No data available for selected period")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                Chart {
                    ForEach(weeklyData) { week in
                        BarMark(
                            x: .value("Week", week.formattedDate),
                            y: .value("Protein", week.totalProtein)
                        )
                        .foregroundStyle(Color.red.gradient)
                        
                        BarMark(
                            x: .value("Week", week.formattedDate),
                            y: .value("Carbs", week.totalCarbs)
                        )
                        .foregroundStyle(Color.green.gradient)
                        
                        BarMark(
                            x: .value("Week", week.formattedDate),
                            y: .value("Fats", week.totalFats)
                        )
                        .foregroundStyle(Color.yellow.gradient)
                    }
                }
                .chartForegroundStyleScale([
                    "Protein": Color.red,
                    "Carbs": Color.green,
                    "Fats": Color.yellow
                ])
                .chartLegend(position: .bottom, alignment: .center)
                .frame(height: 220)
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .background(Color(.systemGray6))
        .cornerRadius(15)
        .padding(.horizontal)
    }
}

struct CalorieTrendChartView: View {
    let data: [DailyNutritionData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Calorie Trend")
                .font(.headline)
                .padding(.horizontal)
            
            Text("Daily calories with 7-day moving average")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            if data.isEmpty {
                Text("No data available for selected period")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                Chart {
                    ForEach(data) { item in
                        LineMark(
                            x: .value("Date", item.shortDate),
                            y: .value("Calories", item.calories)
                        )
                        .foregroundStyle(Color.green.opacity(0.5))
                        .symbol {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 6, height: 6)
                        }
                    }
                    
                    ForEach(data.filter { $0.caloriesMovingAverage != nil }) { item in
                        LineMark(
                            x: .value("Date", item.shortDate),
                            y: .value("Average", item.caloriesMovingAverage!)
                        )
                        .foregroundStyle(Color.blue)
                        .lineStyle(StrokeStyle(lineWidth: 3))
                    }
                }
                .chartYScale(domain: 0...(data.map { $0.calories }.max() ?? 0) + 200)
                .chartLegend(position: .bottom, alignment: .center)
                .frame(height: 220)
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .background(Color(.systemGray6))
        .cornerRadius(15)
        .padding(.horizontal)
    }
}

struct InsightCardView: View {
    let insight: HealthInsight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: insight.type.icon)
                    .foregroundColor(insight.type.color)
                
                Text(insight.title)
                    .font(.headline)
                
                Spacer()
                
                Text(insight.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(insight.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(insight.type.color.opacity(0.1))
        .cornerRadius(10)
    }
} 