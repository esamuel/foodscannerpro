import SwiftUI
import PhotosUI

struct ProfileView: View {
    @StateObject private var userProfile = UserProfile.shared
    @State private var isEditingProfile = false
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var showingAPIKeySetup = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
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
                    
                    // User Name
                    Text(userProfile.name)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    // User Email
                    Text(userProfile.email)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    // User Stats
                    VStack(spacing: 15) {
                        HStack(spacing: 30) {
                            StatView(title: "Age", value: "\(userProfile.age)")
                            StatView(title: "Height", value: "\(Int(userProfile.height)) cm")
                            StatView(title: "Weight", value: "\(Int(userProfile.weight)) kg")
                        }
                        
                        // BMI
                        HStack {
                            Text("BMI:")
                                .font(.headline)
                            Text(String(format: "%.1f", userProfile.bmi))
                                .font(.headline)
                            Text("(\(userProfile.bmiCategory))")
                                .font(.subheadline)
                                .foregroundColor(bmiColor(for: userProfile.bmiCategory))
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(15)
                    .padding(.horizontal)
                    
                    // Dietary Preferences
                    SectionView(title: "Dietary Preferences", items: userProfile.dietaryPreferences)
                    
                    // Allergies
                    SectionView(title: "Allergies", items: userProfile.allergies)
                    
                    // Goals
                    SectionView(title: "Goals", items: userProfile.goals)
                    
                    // Edit Profile Button
                    Button(action: {
                        isEditingProfile = true
                    }) {
                        Text("Edit Profile")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    
                    // API Key Setup Button
                    Button(action: {
                        showingAPIKeySetup = true
                    }) {
                        HStack {
                            Image(systemName: "key.fill")
                                .font(.headline)
                            Text("Setup API Keys")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                }
                .padding(.bottom, 30)
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $isEditingProfile) {
                EditProfileView(userProfile: userProfile, isPresented: $isEditingProfile)
            }
            .sheet(isPresented: $showingImagePicker) {
                ModernImagePicker(selectedImage: $selectedImage, sourceType: .photoLibrary)
                    .onDisappear {
                        if let image = selectedImage {
                            userProfile.profileImage = image
                            userProfile.save()
                        }
                    }
            }
            .background(
                EmptyView().sheet(isPresented: $showingAPIKeySetup) {
                    APIKeySetupView(isPresented: $showingAPIKeySetup)
                }
            )
        }
    }
    
    private func bmiColor(for category: String) -> Color {
        switch category {
        case "Underweight":
            return .orange
        case "Normal weight":
            return .green
        case "Overweight":
            return .yellow
        case "Obese":
            return .red
        default:
            return .gray
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
    
    init(userProfile: UserProfile, isPresented: Binding<Bool>) {
        self.userProfile = userProfile
        _name = State(initialValue: userProfile.name)
        _email = State(initialValue: userProfile.email)
        _age = State(initialValue: String(userProfile.age))
        _height = State(initialValue: String(userProfile.height))
        _weight = State(initialValue: String(userProfile.weight))
        _isPresented = isPresented
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
        userProfile.age = Int(age) ?? userProfile.age
        userProfile.height = Double(height) ?? userProfile.height
        userProfile.weight = Double(weight) ?? userProfile.weight
        userProfile.save()
    }
}

// API Key Setup View
struct APIKeySetupView: View {
    @Binding var isPresented: Bool
    @State private var clarifaiKey = ""
    @State private var logMealKey = ""
    @State private var usdaKey = ""
    @State private var showingSuccessAlert = false
    @State private var successMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Clarifai API Key"),
                        footer: Text("Get your key from https://www.clarifai.com/")) {
                    TextField("Enter Clarifai API Key", text: $clarifaiKey)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                
                Section(header: Text("LogMeal API Key"),
                        footer: Text("Get your key from https://logmeal.es/api")) {
                    TextField("Enter LogMeal API Key", text: $logMealKey)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                
                Section(header: Text("USDA Food Data Central API Key"),
                        footer: Text("Get your key from https://fdc.nal.usda.gov/api-key-signup.html")) {
                    TextField("Enter USDA API Key", text: $usdaKey)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
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
        }
    }
    
    private func saveAPIKeys() {
        var success = false
        successMessage = "API Keys updated:"
        
        if !clarifaiKey.isEmpty {
            if APIKeyManager.shared.updateClarifaiAPIKey(clarifaiKey) {
                successMessage += "\n✓ Clarifai API key"
                success = true
            }
        }
        
        if !logMealKey.isEmpty {
            if APIKeyManager.shared.updateLogMealAPIKey(logMealKey) {
                successMessage += "\n✓ LogMeal API key"
                success = true
            }
        }
        
        if !usdaKey.isEmpty {
            if APIKeyManager.shared.updateUSDAAPIKey(usdaKey) {
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

#Preview {
    ProfileView()
} 