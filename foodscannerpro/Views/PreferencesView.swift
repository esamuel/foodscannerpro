import SwiftUI

struct PreferencesView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var preferencesManager = UserPreferencesManager.shared
    @State private var showingWeightPicker = false
    @State private var showingCaloriesPicker = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Health Goals")) {
                    // Target Weight
                    HStack {
                        Text("Target Weight")
                        Spacer()
                        Button(action: {
                            showingWeightPicker = true
                        }) {
                            Text(preferencesManager.preferences.healthGoals.targetWeight.map { "\(Int($0)) kg" } ?? "Not Set")
                                .foregroundColor(.blue)
                        }
                    }
                    
                    // Target Calories
                    HStack {
                        Text("Daily Calories")
                        Spacer()
                        Button(action: {
                            showingCaloriesPicker = true
                        }) {
                            Text(preferencesManager.preferences.healthGoals.targetCalories.map { "\($0) kcal" } ?? "Not Set")
                                .foregroundColor(.blue)
                        }
                    }
                    
                    // Macronutrient Goals
                    NavigationLink(destination: MacronutrientGoalsView()) {
                        Text("Macronutrient Goals")
                    }
                }
                
                Section(header: Text("Dietary Preferences")) {
                    Toggle("Vegetarian", isOn: $preferencesManager.preferences.dietaryPreferences.isVegetarian)
                    Toggle("Vegan", isOn: $preferencesManager.preferences.dietaryPreferences.isVegan)
                    Toggle("Keto", isOn: $preferencesManager.preferences.dietaryPreferences.isKeto)
                    Toggle("Paleo", isOn: $preferencesManager.preferences.dietaryPreferences.isPaleo)
                    Toggle("Gluten-Free", isOn: $preferencesManager.preferences.dietaryPreferences.isGlutenFree)
                    Toggle("Dairy-Free", isOn: $preferencesManager.preferences.dietaryPreferences.isDairyFree)
                }
                
                Section(header: Text("Allergies")) {
                    Toggle("Nuts", isOn: $preferencesManager.preferences.allergies.hasNutAllergy)
                    Toggle("Shellfish", isOn: $preferencesManager.preferences.allergies.hasShellfish)
                    Toggle("Eggs", isOn: $preferencesManager.preferences.allergies.hasEggs)
                    Toggle("Soy", isOn: $preferencesManager.preferences.allergies.hasSoy)
                    Toggle("Dairy", isOn: $preferencesManager.preferences.allergies.hasDairy)
                    Toggle("Gluten", isOn: $preferencesManager.preferences.allergies.hasGluten)
                }
            }
            .navigationTitle("Preferences")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingWeightPicker) {
                WeightPickerView(
                    weight: Binding(
                        get: { preferencesManager.preferences.healthGoals.targetWeight ?? 70.0 },
                        set: { preferencesManager.preferences.healthGoals.targetWeight = $0 }
                    )
                )
            }
            .sheet(isPresented: $showingCaloriesPicker) {
                CaloriePickerView(
                    calories: Binding(
                        get: { preferencesManager.preferences.healthGoals.targetCalories ?? 2000 },
                        set: { preferencesManager.preferences.healthGoals.targetCalories = $0 }
                    )
                )
            }
        }
    }
}

struct MacronutrientGoalsView: View {
    @StateObject private var preferencesManager = UserPreferencesManager.shared
    
    var body: some View {
        Form {
            Section(header: Text("Daily Targets")) {
                HStack {
                    Text("Protein")
                    Spacer()
                    TextField("g", value: $preferencesManager.preferences.healthGoals.targetProtein, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                    Text("g")
                }
                
                HStack {
                    Text("Carbs")
                    Spacer()
                    TextField("g", value: $preferencesManager.preferences.healthGoals.targetCarbs, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                    Text("g")
                }
                
                HStack {
                    Text("Fat")
                    Spacer()
                    TextField("g", value: $preferencesManager.preferences.healthGoals.targetFat, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                    Text("g")
                }
            }
        }
        .navigationTitle("Macronutrient Goals")
    }
}

struct WeightPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var weight: Double
    
    var body: some View {
        NavigationView {
            Form {
                Picker("Weight (kg)", selection: $weight) {
                    ForEach(30...200, id: \.self) { kg in
                        Text("\(kg) kg").tag(Double(kg))
                    }
                }
                .pickerStyle(.wheel)
            }
            .navigationTitle("Target Weight")
            .navigationBarItems(
                trailing: Button("Done") {
                    dismiss()
                }
            )
        }
    }
}

struct CaloriePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var calories: Int
    
    var body: some View {
        NavigationView {
            Form {
                Picker("Calories", selection: $calories) {
                    ForEach(1000...5000, id: \.self) { cal in
                        if cal % 50 == 0 {
                            Text("\(cal) kcal").tag(cal)
                        }
                    }
                }
                .pickerStyle(.wheel)
            }
            .navigationTitle("Daily Calories")
            .navigationBarItems(
                trailing: Button("Done") {
                    dismiss()
                }
            )
        }
    }
}

#Preview {
    PreferencesView()
} 