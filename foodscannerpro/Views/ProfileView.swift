import SwiftUI
import PhotosUI
import UIKit
import Components

struct ProfileView: View {
    @StateObject private var userProfile = UserProfile.shared
    @StateObject private var apiKeyManager = APIKeyManager.shared
    @State private var isEditingProfile = false
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var showingAPIKeySetup = false
    @State private var showingSettings = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingAPISettings = false
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    ProfileHeaderView(
                        userProfile: userProfile,
                        showingImagePicker: $showingImagePicker,
                        selectedImage: $selectedImage
                    )
                    
                    UserStatsView(userProfile: userProfile)
                    
                    HealthMetricsView(userProfile: userProfile)
                    
                    AlertPreferencesView(preferences: userProfile.alertPreferences)
                    
                    PreferencesSectionView(
                        dietaryPreferences: userProfile.dietaryPreferences,
                        allergies: userProfile.allergies,
                        goals: userProfile.goals
                    )
                    
                    ActionButtonsView(
                        isEditingProfile: $isEditingProfile,
                        showingSettings: $showingSettings,
                        showingAPIKeySetup: $showingAPIKeySetup
                    )
                    
                    APIStatusView(apiKeyManager: apiKeyManager, showingAPISettings: $showingAPISettings)
                }
                .padding(.bottom, 30)
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $isEditingProfile) {
                NavigationStack {
                    EditProfileView(userProfile: userProfile, isPresented: $isEditingProfile)
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ModernImagePicker(selectedImage: $selectedImage, sourceType: .photoLibrary)
            }
            .sheet(isPresented: $showingAPIKeySetup) {
                NavigationStack {
                    APIKeySetupView(isPresented: $showingAPIKeySetup)
                }
            }
            .sheet(isPresented: $showingSettings) {
                NavigationStack {
                    SettingsView(isPresented: $showingSettings)
                }
            }
            .sheet(isPresented: $showingAPISettings) {
                NavigationStack {
                    APISettingsView()
                }
            }
            .onChange(of: selectedImage) { oldValue, newValue in
                if let image = newValue {
                    userProfile.updateProfileImage(image)
                }
            }
        }
    }
}

// MARK: - Profile Header View
struct ProfileHeaderView: View {
    @ObservedObject var userProfile: UserProfile
    @Binding var showingImagePicker: Bool
    @Binding var selectedImage: UIImage?
    
    var body: some View {
        VStack(spacing: 10) {
            // Profile Image
            ZStack {
                if let profileImage = userProfile.profileImage {
                    Image(uiImage: profileImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 120, height: 120)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                        )
                }
                
                Button(action: {
                    showingImagePicker = true
                }) {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 30, height: 30)
                        .overlay(
                            Image(systemName: "camera.fill")
                                .font(.system(size: 15))
                                .foregroundColor(.white)
                        )
                }
                .offset(x: 40, y: 40)
            }
            .padding(.top, 20)
            
            Text(userProfile.name)
                .font(.title)
                .fontWeight(.bold)
            
            Text(userProfile.email)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - User Stats View
struct UserStatsView: View {
    @ObservedObject var userProfile: UserProfile
    
    var body: some View {
        VStack(spacing: 15) {
            HStack(spacing: 30) {
                StatView(title: "Age", value: "\(userProfile.age)")
                StatView(title: "Height", value: "\(Int(userProfile.height)) cm")
                StatView(title: "Weight", value: "\(Int(userProfile.weight)) kg")
            }
            
            BMIView(bmi: userProfile.bmi, category: userProfile.bmiCategory)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
        .padding(.horizontal)
    }
}

struct BMIView: View {
    let bmi: Double
    let category: Components.BMICategory
    
    var body: some View {
        HStack {
            Text("BMI:")
                .font(.headline)
            Text(String(format: "%.1f", bmi))
                .font(.headline)
            Text("(\(category.rawValue))")
                .font(.subheadline)
                .foregroundColor(bmiColor(for: category))
        }
    }
    
    private func bmiColor(for category: Components.BMICategory) -> Color {
        switch category {
        case .underweight: return .orange
        case .normal: return .green
        case .overweight: return .yellow
        case .obese: return .red
        }
    }
}

// MARK: - Health Metrics View
struct HealthMetricsView: View {
    @ObservedObject var userProfile: UserProfile
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Health Metrics")
                .font(.headline)
                .padding(.horizontal)
            
            HStack(spacing: 20) {
                HealthMetricView(
                    title: "Blood Pressure",
                    value: userProfile.bloodPressure,
                    icon: "heart.fill",
                    color: .red
                )
                
                HealthMetricView(
                    title: "Blood Sugar",
                    value: String(format: "%.1f mmol/L", userProfile.bloodSugar),
                    icon: "drop.fill",
                    color: .blue
                )
            }
            .padding(.horizontal)
            
            CholesterolView(cholesterol: userProfile.cholesterol)
        }
        .padding(.vertical, 5)
    }
}

struct CholesterolView: View {
    let cholesterol: Components.Cholesterol
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Cholesterol")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                Text("Total: \(String(format: "%.1f", cholesterol.total)) mmol/L")
                Spacer()
                Text("HDL: \(String(format: "%.1f", cholesterol.hdl)) mmol/L")
                Spacer()
                Text("LDL: \(String(format: "%.1f", cholesterol.ldl)) mmol/L")
            }
            .font(.caption)
            
            HStack {
                Text("Status:")
                Text(cholesterol.status.rawValue)
                    .foregroundColor(cholesterolStatusColor(cholesterol.status))
            }
            .font(.caption)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }
    
    private func cholesterolStatusColor(_ status: Components.CholesterolStatus) -> Color {
        switch status {
        case .optimal, .normal: return .green
        case .borderline: return .yellow
        case .high: return .red
        }
    }
}

// MARK: - Alert Preferences View
struct AlertPreferencesView: View {
    let preferences: Components.AlertPreferences
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Alert Preferences")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 8) {
                AlertPreferenceRow(
                    title: "Sugar",
                    isEnabled: preferences.alertForSugar,
                    threshold: "\(Int(preferences.sugarThreshold))g"
                )
                AlertPreferenceRow(
                    title: "Sodium",
                    isEnabled: preferences.alertForSodium,
                    threshold: "\(Int(preferences.sodiumThreshold))mg"
                )
                AlertPreferenceRow(
                    title: "Fat",
                    isEnabled: preferences.alertForFat,
                    threshold: "\(Int(preferences.fatThreshold))g"
                )
                AlertPreferenceRow(
                    title: "Calories",
                    isEnabled: preferences.alertForCalories,
                    threshold: "\(Int(preferences.calorieThreshold)) kcal"
                )
                AlertPreferenceRow(
                    title: "Allergens",
                    isEnabled: preferences.alertForAllergens,
                    threshold: ""
                )
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
        }
        .padding(.vertical, 5)
    }
}

struct AlertPreferenceRow: View {
    let title: String
    let isEnabled: Bool
    let threshold: String
    
    var body: some View {
        HStack {
            Image(systemName: isEnabled ? "bell.fill" : "bell.slash")
                .foregroundColor(isEnabled ? .green : .gray)
            Text(title)
            Spacer()
            if !threshold.isEmpty {
                Text("Threshold: \(threshold)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Preferences Section View
struct PreferencesSectionView: View {
    let dietaryPreferences: [String]
    let allergies: [String]
    let goals: [String]
    
    var body: some View {
        VStack(spacing: 15) {
            SectionView(title: "Dietary Preferences", items: dietaryPreferences)
            SectionView(title: "Allergies", items: allergies)
            SectionView(title: "Goals", items: goals)
        }
    }
}

// MARK: - Action Buttons View
struct ActionButtonsView: View {
    @Binding var isEditingProfile: Bool
    @Binding var showingSettings: Bool
    @Binding var showingAPIKeySetup: Bool
    
    var body: some View {
        VStack(spacing: 10) {
            Button(action: { isEditingProfile = true }) {
                ActionButtonLabel(title: "Edit Profile", icon: "pencil", color: .blue)
            }
            
            Button(action: { showingSettings = true }) {
                ActionButtonLabel(title: "Settings", icon: "gear", color: .purple)
            }
            
            Button(action: { showingAPIKeySetup = true }) {
                ActionButtonLabel(title: "Setup API Keys", icon: "key.fill", color: .green)
            }
        }
        .padding(.horizontal)
    }
}

struct ActionButtonLabel: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.headline)
            Text(title)
                .font(.headline)
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .padding()
        .background(color)
        .cornerRadius(10)
    }
}

// MARK: - API Status View
struct APIStatusView: View {
    @ObservedObject var apiKeyManager: APIKeyManager
    @Binding var showingAPISettings: Bool
    
    var body: some View {
        Section(header: Text("API Settings")) {
            APIKeyStatusRow(title: "Clarifai", isValid: apiKeyManager.hasValidClarifaiKey())
            APIKeyStatusRow(title: "LogMeal", isValid: apiKeyManager.hasValidLogMealKey())
            APIKeyStatusRow(title: "USDA", isValid: apiKeyManager.hasValidUsdaKey())
            
            Button("Configure API Keys") {
                showingAPISettings = true
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

struct APIKeyStatusRow: View {
    let title: String
    let isValid: Bool
    
    var body: some View {
        HStack {
            Text("\(isValid ? "✓" : "✗") \(title) API key \(isValid ? "is set" : "not set")")
                .foregroundColor(isValid ? .green : .red)
        }
    }
}

struct StatView: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 5) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.headline)
        }
    }
}

struct SectionView: View {
    let title: String
    let items: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(items, id: \.self) { item in
                        Text(item)
                            .padding(.horizontal, 15)
                            .padding(.vertical, 8)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(20)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 5)
    }
}

struct HealthMetricView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct EditProfileView: View {
    @ObservedObject var userProfile: UserProfile
    @Environment(\.dismiss) private var dismiss
    @Binding var isPresented: Bool
    
    @State private var name: String
    @State private var email: String
    @State private var age: String
    @State private var height: String
    @State private var weight: String
    @State private var newPreference: String = ""
    @State private var newAllergy: String = ""
    @State private var newGoal: String = ""
    
    // New health metrics
    @State private var bloodPressureSystolic: String
    @State private var bloodPressureDiastolic: String
    @State private var bloodSugar: String
    @State private var cholesterolTotal: String
    @State private var cholesterolHDL: String
    @State private var cholesterolLDL: String
    
    // Alert preferences
    @State private var alertForSugar: Bool
    @State private var alertForSodium: Bool
    @State private var alertForFat: Bool
    @State private var alertForCalories: Bool
    @State private var alertForAllergens: Bool
    
    @State private var sugarThreshold: String
    @State private var sodiumThreshold: String
    @State private var fatThreshold: String
    @State private var calorieThreshold: String
    
    init(userProfile: UserProfile, isPresented: Binding<Bool>) {
        self.userProfile = userProfile
        _isPresented = isPresented
        
        // Initialize personal info
        _name = State(initialValue: userProfile.name)
        _email = State(initialValue: userProfile.email)
        _age = State(initialValue: String(userProfile.age))
        _height = State(initialValue: String(userProfile.height))
        _weight = State(initialValue: String(userProfile.weight))
        
        // Initialize health metrics
        let bpComponents = userProfile.bloodPressure.split(separator: "/")
        _bloodPressureSystolic = State(initialValue: String(bpComponents.first ?? "120"))
        _bloodPressureDiastolic = State(initialValue: String(bpComponents.last ?? "80"))
        _bloodSugar = State(initialValue: String(userProfile.bloodSugar))
        _cholesterolTotal = State(initialValue: String(userProfile.cholesterol.total))
        _cholesterolHDL = State(initialValue: String(userProfile.cholesterol.hdl))
        _cholesterolLDL = State(initialValue: String(userProfile.cholesterol.ldl))
        
        // Initialize alert preferences
        _alertForSugar = State(initialValue: userProfile.alertPreferences.alertForSugar)
        _alertForSodium = State(initialValue: userProfile.alertPreferences.alertForSodium)
        _alertForFat = State(initialValue: userProfile.alertPreferences.alertForFat)
        _alertForCalories = State(initialValue: userProfile.alertPreferences.alertForCalories)
        _alertForAllergens = State(initialValue: userProfile.alertPreferences.alertForAllergens)
        
        _sugarThreshold = State(initialValue: String(userProfile.alertPreferences.sugarThreshold))
        _sodiumThreshold = State(initialValue: String(userProfile.alertPreferences.sodiumThreshold))
        _fatThreshold = State(initialValue: String(userProfile.alertPreferences.fatThreshold))
        _calorieThreshold = State(initialValue: String(userProfile.alertPreferences.calorieThreshold))
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Information")) {
                    TextField("Name", text: $name)
                    TextField("Email", text: $email)
                    TextField("Age", text: $age)
                        .keyboardType(.numberPad)
                    TextField("Height (cm)", text: $height)
                        .keyboardType(.decimalPad)
                    TextField("Weight (kg)", text: $weight)
                        .keyboardType(.decimalPad)
                }
                
                Section(header: Text("Health Metrics")) {
                    HStack {
                        Text("Blood Pressure")
                        Spacer()
                        TextField("Systolic", text: $bloodPressureSystolic)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 50)
                        Text("/")
                        TextField("Diastolic", text: $bloodPressureDiastolic)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 50)
                        Text("mmHg")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Blood Sugar")
                        Spacer()
                        TextField("Value", text: $bloodSugar)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("mmol/L")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Total Cholesterol")
                        Spacer()
                        TextField("Value", text: $cholesterolTotal)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("mmol/L")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("HDL Cholesterol")
                        Spacer()
                        TextField("Value", text: $cholesterolHDL)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("mmol/L")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("LDL Cholesterol")
                        Spacer()
                        TextField("Value", text: $cholesterolLDL)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("mmol/L")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("Alert Preferences")) {
                    Toggle("Alert for Sugar", isOn: $alertForSugar)
                    if alertForSugar {
                        HStack {
                            Text("Threshold")
                            Spacer()
                            TextField("Value", text: $sugarThreshold)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                            Text("g")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.leading)
                    }
                    
                    Toggle("Alert for Sodium", isOn: $alertForSodium)
                    if alertForSodium {
                        HStack {
                            Text("Threshold")
                            Spacer()
                            TextField("Value", text: $sodiumThreshold)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                            Text("mg")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.leading)
                    }
                    
                    Toggle("Alert for Fat", isOn: $alertForFat)
                    if alertForFat {
                        HStack {
                            Text("Threshold")
                            Spacer()
                            TextField("Value", text: $fatThreshold)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                            Text("g")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.leading)
                    }
                    
                    Toggle("Alert for Calories", isOn: $alertForCalories)
                    if alertForCalories {
                        HStack {
                            Text("Threshold")
                            Spacer()
                            TextField("Value", text: $calorieThreshold)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                            Text("kcal")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.leading)
                    }
                    
                    Toggle("Alert for Allergens", isOn: $alertForAllergens)
                }
                
                Section(header: Text("Dietary Preferences")) {
                    ForEach(userProfile.dietaryPreferences, id: \.self) { preference in
                        Text(preference)
                    }
                    .onDelete { indexSet in
                        userProfile.dietaryPreferences.remove(atOffsets: indexSet)
                    }
                    
                    HStack {
                        TextField("Add preference", text: $newPreference)
                        Button(action: {
                            if !newPreference.isEmpty {
                                userProfile.dietaryPreferences.append(newPreference)
                                newPreference = ""
                            }
                        }) {
                            Image(systemName: "plus.circle.fill")
                        }
                    }
                }
                
                Section(header: Text("Allergies")) {
                    ForEach(userProfile.allergies, id: \.self) { allergy in
                        Text(allergy)
                    }
                    .onDelete { indexSet in
                        userProfile.allergies.remove(atOffsets: indexSet)
                    }
                    
                    HStack {
                        TextField("Add allergy", text: $newAllergy)
                        Button(action: {
                            if !newAllergy.isEmpty {
                                userProfile.allergies.append(newAllergy)
                                newAllergy = ""
                            }
                        }) {
                            Image(systemName: "plus.circle.fill")
                        }
                    }
                }
                
                Section(header: Text("Goals")) {
                    ForEach(userProfile.goals, id: \.self) { goal in
                        Text(goal)
                    }
                    .onDelete { indexSet in
                        userProfile.goals.remove(atOffsets: indexSet)
                    }
                    
                    HStack {
                        TextField("Add goal", text: $newGoal)
                        Button(action: {
                            if !newGoal.isEmpty {
                                userProfile.goals.append(newGoal)
                                newGoal = ""
                            }
                        }) {
                            Image(systemName: "plus.circle.fill")
                        }
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveProfile()
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func saveProfile() {
        userProfile.name = name
        userProfile.email = email
        if let age = Int(age) {
            userProfile.age = age
        }
        if let height = Double(height) {
            userProfile.height = height
        }
        if let weight = Double(weight) {
            userProfile.weight = weight
        }
        
        // Save health metrics
        userProfile.bloodPressure = "\(bloodPressureSystolic)/\(bloodPressureDiastolic)"
        if let bloodSugarValue = Double(bloodSugar) {
            userProfile.bloodSugar = bloodSugarValue
        }
        
        let cholesterol = Components.Cholesterol(
            total: Double(cholesterolTotal) ?? userProfile.cholesterol.total,
            hdl: Double(cholesterolHDL) ?? userProfile.cholesterol.hdl,
            ldl: Double(cholesterolLDL) ?? userProfile.cholesterol.ldl
        )
        userProfile.cholesterol = cholesterol
        
        // Save alert preferences
        let alertPrefs = Components.AlertPreferences(
            alertForSugar: alertForSugar,
            alertForSodium: alertForSodium,
            alertForFat: alertForFat,
            alertForCalories: alertForCalories,
            alertForAllergens: alertForAllergens,
            sugarThreshold: Double(sugarThreshold) ?? userProfile.alertPreferences.sugarThreshold,
            sodiumThreshold: Double(sodiumThreshold) ?? userProfile.alertPreferences.sodiumThreshold,
            fatThreshold: Double(fatThreshold) ?? userProfile.alertPreferences.fatThreshold,
            calorieThreshold: Double(calorieThreshold) ?? userProfile.alertPreferences.calorieThreshold
        )
        userProfile.alertPreferences = alertPrefs
        
        userProfile.save()
    }
}

// API Key Setup View
struct APIKeySetupView: View {
    @Binding var isPresented: Bool
    @State private var clarifaiAPIKey = ""
    @State private var logMealAPIKey = ""
    @State private var usdaAPIKey = ""
    @State private var showingSuccessAlert = false
    @State private var successMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Clarifai API Key"),
                        footer: Text("Get your key from")) {
                    TextField("Enter Clarifai API key", text: $clarifaiAPIKey)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    Link("Get your key from", destination: URL(string: "https://www.clarifai.com/")!)
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                Section(header: Text("LogMeal API Key"),
                        footer: Text("Get your key from")) {
                    TextField("Enter LogMeal API key", text: $logMealAPIKey)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    Link("Get your key from", destination: URL(string: "https://logmeal.es/api")!)
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                Section(header: Text("USDA Food Data Central API Key"),
                        footer: Text("Get your key from")) {
                    TextField("Enter USDA API key", text: $usdaAPIKey)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    Link("Get your key from", destination: URL(string: "https://fdc.nal.usda.gov/api-key-signup.html")!)
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                Section {
                    Button("Save API Keys") {
                        saveAPIKeys()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationTitle("API Key Setup")
            .navigationBarItems(trailing: Button("Done") {
                isPresented = false
            })
            .alert(isPresented: $showingSuccessAlert) {
                Alert(
                    title: Text("API Keys Updated"),
                    message: Text(successMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onAppear {
                // Load saved API keys
                let apiKeyManager = APIKeyManager.shared
                
                // Only load keys that aren't default values
                if apiKeyManager.clarifaiAPIKey != "YOUR_CLARIFAI_API_KEY" {
                    clarifaiAPIKey = apiKeyManager.clarifaiAPIKey ?? ""
                }
                
                if apiKeyManager.logMealAPIKey != "YOUR_LOGMEAL_API_KEY" {
                    logMealAPIKey = apiKeyManager.logMealAPIKey ?? ""
                }
                
                if apiKeyManager.usdaAPIKey != "DEMO_KEY" {
                    usdaAPIKey = apiKeyManager.usdaAPIKey ?? ""
                }
            }
        }
    }
    
    private func saveAPIKeys() {
        var success = false
        successMessage = "API Keys updated:"
        
        if !clarifaiAPIKey.isEmpty {
            if APIKeyManager.shared.updateClarifaiAPIKey(clarifaiAPIKey) {
                successMessage += "\n✓ Clarifai API key"
                success = true
            }
        }
        
        if !logMealAPIKey.isEmpty {
            if APIKeyManager.shared.updateLogMealAPIKey(logMealAPIKey) {
                successMessage += "\n✓ LogMeal API key"
                success = true
            }
        }
        
        if !usdaAPIKey.isEmpty {
            if APIKeyManager.shared.updateUSDAAPIKey(usdaAPIKey) {
                successMessage += "\n✓ USDA API key"
                success = true
            }
        }
        
        if !success {
            successMessage = "No API keys were updated."
        }
        
        showingSuccessAlert = true
    }
}

struct SettingsView: View {
    @Binding var isPresented: Bool
    @State private var showingHowToUse = false
    @State private var showingContactUs = false
    @State private var showingPrivacyPolicy = false
    
    // App version from the info dictionary
    private var appVersion: String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
           let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            return "\(version) (\(build))"
        }
        return "1.0.0"
    }
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("App Information")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(appVersion)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("Help & Support")) {
                    NavigationLink(destination: HowToUseView()) {
                        HStack {
                            Image(systemName: "questionmark.circle")
                                .foregroundColor(.blue)
                            Text("How to Use")
                        }
                    }
                    
                    NavigationLink(destination: ContactUsView()) {
                        HStack {
                            Image(systemName: "envelope")
                                .foregroundColor(.green)
                            Text("Contact Us")
                        }
                    }
                }
                
                Section(header: Text("Legal")) {
                    NavigationLink(destination: PrivacyPolicyView()) {
                        HStack {
                            Image(systemName: "lock.shield")
                                .foregroundColor(.red)
                            Text("Privacy Policy")
                        }
                    }
                    
                    NavigationLink(destination: TermsOfServiceView()) {
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundColor(.orange)
                            Text("Terms of Service")
                        }
                    }
                }
                
                Section(header: Text("Data Management")) {
                    Button(action: {
                        // Show confirmation dialog
                        // Implement actual data clearing functionality
                    }) {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                            Text("Clear App Data")
                                .foregroundColor(.red)
                        }
                    }
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("FoodScannerPro")
                            .font(.headline)
                        Spacer()
                    }
                    Text("A powerful tool for food recognition and nutritional analysis, helping you make better food choices and track your dietary habits.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Done") {
                isPresented = false
            })
        }
    }
}

struct HowToUseView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Group {
                    Text("How to Use FoodScannerPro")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.bottom, 5)
                    
                    VStack(alignment: .leading, spacing: 15) {
                        FeatureSection(
                            title: "1. Scan Food",
                            description: "Use the camera button to take a photo of your food. The app will analyze and identify the food items.",
                            icon: "camera.fill"
                        )
                        
                        FeatureSection(
                            title: "2. View Analysis",
                            description: "After scanning, you'll see the nutritional information including calories, proteins, carbs, and fats.",
                            icon: "chart.bar.fill"
                        )
                        
                        FeatureSection(
                            title: "3. Track Progress",
                            description: "All your scans are saved in the history section where you can track your eating habits over time.",
                            icon: "clock.fill"
                        )
                        
                        FeatureSection(
                            title: "4. Set Preferences",
                            description: "Set up dietary preferences and allergies in your profile to get personalized recommendations.",
                            icon: "person.fill"
                        )
                        
                        FeatureSection(
                            title: "5. Get Alerts",
                            description: "Configure nutrition alerts to warn you if a food exceeds your set thresholds for sugar, sodium, or other nutrients.",
                            icon: "bell.fill"
                        )
                    }
                    
                    Text("Tips for Best Results")
                        .font(.headline)
                        .padding(.top, 10)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        TipItem(tip: "Take clear, well-lit photos for more accurate identification")
                        TipItem(tip: "Position the camera directly above the food")
                        TipItem(tip: "Include all items you want to analyze in the frame")
                        TipItem(tip: "For complex meals, scan individual components separately")
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("How to Use")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FeatureSection: View {
    let title: String
    let description: String
    let icon: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(.blue)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct TipItem: View {
    let tip: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            Text(tip)
                .font(.callout)
        }
    }
}

struct ContactUsView: View {
    @State private var name = ""
    @State private var email = ""
    @State private var message = ""
    @State private var selectedIssue = "General Inquiry"
    @State private var showingAlert = false
    
    let issueTypes = ["General Inquiry", "Bug Report", "Feature Request", "Account Issue", "Other"]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Contact Us")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom, 5)
                
                Text("We'd love to hear from you! Fill out the form below and our team will get back to you as soon as possible.")
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Full Name")
                        .font(.headline)
                    TextField("Enter your name", text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.bottom, 10)
                    
                    Text("Email Address")
                        .font(.headline)
                    TextField("Enter your email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding(.bottom, 10)
                    
                    Text("Issue Type")
                        .font(.headline)
                    Picker("Select an issue type", selection: $selectedIssue) {
                        ForEach(issueTypes, id: \.self) {
                            Text($0)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding(.bottom, 10)
                    
                    Text("Message")
                        .font(.headline)
                    TextEditor(text: $message)
                        .frame(minHeight: 150)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .padding(.bottom, 15)
                    
                    Button(action: {
                        submitForm()
                    }) {
                        Text("Submit")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
                
                Divider()
                    .padding(.vertical, 20)
                
                Text("Direct Contact")
                    .font(.headline)
                    .padding(.bottom, 5)
                
                Button(action: {
                    openEmail()
                }) {
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.blue)
                        Text("support@foodscannerpro.com")
                            .foregroundColor(.blue)
                            .underline()
                    }
                }
                .padding(.bottom, 5)
                
                Button(action: {
                    openWebsite()
                }) {
                    HStack {
                        Image(systemName: "globe")
                            .foregroundColor(.blue)
                        Text("www.foodscannerpro.com")
                            .foregroundColor(.blue)
                            .underline()
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Contact Us")
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text("Message Sent"),
                message: Text("Thank you for your message. We'll get back to you soon!"),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func submitForm() {
        // This would normally call to a backend service
        // For demo purposes, just show an alert
        showingAlert = true
        
        // Clear form
        name = ""
        email = ""
        message = ""
        selectedIssue = "General Inquiry"
    }
    
    private func openEmail() {
        if let url = URL(string: "mailto:support@foodscannerpro.com") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openWebsite() {
        if let url = URL(string: "https://www.foodscannerpro.com") {
            UIApplication.shared.open(url)
        }
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                Text("Privacy Policy")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom, 10)
                
                Text("Last Updated: March 18, 2025")
                    .foregroundColor(.secondary)
                    .padding(.bottom, 20)
                
                Group {
                    PolicySection(
                        title: "Introduction",
                        content: "FoodScannerPro is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our application."
                    )
                    
                    PolicySection(
                        title: "Information We Collect",
                        content: "We collect information that you provide directly to us, such as when you create an account, update your profile, use our features, or contact us. This may include your name, email address, profile picture, health information, and dietary preferences."
                    )
                    
                    PolicySection(
                        title: "How We Use Your Information",
                        content: "We use the information we collect to provide, maintain, and improve our services; to develop new features; to process transactions; to communicate with you; and to protect our services and users."
                    )
                    
                    PolicySection(
                        title: "Sharing Your Information",
                        content: "We do not share your personal information with third parties except as described in this Privacy Policy. We may share information with service providers who perform services on our behalf, for legal reasons, or in connection with a business transfer."
                    )
                    
                    PolicySection(
                        title: "Data Storage and Security",
                        content: "Your data is stored on your device and in our secure cloud servers. We implement appropriate security measures to protect your information from unauthorized access or disclosure."
                    )
                    
                    PolicySection(
                        title: "Your Rights",
                        content: "You have the right to access, correct, or delete your personal information. You can manage your information through the app settings or by contacting us."
                    )
                    
                    PolicySection(
                        title: "Changes to This Policy",
                        content: "We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new policy in the app and updating the 'Last Updated' date."
                    )
                    
                    PolicySection(
                        title: "Contact Us",
                        content: "If you have any questions about this Privacy Policy, please contact us at privacy@foodscannerpro.com."
                    )
                }
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PolicySection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .padding(.bottom, 2)
            
            Text(content)
                .font(.body)
                .foregroundColor(.secondary)
            
            Divider()
                .padding(.vertical, 10)
        }
    }
}

struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                Text("Terms of Service")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom, 10)
                
                Text("Last Updated: March 18, 2025")
                    .foregroundColor(.secondary)
                    .padding(.bottom, 20)
                
                Group {
                    PolicySection(
                        title: "Acceptance of Terms",
                        content: "By using FoodScannerPro, you agree to these Terms of Service. If you do not agree, please do not use the application."
                    )
                    
                    PolicySection(
                        title: "Description of Service",
                        content: "FoodScannerPro provides food recognition and nutritional analysis services. The app allows you to scan food items using your device's camera and receive information about nutritional content."
                    )
                    
                    PolicySection(
                        title: "User Accounts",
                        content: "You may need to create an account to use certain features. You are responsible for maintaining the confidentiality of your account credentials and for all activities under your account."
                    )
                    
                    PolicySection(
                        title: "User Responsibilities",
                        content: "You agree to use the app lawfully and in compliance with these terms. You will not use the app for any illegal purposes or in any manner that could damage or impair the app's functionality."
                    )
                    
                    PolicySection(
                        title: "Intellectual Property",
                        content: "The app and its content, features, and functionality are owned by FoodScannerPro and are protected by copyright, trademark, and other intellectual property laws."
                    )
                    
                    PolicySection(
                        title: "Disclaimer of Warranties",
                        content: "The app is provided 'as is' without warranties of any kind. We do not guarantee the accuracy of food recognition or nutritional information provided by the app."
                    )
                    
                    PolicySection(
                        title: "Limitation of Liability",
                        content: "We shall not be liable for any indirect, incidental, special, consequential, or punitive damages, including loss of profits, data, or other intangible losses."
                    )
                    
                    PolicySection(
                        title: "Changes to Terms",
                        content: "We may update these Terms of Service from time to time. We will notify you of any changes by posting the new terms in the app and updating the 'Last Updated' date."
                    )
                }
            }
            .padding()
        }
        .navigationTitle("Terms of Service")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ProfileView()
} 