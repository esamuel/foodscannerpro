//
//  ContentView.swift
//  foodscannerpro
//
//  Created by Samuel Eskenasy on 3/12/25.
//

import SwiftUI
import PhotosUI
import UIKit
import CoreML
import Vision
import CoreData
import Combine
import Charts

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedTab = 0
    @State private var showingCamera = false
    @State private var showingFeatureTour = false
    @AppStorage("hasCompletedFeatureTour") private var hasCompletedFeatureTour = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView(tabSelection: $selectedTab, showingCamera: $showingCamera)
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }
                    .tag(0)
                
                RecommendationsView()
                    .tabItem {
                        Label("Recommendations", systemImage: "heart.fill")
                    }
                    .tag(1)
                
                // Empty tab for the center camera button
                Color.clear
                    .tabItem {
                        Label("", systemImage: "")
                    }
                    .tag(2)
                
                AnalyticsView()
                    .tabItem {
                        Label("Analytics", systemImage: "chart.bar.fill")
                    }
                    .tag(3)
                
                EnhancedHistoryView()
                    .tabItem {
                        Label("History", systemImage: "clock.fill")
                    }
                    .tag(4)
                
                ProfileView()
                    .tabItem {
                        Label("Profile", systemImage: "person.fill")
                    }
                    .tag(5)
            }
            .accentColor(.green)
            .safeAreaInset(edge: .bottom) {
                // Add extra padding at the bottom to accommodate the floating button
                Color.clear.frame(height: 20)
            }
            
            // Custom scan button
            Button {
                showingCamera = true
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 70, height: 70)
                        .shadow(radius: 4)
                    
                    Image(systemName: "camera.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                }
            }
            .offset(y: -15) // Move up to overlap the tab bar
            
            // Fullscreen cover for camera
            .fullScreenCover(isPresented: $showingCamera) {
                CameraView(tabSelection: $selectedTab)
            }
            
            // Feature tour overlay
            if showingFeatureTour {
                FeatureTourView(isShowingTour: $showingFeatureTour)
                    .transition(.opacity)
                    .zIndex(100) // Ensure it's above everything else
            }
        }
        .onAppear {
            // Customize tab bar appearance
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .systemBackground
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
            
            // Customize navigation bar appearance
            let navigationAppearance = UINavigationBarAppearance()
            navigationAppearance.configureWithOpaqueBackground()
            navigationAppearance.backgroundColor = .systemBackground
            navigationAppearance.titleTextAttributes = [.foregroundColor: UIColor.label]
            navigationAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
            
            UINavigationBar.appearance().standardAppearance = navigationAppearance
            UINavigationBar.appearance().scrollEdgeAppearance = navigationAppearance
            UINavigationBar.appearance().compactAppearance = navigationAppearance
            
            // Check if we should show the feature tour
            if !hasCompletedFeatureTour {
                // Delay the tour slightly to ensure the UI is fully loaded
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    showingFeatureTour = true
                    hasCompletedFeatureTour = true
                }
            }
        }
    }
}

struct GalleryImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        // This ensures the picker works even with limited photo access
        config.preferredAssetRepresentationMode = .current
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: GalleryImagePicker
        
        init(_ parent: GalleryImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()
            
            guard let provider = results.first?.itemProvider else { return }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, _ in
                    DispatchQueue.main.async {
                        self.parent.image = image as? UIImage
                    }
                }
            }
        }
    }
}

struct LegacyImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    @Binding var showRecognition: Bool
    
    init(image: Binding<UIImage?>, showRecognition: Binding<Bool>) {
        self._image = image
        self._showRecognition = showRecognition
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: LegacyImagePicker
        
        init(_ parent: LegacyImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
                parent.showRecognition = true
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Home View Components
struct SearchBarView: View {
    @Binding var searchText: String
    @Binding var isSearching: Bool
    let filteredResults: [String]
    let onResultSelected: (String) -> Void
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Search foods", text: $searchText)
                    .onChange(of: searchText) { oldValue, newValue in
                        isSearching = !newValue.isEmpty
                    }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(15)
            .padding(.horizontal)
            
            if isSearching {
                SearchResultsView(
                    results: filteredResults,
                    onResultSelected: onResultSelected
                )
            }
        }
    }
}

struct SearchResultsView: View {
    let results: [String]
    let onResultSelected: (String) -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading) {
                ForEach(results, id: \.self) { food in
                    Button(action: { onResultSelected(food) }) {
                        Text(food)
                            .padding(.vertical, 8)
                            .padding(.horizontal)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Divider()
                }
            }
        }
        .frame(maxHeight: 200)
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .padding(.horizontal)
    }
}

struct ScanOptionsView: View {
    let onCameraSelected: () -> Void
    let onGallerySelected: () -> Void
    
    var body: some View {
        VStack(spacing: 15) {
            Text("Scan Food")
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            
            HStack(spacing: 20) {
                ScanOptionButton(
                    title: "Take Photo",
                    icon: "camera.fill",
                    color: .green,
                    action: onCameraSelected
                )
                
                ScanOptionButton(
                    title: "From Gallery",
                    icon: "photo.on.rectangle",
                    color: .blue,
                    action: onGallerySelected
                )
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
}

struct ScanOptionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(color)
                }
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(15)
        }
    }
}

struct QuickAccessGridView: View {
    @Binding var tabSelection: Int
    
    var body: some View {
        VStack(spacing: 15) {
            Text("Quick Access")
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 20) {
                QuickAccessButton(icon: "chart.bar.fill", title: "Analytics", color: .blue) {
                    tabSelection = 3
                }
                QuickAccessButton(icon: "clock.fill", title: "History", color: .purple) {
                    tabSelection = 4
                }
                QuickAccessButton(icon: "heart.fill", title: "Recommendations", color: .red) {
                    tabSelection = 1
                }
                QuickAccessButton(icon: "person.fill", title: "Profile", color: .orange) {
                    tabSelection = 5
                }
                QuickAccessButton(icon: "star.fill", title: "Premium", color: .yellow) {
                    // Premium action
                }
                QuickAccessButton(icon: "fork.knife", title: "Meal Plans", color: .green) {
                    // Meal plans action
                }
            }
            .padding(.horizontal)
        }
    }
}

struct QuickAccessButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(color)
                }
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

struct HomeView: View {
    @State private var searchText = ""
    @State private var isSearching = false
    @State private var selectedImage: UIImage?
    @State private var showingPreview = false
    @State private var showingRecognition = false
    @State private var showingLegacyPicker = false
    @Binding var tabSelection: Int
    @Binding var showingCamera: Bool
    
    private let foodDatabase = [
        "Apple", "Banana", "Chicken Breast", "Greek Yogurt",
        "Salmon", "Quinoa", "Avocado", "Sweet Potato",
        "Broccoli", "Eggs", "Oatmeal", "Almonds"
    ]
    
    private var filteredResults: [String] {
        guard !searchText.isEmpty else { return [] }
        return foodDatabase.filter { $0.lowercased().contains(searchText.lowercased()) }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    SearchBarView(
                        searchText: $searchText,
                        isSearching: $isSearching,
                        filteredResults: filteredResults
                    ) { result in
                        searchText = result
                        isSearching = false
                    }
                    
                    ScanOptionsView(
                        onCameraSelected: { showingCamera = true },
                        onGallerySelected: {
                            selectedImage = nil
                            showingRecognition = false
                            showingLegacyPicker = true
                        }
                    )
                    
                    QuickAccessGridView(tabSelection: $tabSelection)
                    
                    FeaturedMealsView()
                    
                    Spacer(minLength: 50)
                }
            }
            .navigationTitle("Food Scanner Pro")
            .sheet(isPresented: $showingPreview) {
                if let image = selectedImage {
                    ImagePreviewView(image: image, isPresented: $showingPreview, tabSelection: $tabSelection)
                }
            }
            .sheet(isPresented: $showingLegacyPicker) {
                LegacyImagePicker(image: $selectedImage, showRecognition: $showingRecognition)
            }
        }
        .fullScreenCover(isPresented: $showingRecognition) {
            if let image = selectedImage {
                FoodRecognitionView(
                    image: image,
                    classifier: FoodClassifier(),
                    rootIsPresented: $showingRecognition,
                    tabSelection: $tabSelection
                )
            }
        }
        .onChange(of: selectedImage) { oldValue, newValue in
            if newValue != nil && !showingLegacyPicker {
                showingPreview = true
            }
        }
        .onChange(of: showingRecognition) { oldValue, newValue in
            if !newValue {
                selectedImage = nil
            }
        }
    }
}

struct FeatureButton: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        VStack {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

// Add this class before the FoodClassifier class
class AdjustableObservation {
    let identifier: String
    var confidence: Float
    
    init(observation: VNClassificationObservation) {
        self.identifier = observation.identifier
        self.confidence = observation.confidence
    }
    
    init(identifier: String, confidence: Float) {
        self.identifier = identifier
        self.confidence = confidence
    }
}

class FoodClassifier: ObservableObject {
    @Published var recognizedObjects: [RecognizedFood] = []
    @Published var isProcessing = false
    @Published var healthRecommendations: [FoodRecommendation] = []
    
    // Add a serial queue for thread-safe array updates
    private let updateQueue = DispatchQueue(label: "com.foodscannerpro.arrayupdates")
    
    // Expanded food keywords for better recognition
    private let foodKeywords = [
        // Basic food categories
        "food", "fruit", "vegetable", "meat", "dish", "bread", "cake", "soup", "salad", "sandwich",
        
        // Common fruits with high priority (add these at the beginning)
        "banana", "apple", "orange", "grape", "strawberry", "blueberry", "raspberry", "pineapple",
        
        // Fruits
        "mango", "peach", "pear", "plum", "watermelon", "kiwi", "cherry", "lemon", "lime", "coconut",
        "fig", "date", "grapefruit", "pomegranate", "apricot", "blackberry", "cantaloupe",
        
        // Vegetables
        "broccoli", "spinach", "kale", "lettuce", "cabbage", "carrot", "potato", "tomato", "cucumber",
        "onion", "garlic", "pepper", "eggplant", "zucchini", "squash", "pumpkin", "corn", "pea",
        "bean", "asparagus", "celery", "radish", "beet", "turnip", "cauliflower", "brussels sprout",
        
        // Proteins
        "chicken", "beef", "pork", "fish", "salmon", "tuna", "shrimp", "lobster", "crab", "tofu",
        "tempeh", "seitan", "egg", "turkey", "duck", "lamb", "venison", "bison", "sausage", "bacon",
        "ham", "steak", "ground beef", "chicken breast", "thigh", "drumstick", "filet", "ribeye",
        
        // Dairy
        "cheese", "yogurt", "milk", "cream", "butter", "ice cream", "cottage cheese", "sour cream",
        "cheddar", "mozzarella", "parmesan", "feta", "gouda", "brie", "ricotta", "cream cheese",
        
        // Grains
        "pasta", "rice", "bread", "cereal", "oats", "quinoa", "barley", "couscous", "noodle",
        "spaghetti", "macaroni", "penne", "fettuccine", "linguine", "ramen", "udon", "tortilla",
        "bagel", "croissant", "roll", "bun", "muffin", "pancake", "waffle", "toast", "cracker",
        
        // Prepared foods
        "pizza", "burger", "hotdog", "taco", "burrito", "sushi", "curry", "stew", "roast", "stir fry",
        "casserole", "lasagna", "pie", "quiche", "omelette", "sandwich", "wrap", "salad", "soup",
        "chili", "pasta dish", "rice dish", "noodle dish", "bowl", "platter", "buffet", "appetizer",
        
        // Desserts
        "chocolate", "cookie", "cake", "pie", "ice cream", "dessert", "candy", "pastry", "brownie",
        "cupcake", "donut", "muffin", "cheesecake", "pudding", "mousse", "tart", "cobbler", "crumble",
        
        // Snacks
        "snack", "nut", "seed", "chip", "cracker", "popcorn", "pretzel", "granola", "trail mix",
        "energy bar", "protein bar", "fruit snack", "jerky", "dried fruit", "nut butter",
        
        // Beverages
        "coffee", "tea", "juice", "smoothie", "drink", "beverage", "water", "soda", "alcohol",
        "wine", "beer", "cocktail", "milk", "latte", "cappuccino", "espresso", "mocha", "frappe",
        
        // Meal types
        "breakfast", "lunch", "dinner", "brunch", "snack", "appetizer", "entree", "side dish",
        "dessert", "main course", "meal", "feast", "banquet", "buffet", "platter", "course",
        
        // Cooking methods
        "baked", "grilled", "fried", "roasted", "steamed", "boiled", "sauteed", "stir-fried",
        "smoked", "poached", "braised", "broiled", "raw", "cured", "pickled", "fermented",
        
        // Cuisines
        "italian", "mexican", "chinese", "japanese", "indian", "thai", "french", "mediterranean",
        "greek", "spanish", "korean", "vietnamese", "american", "cajun", "creole", "middle eastern",
        "moroccan", "ethiopian", "german", "british", "irish", "russian", "brazilian", "peruvian"
    ]
    
    // Confidence thresholds
    private let minimumConfidence: Float = 0.4
    private let highConfidenceThreshold: Float = 0.8
    
    // Reference to the nutrition service
    private let nutritionService = NutritionService.shared
    
    // Reference to the health service
    private let healthService = HealthService.shared
    
    // Queue for handling nutrition lookups
    private let nutritionQueue = DispatchQueue(label: "com.foodscannerpro.nutritionqueue", attributes: .concurrent)
    private let nutritionGroup = DispatchGroup()
    
    // Feedback manager for improving recognition
    private let feedbackManager = FeedbackManager.shared
    
    init() {
        // Load feedback data when initialized
        feedbackManager.loadFeedback()
    }
    
    func analyzeImage(_ image: UIImage) {
        isProcessing = true
        recognizedObjects.removeAll()
        healthRecommendations = healthService.generateRecommendations()
        
        // Add a small delay to allow UI to update before starting processing
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self, let cgImage = image.cgImage else {
                DispatchQueue.main.async {
                    self?.isProcessing = false
                }
                return
            }
            
            // Create a request handler with orientation
            let requestHandler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])
            
            // Create classification request
            let classificationRequest = VNClassifyImageRequest()
            
            do {
                // Perform the classification request
                try requestHandler.perform([classificationRequest])
                
                // Process classification results
                if let observations = classificationRequest.results as? [VNClassificationObservation] {
                    // Convert VNClassificationObservation to AdjustableObservation
                    var adjustableObservations = observations.map { AdjustableObservation(observation: $0) }
                    
                    // Step 1: Filter by food keywords
                    adjustableObservations = self.filterByFoodKeywords(adjustableObservations)
                    
                    // Step 2: Filter by minimum confidence
                    adjustableObservations = self.filterByConfidence(adjustableObservations)
                    
                    // Step 3: Apply feedback-based corrections
                    self.applyFeedbackCorrections(to: &adjustableObservations)
                    
                    // Step 4: Sort by confidence
                    adjustableObservations.sort { $0.confidence > $1.confidence }
                    
                    // Step 5: Process the results
                        DispatchQueue.main.async {
                        if !adjustableObservations.isEmpty {
                            self.processObservations(Array(adjustableObservations.prefix(5)))
                        } else {
                            // Convert observations for backup processing
                            let originalObservations = observations.prefix(10).map { observation in
                                VNClassificationObservation(identifier: observation.identifier, confidence: observation.confidence)
                            }
                            self.tryBackupRecognition(originalObservations)
                        }
                    }
                }
            } catch {
                print("Failed to perform classification: \(error)")
                DispatchQueue.main.async {
                    self.isProcessing = false
                }
            }
        }
    }
    
    private func filterByFoodKeywords(_ observations: [AdjustableObservation]) -> [AdjustableObservation] {
        observations.filter { observation in
            let name = observation.identifier.lowercased()
            return self.foodKeywords.contains { keyword in
                name.contains(keyword.lowercased())
            }
        }
    }
    
    private func filterByConfidence(_ observations: [AdjustableObservation]) -> [AdjustableObservation] {
        observations.filter { observation in
            observation.confidence > self.minimumConfidence
        }
    }
    
    // Update the method signature to use AdjustableObservation
    private func processObservations(_ observations: [AdjustableObservation]) {
        // Create a temporary array to hold recognized objects
        var tempRecognizedObjects: [RecognizedFood] = []
        let processingQueue = DispatchQueue(label: "com.foodscannerpro.processing", attributes: .concurrent)
        let processingGroup = DispatchGroup()
        let syncQueue = DispatchQueue(label: "com.foodscannerpro.sync")
        
        // Process each observation
        for observation in observations {
            // Clean up the identifier to get a more readable name
            let name = cleanUpFoodName(observation.identifier)
            
            // Enter the dispatch group
            processingGroup.enter()
            
            // Get nutrition info on a background queue
            processingQueue.async {
                self.processNutritionInfo(name: name, observation: observation) { recognizedFood in
                    syncQueue.async {
                        tempRecognizedObjects.append(recognizedFood)
                        processingGroup.leave()
                    }
                }
            }
        }
        
        // Wait for all nutrition lookups to complete
        processingGroup.notify(queue: .main) {
            // Sort by confidence
            self.recognizedObjects = tempRecognizedObjects.sorted(by: { $0.confidence > $1.confidence })
            self.isProcessing = false
        }
    }

    private func processNutritionInfo(
        name: String,
        observation: AdjustableObservation,
        completion: @escaping (RecognizedFood) -> Void
    ) {
        self.nutritionService.getNutritionInfo(for: name) { result in
            switch result {
            case .success(let nutritionInfo):
                let foodNutrition = FoodNutrition(
                    calories: Double(nutritionInfo.calories),
                    protein: nutritionInfo.protein,
                    carbs: nutritionInfo.carbs,
                    fats: nutritionInfo.fat
                )
                
                let additionalNutrition = self.createAdditionalNutrition(from: nutritionInfo.toNutritionInfo())
                
                let warnings = self.healthService.checkForWarnings(foodName: name)
                let isRecommended = self.isRecommendedFood(name)
                let recommendationReason = self.getRecommendationReason(name)
                
                let recognizedFood = RecognizedFood(
                    name: name,
                    confidence: observation.confidence,
                    boundingBox: .init(x: 0, y: 0, width: 1, height: 1),
                    estimatedNutrition: foodNutrition,
                    additionalNutrition: additionalNutrition,
                    nutritionSource: nutritionInfo.source,
                    dietaryWarnings: warnings.isEmpty ? nil : warnings,
                    isRecommended: isRecommended,
                    recommendationReason: recommendationReason
                )
                completion(recognizedFood)
                
            case .failure(let error):
                print("Failed to get nutrition info for \(name): \(error.localizedDescription)")
                let defaultFood = self.createDefaultRecognizedFood(
                    name: name,
                    confidence: observation.confidence
                )
                completion(defaultFood)
            }
        }
    }
    
    private func createRecognizedFood(
        from nutritionInfo: FoodNutritionInfo,
        observation: AdjustableObservation
    ) -> RecognizedFood {
        // Create food nutrition
        let foodNutrition = FoodNutrition(
            calories: Double(nutritionInfo.calories),
            protein: nutritionInfo.protein,
            carbs: nutritionInfo.carbs,
            fats: nutritionInfo.fat  // Changed from fats to fat to match FoodNutritionInfo
        )
        
        // Create additional nutrition info
        let additionalNutrition = self.createAdditionalNutrition(from: nutritionInfo.toNutritionInfo())
        
        // Check for dietary warnings
        let warnings = self.healthService.checkForWarnings(foodName: nutritionInfo.foodName)
        
        // Check if this food is recommended
        let isRecommended = self.isRecommendedFood(nutritionInfo.foodName)
        let recommendationReason = self.getRecommendationReason(nutritionInfo.foodName)
        
        return RecognizedFood(
            name: nutritionInfo.foodName,
            confidence: observation.confidence,
            boundingBox: .init(x: 0, y: 0, width: 1, height: 1),
            estimatedNutrition: foodNutrition,
            additionalNutrition: additionalNutrition,
            nutritionSource: nutritionInfo.source,
            dietaryWarnings: warnings.isEmpty ? nil : warnings,
            isRecommended: isRecommended,
            recommendationReason: recommendationReason
        )
    }
    
    private func createAdditionalNutrition(from nutritionInfo: NutritionInfo) -> AdditionalNutrition {
        return AdditionalNutrition(
            fiber: nutritionInfo.fiber,
            sugar: nutritionInfo.sugar,
            sodium: nutritionInfo.minerals["sodium"],
            cholesterol: nutritionInfo.minerals["cholesterol"],
            potassium: nutritionInfo.minerals["potassium"],
            calcium: nutritionInfo.minerals["calcium"],
            iron: nutritionInfo.minerals["iron"],
            vitaminA: nutritionInfo.vitamins["A"],
            vitaminC: nutritionInfo.vitamins["C"],
            servingSize: nil, // These are not part of NutritionInfo
            servingUnit: nil  // These are not part of NutritionInfo
        )
    }
    
    // Update the method signature to use AdjustableObservation
    private func applyFeedbackCorrections(to observations: inout [AdjustableObservation]) {
        let feedbackData = feedbackManager.feedbackData
        
        // Create dictionaries for corrections and misclassifications
        var corrections: [String: [(String, Float)]] = [:]
        var commonMisclassifications: [String: Set<String>] = [:]
        
        // Process feedback data
        processFeedbackData(feedbackData, corrections: &corrections, misclassifications: &commonMisclassifications)
        
        // Process each observation
        var processedObservations: [AdjustableObservation] = []
        
        for observation in observations {
            if let adjustedObservation = processObservation(
                observation,
                corrections: corrections,
                misclassifications: commonMisclassifications
            ) {
                processedObservations.append(adjustedObservation)
            }
        }
        
        // Update the original observations array
        observations = processedObservations
    }
    
    private func processFeedbackData(
        _ feedbackData: [FeedbackEntry],
        corrections: inout [String: [(String, Float)]],
        misclassifications: inout [String: Set<String>]
    ) {
        for entry in feedbackData {
            guard entry.feedback == .incorrect,
                  let correctName = entry.correctFoodName else {
                continue
            }
            
            let cleanName = cleanUpFoodName(entry.foodName).lowercased()
            
            // Initialize arrays if needed
            if corrections[cleanName] == nil {
                corrections[cleanName] = []
            }
            if misclassifications[cleanName] == nil {
                misclassifications[cleanName] = Set<String>()
            }
            
            // Add corrections
            corrections[cleanName]?.append((correctName, Float(entry.confidence)))
            misclassifications[cleanName]?.insert(correctName.lowercased())
        }
    }
    
    private func processObservation(
        _ observation: AdjustableObservation,
        corrections: [String: [(String, Float)]],
        misclassifications: [String: Set<String>]
    ) -> AdjustableObservation? {
        // Step 1: Clean up name
        let cleanName = cleanUpFoodName(observation.identifier).lowercased()
        
        // Step 2: Check for corrections
        if let correctedObservation = checkForCorrections(
            observation: observation,
            cleanName: cleanName,
            corrections: corrections
        ) {
            return applyFiltersAndAdjustments(
                correctedObservation,
                misclassifications: misclassifications
            )
        }
        
        // Step 3: If no corrections, apply filters and adjustments to original
        return applyFiltersAndAdjustments(
            observation,
            misclassifications: misclassifications
        )
    }
    
    private func checkForCorrections(
        observation: AdjustableObservation,
        cleanName: String,
        corrections: [String: [(String, Float)]]
    ) -> AdjustableObservation? {
        guard let correctionsList = corrections[cleanName] else {
            return nil
        }
        
        // Count corrections
        var counts: [String: Int] = [:]
        for (correction, _) in correctionsList {
            counts[correction, default: 0] += 1
        }
        
        // Find most frequent correction
        guard let mostFrequent = counts.max(by: { $0.value < $1.value })?.key else {
            return nil
        }
        
        return AdjustableObservation(
            identifier: mostFrequent,
            confidence: observation.confidence
        )
    }
    
    private func applyFiltersAndAdjustments(
        _ observation: AdjustableObservation,
        misclassifications: [String: Set<String>]
    ) -> AdjustableObservation? {
        let name = observation.identifier.lowercased()
        
        // Check confidence threshold
        if observation.confidence < 0.8 {
            if isGenericTerm(name) {
                return nil
            }
        }
        
        // Check for problematic classifications
        if isProblematicClassification(name: name, confidence: observation.confidence, misclassifications: misclassifications) {
            return nil
        }
        
        // Apply confidence adjustments
        return adjustConfidence(observation)
    }
    
    private func isGenericTerm(_ name: String) -> Bool {
        let genericTerms = ["food", "edible", "ingredient", "meal", "dish"]
        return genericTerms.contains(where: { name.contains($0) })
    }
    
    private func isProblematicClassification(
        name: String,
        confidence: Float,
        misclassifications: [String: Set<String>]
    ) -> Bool {
        if name.contains("oats") && confidence < 0.95 {
            if let commonCorrections = misclassifications[name] {
                return commonCorrections.contains("banana")
            }
        }
        return false
    }
    
    private func adjustConfidence(_ observation: AdjustableObservation) -> AdjustableObservation {
        let name = observation.identifier.lowercased()
        var result = observation
        
        if name.contains("banana") && observation.confidence > 0.6 {
            result.confidence = min(1.0, observation.confidence * 1.2)
        }
        
        return result
    }
    
    // Clean up food name for better readability
    private func cleanUpFoodName(_ name: String) -> String {
        // Remove any text in parentheses and their contents
        var cleanName = name.replacingOccurrences(of: "\\([^)]+\\)", with: "", options: .regularExpression)
        
        // Remove USDA program references
        cleanName = cleanName.replacingOccurrences(of: "Includes foods? for USDA'?s? [^,]+", with: "", options: .regularExpression)
        
        // Split by comma and take the first meaningful part
        let parts = cleanName.components(separatedBy: ",")
        cleanName = parts.first { part in
            let cleaned = part.trimmingCharacters(in: .whitespacesAndNewlines)
            // Skip parts that are too short or contain certain keywords
            return cleaned.count >= 3 && 
                   !cleaned.lowercased().contains("usda") &&
                   !cleaned.lowercased().contains("program") &&
                   !cleaned.lowercased().contains("distribution")
        } ?? parts[0]
        
        // Clean up extra whitespace
        cleanName = cleanName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove any remaining parentheses and their contents
        cleanName = cleanName.replacingOccurrences(of: "\\([^)]+\\)", with: "", options: .regularExpression)
        
        // Capitalize first letter of each word
        let words = cleanName.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        let capitalizedWords = words.map { word in
            if word.count > 0 {
                let firstChar = word.prefix(1).uppercased()
                let restOfWord = word.dropFirst().lowercased()
                return firstChar + restOfWord
            }
            return word
        }
        
        return capitalizedWords.joined(separator: " ")
    }
    
    // Check if a food is recommended based on health profile
    private func isRecommendedFood(_ foodName: String) -> Bool {
        return healthService.isRecommendedFood(foodName)
    }
    
    // Get recommendation reason for a food
    private func getRecommendationReason(_ foodName: String) -> String? {
        return healthService.getRecommendationReason(foodName)
    }
    
    // Add shape analysis function
    private func analyzeShape(_ contours: [VNContour]) -> String {
        // Get the bounding box of the largest contour
        let largestContour = contours.max { contour1, contour2 in
            let box1 = contour1.normalizedPath.boundingBox
            let box2 = contour2.normalizedPath.boundingBox
            let area1 = box1.width * box1.height
            let area2 = box2.width * box2.height
            return area1 < area2
        }
        
        guard let contour = largestContour else {
            return "unknown"
        }
        
        let box = contour.normalizedPath.boundingBox
        let aspectRatio = box.width / box.height
        
        if aspectRatio > 1.5 {
            return "elongated"  // Likely a banana or similar elongated shape
        } else if aspectRatio >= 0.8 && aspectRatio <= 1.2 {
            return "round"      // Likely an apple or similar round shape
        } else {
            return "unknown"
        }
    }
    
    private func tryBackupRecognition(_ observations: [VNClassificationObservation]) {
        // Create a backup array
        var backupObjects: [RecognizedFood] = []
        let processingQueue = DispatchQueue(label: "com.foodscannerpro.backupprocessing", attributes: .concurrent)
        let processingGroup = DispatchGroup()
        let syncQueue = DispatchQueue(label: "com.foodscannerpro.backupsync")
        
        // Process each observation
        for observation in observations {
            // Get components from the identifier
            let components = observation.identifier.components(separatedBy: ",")
            
            // Process each component
            for component in components {
                let name = component.trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Skip very short names
                if name.count < 3 {
                    continue
                }
                
                // Enter the dispatch group
                processingGroup.enter()
                
                // Process on background queue
                processingQueue.async {
                    self.processBackupComponent(
                        name: name,
                        confidence: observation.confidence
                    ) { recognizedFood in
                        syncQueue.async {
                            backupObjects.append(recognizedFood)
                            processingGroup.leave()
                        }
                    }
                }
            }
        }
        
        // Wait for all backup nutrition lookups to complete
        processingGroup.notify(queue: .main) {
            self.recognizedObjects = backupObjects.sorted(by: { $0.confidence > $1.confidence })
            self.isProcessing = false
        }
    }

    private func processBackupComponent(
        name: String,
        confidence: Float,
        completion: @escaping (RecognizedFood) -> Void
    ) {
        self.nutritionService.getNutritionInfo(for: name) { result in
            switch result {
            case .success(let nutritionInfo):
                let foodNutrition = FoodNutrition(
                    calories: Double(nutritionInfo.calories),
                    protein: nutritionInfo.protein,
                    carbs: nutritionInfo.carbs,
                    fats: nutritionInfo.fat
                )
                
                let additionalNutrition = self.createAdditionalNutrition(from: nutritionInfo.toNutritionInfo())
                let warnings = self.healthService.checkForWarnings(foodName: name)
                let isRecommended = self.isRecommendedFood(name)
                let recommendationReason = self.getRecommendationReason(name)
                
                let recognizedFood = RecognizedFood(
                    name: name,
                    confidence: confidence,
                    boundingBox: .init(x: 0, y: 0, width: 1, height: 1),
                    estimatedNutrition: foodNutrition,
                    additionalNutrition: additionalNutrition,
                    nutritionSource: nutritionInfo.source,
                    dietaryWarnings: warnings.isEmpty ? nil : warnings,
                    isRecommended: isRecommended,
                    recommendationReason: recommendationReason
                )
                completion(recognizedFood)
                
            case .failure(let error):
                print("Failed to get backup nutrition info for \(name): \(error.localizedDescription)")
                let defaultFood = self.createDefaultRecognizedFood(
                    name: name,
                    confidence: confidence
                )
                completion(defaultFood)
            }
        }
    }
    
    private func createDefaultRecognizedFood(name: String, confidence: Float) -> RecognizedFood {
        let defaultNutrition = FoodNutrition(
            calories: 100,
            protein: 5,
            carbs: 15,
            fats: 3
        )
        
        let additionalNutrition = AdditionalNutrition(
            fiber: nil,
            sugar: nil,
            sodium: nil,
            cholesterol: nil,
            potassium: nil,
            calcium: nil,
            iron: nil,
            vitaminA: nil,
            vitaminC: nil,
            servingSize: nil,
            servingUnit: nil
        )
        
        let warnings = self.healthService.checkForWarnings(foodName: name)
        let isRecommended = self.isRecommendedFood(name)
        let recommendationReason = self.getRecommendationReason(name)
        
        return RecognizedFood(
            name: name,
            confidence: confidence,
            boundingBox: .init(x: 0, y: 0, width: 1, height: 1),
            estimatedNutrition: defaultNutrition,
            additionalNutrition: additionalNutrition,
            nutritionSource: nil,
            dietaryWarnings: warnings.isEmpty ? nil : warnings,
            isRecommended: isRecommended,
            recommendationReason: recommendationReason
        )
    }
}

struct RecognizedFood: Identifiable {
    let id = UUID()
    let name: String
    let confidence: Float
    let boundingBox: CGRect
    let estimatedNutrition: FoodNutrition
    let additionalNutrition: AdditionalNutrition?
    let nutritionSource: NutritionSource?
    var dietaryWarnings: [DietaryWarning]?
    var isRecommended: Bool = false
    var recommendationReason: String?
    var userFeedback: FoodRecognitionFeedback? = nil
    
    init(
        name: String,
        confidence: Float,
        boundingBox: CGRect,
        estimatedNutrition: FoodNutrition,
        additionalNutrition: AdditionalNutrition? = nil,
        nutritionSource: NutritionSource? = nil,
        dietaryWarnings: [DietaryWarning]? = nil,
        isRecommended: Bool = false,
        recommendationReason: String? = nil,
        userFeedback: FoodRecognitionFeedback? = nil
    ) {
        self.name = name
        self.confidence = confidence
        self.boundingBox = boundingBox
        self.estimatedNutrition = estimatedNutrition
        self.additionalNutrition = additionalNutrition
        self.nutritionSource = nutritionSource
        self.dietaryWarnings = dietaryWarnings
        self.isRecommended = isRecommended
        self.recommendationReason = recommendationReason
        self.userFeedback = userFeedback
    }
    
    /// Returns the highest warning level if any warnings exist
    var highestWarningLevel: WarningLevel? {
        guard let warnings = dietaryWarnings, !warnings.isEmpty else {
            return nil
        }
        
        if warnings.contains(where: { $0.warningLevel == .severe }) {
            return .severe
        } else if warnings.contains(where: { $0.warningLevel == .moderate }) {
            return .moderate
        } else if warnings.contains(where: { $0.warningLevel == .mild }) {
            return .mild
        } else {
            return WarningLevel.none
        }
    }
}

struct FoodNutrition {
    let calories: Double
    let protein: Double
    let carbs: Double
    let fats: Double  // Changed from fat to fats to match Core Data model
}

struct AdditionalNutrition {
    let fiber: Double?
    let sugar: Double?
    let sodium: Double?
    let cholesterol: Double?
    let potassium: Double?
    let calcium: Double?
    let iron: Double?
    let vitaminA: Double?
    let vitaminC: Double?
    let servingSize: Double?
    let servingUnit: String?
    
    init(
        fiber: Double? = nil,
        sugar: Double? = nil,
        sodium: Double? = nil,
        cholesterol: Double? = nil,
        potassium: Double? = nil,
        calcium: Double? = nil,
        iron: Double? = nil,
        vitaminA: Double? = nil,
        vitaminC: Double? = nil,
        servingSize: Double? = nil,
        servingUnit: String? = nil
    ) {
        self.fiber = fiber
        self.sugar = sugar
        self.sodium = sodium
        self.cholesterol = cholesterol
        self.potassium = potassium
        self.calcium = calcium
        self.iron = iron
        self.vitaminA = vitaminA
        self.vitaminC = vitaminC
        self.servingSize = servingSize
        self.servingUnit = servingUnit
    }
}

struct FoodRecognitionView: View {
    @ObservedObject var classifier: FoodClassifier
    @State private var image: UIImage
    @State private var showingSaveSuccess = false
    @State private var showingEditSheet = false
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var feedbackManager = FeedbackManager.shared
    @Binding var rootIsPresented: Bool
    @Binding var tabSelection: Int
    
    init(image: UIImage, classifier: FoodClassifier, rootIsPresented: Binding<Bool>? = nil, tabSelection: Binding<Int>? = nil) {
        self.image = image
        self.classifier = classifier
        self._image = State(initialValue: image)
        self._rootIsPresented = rootIsPresented != nil ? rootIsPresented! : .constant(false)
        self._tabSelection = tabSelection != nil ? tabSelection! : .constant(0)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Image preview
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(15)
                        .padding(.horizontal)
                    
                    // Processing indicator
                    if classifier.isProcessing {
                        VStack(spacing: 15) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Analyzing your food...")
                                .font(.headline)
                            Text("This may take a moment")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    } else if classifier.recognizedObjects.isEmpty {
                        VStack(spacing: 15) {
                            Image(systemName: "exclamationmark.circle")
                                .font(.system(size: 50))
                                .foregroundColor(.orange)
                            Text("No food items detected")
                                .font(.headline)
                            Text("Try taking a clearer photo or from a different angle")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            
                            // Add a button to go back
                            Button {
                                dismissToHome()
                            } label: {
                                Text("Go Back")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                            .padding(.horizontal)
                            .padding(.top, 10)
                        }
                        .padding()
                    } else {
                        // Action buttons
                        HStack(spacing: 20) {
                            Button {
                                saveToHistory()
                            } label: {
                                VStack {
                                    Image(systemName: "square.and.arrow.down")
                                        .font(.system(size: 24))
                                    Text("Save")
                                        .font(.caption)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(10)
                            }
                            
                            Button {
                                showingEditSheet = true
                            } label: {
                                VStack {
                                    Image(systemName: "pencil")
                                        .font(.system(size: 24))
                                    Text("Edit")
                                        .font(.caption)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange.opacity(0.1))
                                .foregroundColor(.orange)
                                .cornerRadius(10)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Food items
                        VStack(spacing: 15) {
                            ForEach(classifier.recognizedObjects) { food in
                                FoodItemCard(food: food)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Health recommendations
                        if !classifier.healthRecommendations.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Recommendations")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 15) {
                                        ForEach(classifier.healthRecommendations) { recommendation in
                                            VStack(alignment: .leading, spacing: 8) {
                                                HStack {
                                                    Image(systemName: "leaf.fill")
                                                        .foregroundColor(.green)
                                                    Text(recommendation.foodName)
                                                        .font(.headline)
                                                }
                                                
                                                Text(recommendation.reason)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                    .lineLimit(2)
                                            }
                                            .padding()
                                            .frame(width: 200)
                                            .background(Color(.systemGray6))
                                            .cornerRadius(10)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Food Recognition")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismissToHome()
                    }
                }
            }
            .alert("Saved to History", isPresented: $showingSaveSuccess) {
                Button("OK", role: .cancel) {
                    dismissToHome()
                }
            } message: {
                Text("The food items have been saved to your history.")
            }
            .onAppear {
                print("FoodRecognitionView appeared with image size: \(image.size.width)x\(image.size.height)")
                // Start the analysis process
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    classifier.analyzeImage(image)
                }
            }
        }
        .environmentObject(feedbackManager)
        .interactiveDismissDisabled() // Prevent swipe to dismiss
    }
    
    private func dismissToHome() {
        print("Dismissing to home")
        // First dismiss this view
        rootIsPresented = false
        // Then set the tab selection to home
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            tabSelection = 0
        }
    }
    
    private func saveToHistory() {
        let meal = Meal(context: viewContext)
        meal.id = UUID()
        meal.date = Date()
        meal.name = "Meal \(Date().formatted(date: .abbreviated, time: .shortened))"
        
        // Save each recognized food item
        for recognizedFood in classifier.recognizedObjects {
            let food = FoodItem(context: viewContext)
            food.id = UUID()
            food.name = recognizedFood.name
            food.calories = recognizedFood.estimatedNutrition.calories
            food.protein = recognizedFood.estimatedNutrition.protein
            food.carbs = recognizedFood.estimatedNutrition.carbs
            food.fats = recognizedFood.estimatedNutrition.fats
            
            // Save the cropped image for this food item
            if let croppedImage = image.cropped(to: recognizedFood.boundingBox) {
                food.image = croppedImage.jpegData(compressionQuality: 0.8)
            } else {
                // If cropping fails, save the full image
                food.image = image.jpegData(compressionQuality: 0.8)
            }
            
            meal.addToFoodItems(food)
        }
        
        do {
            try viewContext.save()
            showingSaveSuccess = true
        } catch {
            print("Error saving meal: \(error)")
        }
    }
}

struct BoundingBoxView: View {
    let recognizedObjects: [RecognizedFood]
    let imageSize: CGSize
    
    var body: some View {
        GeometryReader { geometry in
            ForEach(recognizedObjects) { food in
                let rect = boundingBoxRect(for: food.boundingBox, in: geometry.size)
                Rectangle()
                    .stroke(Color.green, lineWidth: 2)
                    .frame(width: rect.width, height: rect.height)
                    .position(x: rect.midX, y: rect.midY)
                
                Text(food.name)
                    .font(.caption)
                    .padding(4)
                    .background(Color.green.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(4)
                    .position(x: rect.midX, y: rect.minY - 10)
            }
        }
    }
    
    private func boundingBoxRect(for normalizedRect: CGRect, in size: CGSize) -> CGRect {
        let x = normalizedRect.origin.x * size.width
        let y = (1 - normalizedRect.origin.y - normalizedRect.height) * size.height
        let width = normalizedRect.width * size.width
        let height = normalizedRect.height * size.height
        return CGRect(x: x, y: y, width: width, height: height)
    }
}

struct FoodItemCard: View {
    let food: RecognizedFood
    @State private var showDetailedInfo = false
    @State private var showingFeedbackSheet = false
    @State private var localFood: RecognizedFood
    @EnvironmentObject var feedbackManager: FeedbackManager
    
    init(food: RecognizedFood) {
        self.food = food
        self._localFood = State(initialValue: food)
    }
    
    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Text(food.name)
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Text("\(Int(food.confidence * 100))% confident")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button(action: {
                    showingFeedbackSheet = true
                }) {
                    Image(systemName: "exclamationmark.bubble")
                        .foregroundColor(.blue)
                }
            }
            
            // Feedback badge if user has provided feedback
            if let feedback = localFood.userFeedback {
                HStack {
                    Image(systemName: feedback == .correct ? "checkmark.circle.fill" : 
                                      feedback == .incorrect ? "xmark.circle.fill" : "questionmark.circle.fill")
                        .foregroundColor(feedback == .correct ? .green : 
                                         feedback == .incorrect ? .red : .orange)
                    Text("You marked this as: \(feedback.rawValue)")
                        .font(.caption)
                        .foregroundColor(feedback == .correct ? .green : 
                                         feedback == .incorrect ? .red : .orange)
                    Spacer()
                }
                .padding(.vertical, 5)
            }
            
            // Health Warning Badge (if applicable)
            if let warningLevel = food.highestWarningLevel {
                HStack {
                    Image(systemName: warningLevel.icon)
                        .foregroundColor(warningLevel.color)
                    Text("\(warningLevel.rawValue) Warning")
                        .font(.caption)
                        .foregroundColor(warningLevel.color)
                    Spacer()
                }
                .padding(.vertical, 5)
            }
            
            // Recommendation Badge (if applicable)
            if food.isRecommended, let reason = food.recommendationReason {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Recommended: \(reason)")
                        .font(.caption)
                        .foregroundColor(.green)
                    Spacer()
                }
                .padding(.vertical, 5)
            }
            
            VStack(spacing: 15) {
                NutritionRow(title: "Calories", value: Int(food.estimatedNutrition.calories), unit: "kcal")
                
                Divider()
                
                HStack(spacing: 30) {
                    NutritionRow(title: "Protein", value: Int(food.estimatedNutrition.protein), unit: "g")
                    NutritionRow(title: "Carbs", value: Int(food.estimatedNutrition.carbs), unit: "g")
                    NutritionRow(title: "Fat", value: Int(food.estimatedNutrition.fats), unit: "g")  // Changed from Fats to Fat
                }
                
                // Show more details button
                Button(action: {
                    withAnimation {
                        showDetailedInfo.toggle()
                    }
                }) {
                    HStack {
                        Text(showDetailedInfo ? "Show Less" : "Show More")
                            .font(.caption)
                            .foregroundColor(.green)
                        
                        Image(systemName: showDetailedInfo ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    .padding(.top, 5)
                }
                
                // Detailed nutrition information
                if showDetailedInfo {
                    VStack(spacing: 15) {
                        Divider()
                        
                        // Additional nutrition rows
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                            if let fiber = food.additionalNutrition?.fiber {
                                NutritionRow(title: "Fiber", value: Int(fiber), unit: "g")
                            }
                            
                            if let sugar = food.additionalNutrition?.sugar {
                                NutritionRow(title: "Sugar", value: Int(sugar), unit: "g")
                            }
                            
                            if let sodium = food.additionalNutrition?.sodium {
                                NutritionRow(title: "Sodium", value: Int(sodium), unit: "mg")
                            }
                            
                            if let cholesterol = food.additionalNutrition?.cholesterol {
                                NutritionRow(title: "Cholesterol", value: Int(cholesterol), unit: "mg")
                            }
                        }
                        
                        // Detailed Health Warnings (if applicable)
                        if let warnings = food.dietaryWarnings, !warnings.isEmpty {
                            Divider()
                            
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Health Warnings")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                ForEach(warnings) { warning in
                                    WarningView(warning: warning)
                                }
                            }
                            .padding(.vertical, 5)
                        }
                        
                        // Source information
                        HStack {
                            Text("Source:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(food.nutritionSource?.rawValue ?? "Unknown")
                                .font(.caption)
                                .foregroundColor(.green)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(4)
                            
                            Spacer()
                            
                            if let servingSize = food.additionalNutrition?.servingSize,
                               let servingUnit = food.additionalNutrition?.servingUnit {
                                Text("Per \(Int(servingSize))\(servingUnit)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.top, 5)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(15)
        }
        .padding(.horizontal)
        .sheet(isPresented: $showingFeedbackSheet) {
            FeedbackView(food: food, localFood: $localFood)
        }
    }
}

struct WarningView: View {
    let warning: DietaryWarning
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Image(systemName: warning.warningLevel.icon)
                    .foregroundColor(warning.warningLevel.color)
                Text(warning.condition.rawValue)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(warning.warningLevel.color)
            }
            
            Text(warning.message)
                .font(.caption)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
            
            if let alternative = warning.suggestedAlternative {
                Text("Suggestion: \(alternative)")
                    .font(.caption)
                    .foregroundColor(.green)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)
            }
        }
        .padding(10)
        .background(warning.warningLevel.color.opacity(0.1))
        .cornerRadius(8)
    }
}

extension UIImage {
    func cropped(to normalizedRect: CGRect) -> UIImage? {
        let rect = CGRect(
            x: normalizedRect.origin.x * size.width,
            y: (1 - normalizedRect.origin.y - normalizedRect.height) * size.height,
            width: normalizedRect.width * size.width,
            height: normalizedRect.height * size.height
        )
        
        guard let cgImage = cgImage?.cropping(to: rect) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

struct ImagePreviewView: View {
    let image: UIImage
    @Binding var isPresented: Bool
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingRecognition = false
    @Binding var tabSelection: Int
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding()
                
                HStack(spacing: 40) {
                    Button {
                        print("Retake button tapped")
                        // Explicitly set isPresented to false to dismiss the view
                        DispatchQueue.main.async {
                        isPresented = false
                        }
                    } label: {
                        VStack {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 30))
                            Text("Retake")
                                .font(.caption)
                        }
                        .foregroundColor(.red)
                    }
                    .buttonStyle(PlainButtonStyle()) // Ensure button style doesn't interfere
                    
                    Button {
                        print("Use Photo button tapped")
                        // Set showingRecognition to true to show the recognition view
                        DispatchQueue.main.async {
                        showingRecognition = true
                        }
                    } label: {
                        VStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 30))
                            Text("Use Photo")
                                .font(.caption)
                        }
                        .foregroundColor(.green)
                    }
                    .buttonStyle(PlainButtonStyle()) // Ensure button style doesn't interfere
                }
                .padding(.bottom, 30)
            }
        }
        .overlay(alignment: .top) {
            HStack {
                Button {
                    print("Cancel button tapped")
                    // Explicitly set isPresented to false to dismiss the view
                    DispatchQueue.main.async {
                    isPresented = false
                }
                } label: {
                    Text("Cancel")
                    .foregroundColor(.primary)
                    .padding()
                }
                .buttonStyle(PlainButtonStyle()) // Ensure button style doesn't interfere
                
                Spacer()
                
                Text("Preview")
                    .font(.headline)
                
                Spacer()
                
                Button("") { }
                    .padding()
                    .opacity(0)
            }
            .background(.ultraThinMaterial)
        }
        .fullScreenCover(isPresented: $showingRecognition) {
            FoodRecognitionView(
                image: image,
                classifier: FoodClassifier(),
                rootIsPresented: $showingRecognition,
                tabSelection: $tabSelection
            )
        }
    }
}

struct ResultsView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Results View")
                    .font(.title)
            }
            .navigationTitle("Scan Results")
        }
    }
}

struct MealDetailView: View {
    let meal: Meal
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteAlert = false
    @State private var editMode = EditMode.inactive
    
    var body: some View {
        List {
            let foodItems = Array(meal.foodItems as? Set<FoodItem> ?? [])
            ForEach(foodItems, id: \.id) { item in
                VStack(alignment: .leading, spacing: 10) {
                    if let imageData = item.image, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 200)
                            .cornerRadius(10)
                    }
                    
                    Text(item.name ?? "Unknown Food")
                        .font(.headline)
                    HStack {
                        Text("Calories: \(Int(item.calories))")
                        Spacer()
                        Text("P: \(Int(item.protein))g")
                        Text("C: \(Int(item.carbs))g")
                        Text("F: \(Int(item.fats))g")  // Changed from Fats to Fat
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding(.vertical, 5)
            }
            .onDelete(perform: deleteFoodItems)
        }
        .navigationTitle(meal.name ?? "Meal Details")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
        .environment(\.editMode, $editMode)
        .alert("Delete Meal", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteMeal()
            }
        } message: {
            Text("Are you sure you want to delete this meal and all its items?")
        }
    }
    
    private func deleteFoodItems(at offsets: IndexSet) {
        let foodItems = Array(meal.foodItems as? Set<FoodItem> ?? [])
        for index in offsets {
            let item = foodItems[index]
            viewContext.delete(item)
        }
        
        do {
            try viewContext.save()
        } catch {
            print("Error deleting food items: \(error)")
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

struct FeaturedCard: View {
    let title: String
    let subtitle: String
    let imageName: String
    
    var body: some View {
        VStack(alignment: .leading) {
            ZStack(alignment: .bottomLeading) {
                if let image = UIImage(named: imageName) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 250, height: 150)
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                } else {
                    // Fallback to placeholder
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 250, height: 150)
                    
                    Image(systemName: "photo")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                }
                
                // Gradient overlay
                LinearGradient(
                    gradient: Gradient(colors: [.black.opacity(0.7), .clear]),
                    startPoint: .bottom,
                    endPoint: .top
                )
                .frame(width: 250, height: 150)
                .clipShape(RoundedRectangle(cornerRadius: 15))
                
                // Text overlay
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding()
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

// Add this new preview provider for testing individual views
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(tabSelection: .constant(0), showingCamera: .constant(false))
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}

// Rename to avoid conflict with the CameraView struct in CameraView.swift
struct CameraViewPreview: PreviewProvider {
    static var previews: some View {
        CameraView(tabSelection: .constant(1))
    }
}

struct ResultsView_Previews: PreviewProvider {
    static var previews: some View {
        ResultsView()
    }
}

struct AnalyticsView_Previews: PreviewProvider {
    static var previews: some View {
        AnalyticsView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}

struct FeedbackView: View {
    let food: RecognizedFood
    @Binding var localFood: RecognizedFood
    @State private var feedbackType: FoodRecognitionFeedback = .correct
    @State private var correctFoodName: String = ""
    @State private var showingThankYou = false
    @Environment(\.dismiss) private var dismiss
    @StateObject private var feedbackManager = FeedbackManager.shared
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Is this food correctly identified?")) {
                    Text("Current identification: \(food.name)")
                        .font(.headline)
                    
                    Picker("Your feedback", selection: $feedbackType) {
                        Text("Correct").tag(FoodRecognitionFeedback.correct)
                        Text("Partially Correct").tag(FoodRecognitionFeedback.partiallyCorrect)
                        Text("Incorrect").tag(FoodRecognitionFeedback.incorrect)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                if feedbackType != .correct {
                    Section(header: Text("What is the correct food?")) {
                        TextField("Enter correct food name", text: $correctFoodName)
                    }
                }
                
                Section {
                    Button("Submit Feedback") {
                        // Save feedback
                        feedbackManager.addFeedback(
                            for: food,
                            feedback: feedbackType,
                            correctName: feedbackType != .correct ? correctFoodName : nil
                        )
                        
                        // Update local food with feedback
                        localFood.userFeedback = feedbackType
                        
                        showingThankYou = true
                        
                        // Dismiss after a short delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            dismiss()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                }
            }
            .navigationTitle("Food Recognition Feedback")
            .overlay(
                Group {
                    if showingThankYou {
                        VStack {
                            Text("Thank You!")
                                .font(.title)
                                .fontWeight(.bold)
                            Text("Your feedback helps improve our food recognition")
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(15)
                        .shadow(radius: 10)
                    }
                }
            )
        }
    }
}

// Add custom VNClassificationObservation extension
extension VNClassificationObservation {
    convenience init(identifier: String, confidence: Float) {
        self.init()
        self.setValue(identifier, forKey: "identifier")
        self.setValue(confidence, forKey: "confidence")
    }
}

