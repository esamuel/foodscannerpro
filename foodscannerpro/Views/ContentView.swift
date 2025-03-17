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

struct NutritionRow: View {
    let title: String
    let value: Int
    let unit: String
    
    var body: some View {
        VStack(spacing: 5) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            HStack(alignment: .bottom, spacing: 2) {
                Text("\(value)")
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.semibold)
                Text(unit)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

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
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = false
        print("Legacy image picker created")
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: LegacyImagePicker
        
        init(_ parent: LegacyImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            print("Image selected in legacy picker")
            if let image = info[.originalImage] as? UIImage {
                print("Image successfully extracted from info dictionary")
                DispatchQueue.main.async {
                    self.parent.image = image
                    print("Image assigned to binding: \(image.size.width)x\(image.size.height)")
                    self.parent.dismiss()
                    
                    // Delay showing recognition to ensure picker is dismissed
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self.parent.showRecognition = true
                    }
                }
            } else {
                print("Failed to extract image from info dictionary")
                parent.dismiss()
            }
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            print("Image picker cancelled")
            parent.dismiss()
        }
    }
}

struct HomeView: View {
    @State private var searchText = ""
    @State private var showingImagePicker = false
    @State private var showingLegacyPicker = false
    @State private var searchResults: [String] = []
    @State private var isSearching = false
    @State private var selectedImage: UIImage?
    @State private var showingPreview = false
    @State private var showingRecognition = false
    @Binding var tabSelection: Int
    @Binding var showingCamera: Bool
    
    // Sample food database for search
    private let foodDatabase = [
        "Apple", "Banana", "Chicken Breast", "Greek Yogurt",
        "Salmon", "Quinoa", "Avocado", "Sweet Potato",
        "Broccoli", "Eggs", "Oatmeal", "Almonds"
    ]
    
    var filteredResults: [String] {
        if searchText.isEmpty {
            return []
        }
        return foodDatabase.filter { $0.lowercased().contains(searchText.lowercased()) }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Search Bar with Results
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
                        
                        // Search Results
                        if isSearching {
                            ScrollView {
                                LazyVStack(alignment: .leading) {
                                    ForEach(filteredResults, id: \.self) { food in
                                        Button(action: {
                                            searchText = food
                                            isSearching = false
                                        }) {
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
                    
                    // Scan Options Card
                    VStack(spacing: 15) {
                        Text("Scan Food")
                            .font(.title2)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                        
                        HStack(spacing: 20) {
                            // Camera option
                            Button {
                                showingCamera = true
                            } label: {
                                VStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.green.opacity(0.2))
                                            .frame(width: 80, height: 80)
                                        
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 30))
                                            .foregroundColor(.green)
                                    }
                                    
                                    Text("Take Photo")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(15)
                            }
                            
                            // Gallery option
                            Button {
                                print("From Gallery button tapped")
                                selectedImage = nil // Reset the image
                                showingLegacyPicker = true
                            } label: {
                                VStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.blue.opacity(0.2))
                                            .frame(width: 80, height: 80)
                                        
                                        Image(systemName: "photo.on.rectangle")
                                            .font(.system(size: 30))
                                            .foregroundColor(.blue)
                                    }
                                    
                                    Text("From Gallery")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(15)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                    
                    // Main Features Grid
                    VStack(spacing: 15) {
                        Text("Quick Access")
                            .font(.title2)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                        
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 20) {
                            FeatureButton(icon: "chart.bar.fill", title: "Analytics", color: .blue)
                            .onTapGesture {
                                    tabSelection = 3
                            }
                            FeatureButton(icon: "clock.fill", title: "History", color: .purple)
                            .onTapGesture {
                                    tabSelection = 4
                                }
                            FeatureButton(icon: "heart.fill", title: "Recommendations", color: .red)
                                .onTapGesture {
                                    tabSelection = 1
                                }
                            FeatureButton(icon: "person.fill", title: "Profile", color: .orange)
                                .onTapGesture {
                                    tabSelection = 5
                                }
                        FeatureButton(icon: "star.fill", title: "Premium", color: .yellow)
                            FeatureButton(icon: "fork.knife", title: "Meal Plans", color: .green)
                    }
                        .padding(.horizontal)
                    }
                    
                    // Featured Section
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Featured Meals")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            Button(action: {
                                // Handle More action
                            }) {
                                HStack {
                                    Text("More")
                                    Image(systemName: "chevron.right")
                                }
                                .foregroundColor(.green)
                            }
                        }
                        .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 20) {
                                FeaturedCard(
                                    title: "Healthy Breakfast",
                                    subtitle: "Start Your Day Right",
                                    imageName: "breakfast"
                                )
                                
                                FeaturedCard(
                                    title: "Mediterranean Diet",
                                    subtitle: "Heart-Healthy Choices",
                                    imageName: "mediterranean"
                                )
                                
                                FeaturedCard(
                                    title: "Protein-Rich Meals",
                                    subtitle: "Build & Recover",
                                    imageName: "protein"
                                )
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    Spacer(minLength: 50)
                }
            }
            .navigationTitle("Food Scanner Pro")
            .sheet(isPresented: $showingImagePicker) {
                GalleryImagePicker(image: $selectedImage)
            }
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
                FoodRecognitionView(image: image, classifier: FoodClassifier(), rootIsPresented: $showingRecognition, tabSelection: $tabSelection)
            }
        }
        .onChange(of: selectedImage) { oldValue, newValue in
            print("selectedImage changed: \(newValue != nil ? "Image selected" : "No image")")
            if newValue != nil && showingImagePicker {
                print("Image selected from PHPicker, closing picker and showing preview")
                showingImagePicker = false
                
                // Delay showing the preview to ensure pickers are dismissed first
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showingPreview = true
                }
            }
        }
        .onChange(of: showingRecognition) { oldValue, newValue in
            print("showingRecognition changed to: \(newValue)")
            // If recognition view is dismissed, reset the selected image
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

class FoodClassifier: ObservableObject {
    @Published var recognizedObjects: [RecognizedFood] = []
    @Published var isProcessing = false
    @Published var healthRecommendations: [FoodRecommendation] = []
    
    // Expanded food keywords for better recognition
    private let foodKeywords = [
        // Basic food categories
        "food", "fruit", "vegetable", "meat", "dish", "bread", "cake", "soup", "salad", "sandwich",
        
        // Fruits
        "apple", "banana", "orange", "grape", "strawberry", "blueberry", "raspberry", "pineapple",
        "mango", "peach", "pear", "plum", "watermelon", "kiwi", "cherry", "lemon", "lime", "coconut",
        "avocado", "fig", "date", "grapefruit", "pomegranate", "apricot", "blackberry", "cantaloupe",
        
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
    private let minimumConfidence: Float = 0.3
    private let highConfidenceThreshold: Float = 0.7
    
    // Reference to the nutrition service
    private let nutritionService = NutritionService.shared
    
    // Reference to the health service
    private let healthService = HealthService.shared
    
    // Queue for handling nutrition lookups
    private let nutritionQueue = DispatchQueue(label: "com.foodscannerpro.nutritionqueue", attributes: .concurrent)
    private let nutritionGroup = DispatchGroup()
    
    // Feedback manager for improving recognition
    private let feedbackManager = FeedbackManager()
    
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
            
            // Create a request handler
            let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            // Create an image classification request with more accurate settings
            let classificationRequest = VNClassifyImageRequest { [weak self] request, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Classification error: \(error)")
                    DispatchQueue.main.async {
                        self.isProcessing = false
                    }
                    return
                }
                
                // Process classification results
                guard let observations = request.results as? [VNClassificationObservation] else {
                    DispatchQueue.main.async {
                        self.isProcessing = false
                    }
                    return
                }
                
                // Print all observations for debugging
                print("All observations:")
                for (index, observation) in observations.prefix(20).enumerated() {
                    print("\(index): \(observation.identifier) - \(observation.confidence)")
                }
                
                // Filter for food-related items with confidence > minimumConfidence
                var foodObservations = observations.filter { observation in
                    // Check if the identifier contains any food keyword
                    let containsFoodKeyword = self.foodKeywords.contains { keyword in
                        observation.identifier.lowercased().contains(keyword.lowercased())
                    }
                    
                    // Apply confidence threshold
                    return containsFoodKeyword && observation.confidence > self.minimumConfidence
                }
                
                // Apply feedback-based corrections
                self.applyFeedbackCorrections(to: &foodObservations)
                
                // Sort by confidence
                foodObservations.sort { $0.confidence > $1.confidence }
                
                // Limit to top 5 results
                let topObservations = Array(foodObservations.prefix(5))
                
                // If no food items detected, try with a lower threshold
                if topObservations.isEmpty {
                    let lowConfidenceObservations = observations.filter { observation in
                        let containsFoodKeyword = self.foodKeywords.contains { keyword in
                            observation.identifier.lowercased().contains(keyword.lowercased())
                        }
                        return containsFoodKeyword && observation.confidence > 0.2
                    }.sorted { $0.confidence > $1.confidence }.prefix(3)
                    
                    if lowConfidenceObservations.isEmpty {
                        DispatchQueue.main.async {
                            self.isProcessing = false
                        }
                        return
                    }
                    
                    self.processObservations(Array(lowConfidenceObservations))
                } else {
                    self.processObservations(topObservations)
                }
            }
            
            // Set revision to 2 for better accuracy
            classificationRequest.revision = VNClassifyImageRequestRevision2
            
            // Try to perform the request
            do {
                try requestHandler.perform([classificationRequest])
            } catch {
                print("Failed to perform classification: \(error)")
                DispatchQueue.main.async {
                    self.isProcessing = false
                }
            }
        }
    }
    
    private func processObservations(_ observations: [VNClassificationObservation]) {
        // Create a temporary array to hold recognized objects
        var tempRecognizedObjects: [RecognizedFood] = []
        
        // Process each observation
        for observation in observations {
            // Clean up the identifier to get a more readable name
            let name = cleanUpFoodName(observation.identifier)
            
            // Enter the dispatch group
            self.nutritionGroup.enter()
            
            // Get nutrition info on a background queue
            self.nutritionQueue.async {
                self.nutritionService.getNutritionInfo(for: name) { result in
                    switch result {
                    case .success(let nutritionInfo):
                        // Convert NutritionInfo to FoodNutrition
                        let foodNutrition = FoodNutrition(
                            calories: Double(nutritionInfo.calories),
                            protein: nutritionInfo.protein,
                            carbs: nutritionInfo.carbs,
                            fats: nutritionInfo.fat
                        )
                        
                        // Create additional nutrition info
                        let additionalNutrition = AdditionalNutrition(
                            fiber: nutritionInfo.fiber,
                            sugar: nutritionInfo.sugar,
                            sodium: nutritionInfo.sodium,
                            cholesterol: nutritionInfo.cholesterol,
                            potassium: nutritionInfo.potassium,
                            calcium: nutritionInfo.calcium,
                            iron: nutritionInfo.iron,
                            vitaminA: nutritionInfo.vitaminA,
                            vitaminC: nutritionInfo.vitaminC,
                            servingSize: nutritionInfo.servingSize,
                            servingUnit: nutritionInfo.servingUnit
                        )
                        
                        // Check for dietary warnings
                        let warnings = self.healthService.checkForWarnings(foodName: nutritionInfo.foodName)
                        
                        // Check if this food is recommended
                        let isRecommended = self.isRecommendedFood(nutritionInfo.foodName)
                        let recommendationReason = self.getRecommendationReason(nutritionInfo.foodName)
                        
                        // Create RecognizedFood object
                        let recognizedFood = RecognizedFood(
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
                        
                        // Add to temporary array
                        tempRecognizedObjects.append(recognizedFood)
                        
                    case .failure(let error):
                        print("Failed to get nutrition info for \(name): \(error.localizedDescription)")
                        
                        // Create a default RecognizedFood object
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
                        
                        // Check for dietary warnings
                        let warnings = self.healthService.checkForWarnings(foodName: name)
                        
                        // Check if this food is recommended
                        let isRecommended = self.isRecommendedFood(name)
                        let recommendationReason = self.getRecommendationReason(name)
                        
                        let recognizedFood = RecognizedFood(
                            name: name,
                            confidence: observation.confidence,
                            boundingBox: .init(x: 0, y: 0, width: 1, height: 1),
                            estimatedNutrition: defaultNutrition,
                            additionalNutrition: additionalNutrition,
                            nutritionSource: nil,
                            dietaryWarnings: warnings.isEmpty ? nil : warnings,
                            isRecommended: isRecommended,
                            recommendationReason: recommendationReason
                        )
                        
                        // Add to temporary array
                        tempRecognizedObjects.append(recognizedFood)
                    }
                    
                    // Leave the dispatch group
                    self.nutritionGroup.leave()
                }
            }
        }
        
        // Wait for all nutrition lookups to complete
        nutritionGroup.notify(queue: .main) {
            // If no results, try a backup approach
            if tempRecognizedObjects.isEmpty {
                self.tryBackupRecognition(observations)
            } else {
                // Sort by confidence
                self.recognizedObjects = tempRecognizedObjects.sorted(by: { $0.confidence > $1.confidence })
                self.isProcessing = false
            }
        }
    }
    
    private func tryBackupRecognition(_ observations: [VNClassificationObservation]) {
        // Create a backup array
        var backupObjects: [RecognizedFood] = []
        let backupGroup = DispatchGroup()
        
        // Try with a broader set of keywords
        for observation in observations.prefix(10) {
            // Extract potential food names from the identifier
            let components = observation.identifier.components(separatedBy: ",")
            for component in components {
                let name = component.trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Skip very short names
                if name.count < 3 {
                    continue
                }
                
                // Enter the dispatch group
                backupGroup.enter()
                
                // Try to get nutrition info
                self.nutritionQueue.async {
                    self.nutritionService.getNutritionInfo(for: name) { result in
                        switch result {
                        case .success(let nutritionInfo):
                            // Convert NutritionInfo to FoodNutrition
                            let foodNutrition = FoodNutrition(
                                calories: Double(nutritionInfo.calories),
                                protein: nutritionInfo.protein,
                                carbs: nutritionInfo.carbs,
                                fats: nutritionInfo.fat
                            )
                            
                            // Create additional nutrition info
                            let additionalNutrition = AdditionalNutrition(
                                fiber: nutritionInfo.fiber,
                                sugar: nutritionInfo.sugar,
                                sodium: nutritionInfo.sodium,
                                cholesterol: nutritionInfo.cholesterol,
                                potassium: nutritionInfo.potassium,
                                calcium: nutritionInfo.calcium,
                                iron: nutritionInfo.iron,
                                vitaminA: nutritionInfo.vitaminA,
                                vitaminC: nutritionInfo.vitaminC,
                                servingSize: nutritionInfo.servingSize,
                                servingUnit: nutritionInfo.servingUnit
                            )
                            
                            // Check for dietary warnings
                            let warnings = self.healthService.checkForWarnings(foodName: nutritionInfo.foodName)
                            
                            // Check if this food is recommended
                            let isRecommended = self.isRecommendedFood(nutritionInfo.foodName)
                            let recommendationReason = self.getRecommendationReason(nutritionInfo.foodName)
                            
                            // Create RecognizedFood object
                            let recognizedFood = RecognizedFood(
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
                            
                            // Add to backup array
                            backupObjects.append(recognizedFood)
                            
                        case .failure(let error):
                            print("Failed to get backup nutrition info for \(name): \(error.localizedDescription)")
                            
                            // Create a default RecognizedFood object
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
                            
                            // Check for dietary warnings
                            let warnings = self.healthService.checkForWarnings(foodName: name)
                            
                            // Check if this food is recommended
                            let isRecommended = self.isRecommendedFood(name)
                            let recommendationReason = self.getRecommendationReason(name)
                            
                            let recognizedFood = RecognizedFood(
                                name: name,
                                confidence: observation.confidence,
                                boundingBox: .init(x: 0, y: 0, width: 1, height: 1),
                                estimatedNutrition: defaultNutrition,
                                additionalNutrition: additionalNutrition,
                                nutritionSource: nil,
                                dietaryWarnings: warnings.isEmpty ? nil : warnings,
                                isRecommended: isRecommended,
                                recommendationReason: recommendationReason
                            )
                            
                            // Add to backup array
                            backupObjects.append(recognizedFood)
                        }
                        
                        // Leave the dispatch group
                        backupGroup.leave()
                    }
                }
            }
        }
        
        // Wait for all backup nutrition lookups to complete
        backupGroup.notify(queue: .main) {
            self.recognizedObjects = backupObjects
            self.isProcessing = false
        }
    }
    
    // Apply feedback-based corrections to improve recognition
    private func applyFeedbackCorrections(to observations: inout [VNClassificationObservation]) {
        let feedbackData = feedbackManager.feedbackData
        
        // Create a dictionary of corrections based on user feedback
        var corrections: [String: (String, Float)] = [:]
        
        for entry in feedbackData {
            if entry.feedback == .incorrect, let correctName = entry.correctFoodName {
                // Store the correction with the confidence level
                corrections[entry.foodName.lowercased()] = (correctName, entry.confidence)
            }
        }
        
        // Apply corrections to observations
        for i in 0..<observations.count {
            let cleanName = cleanUpFoodName(observations[i].identifier).lowercased()
            
            if let correction = corrections[cleanName] {
                let correctName = correction.0
                let confidence = correction.1
                // Create a new observation with the corrected name
                // VNClassificationObservation doesn't have a public initializer
                // So we'll just modify the original observation's properties
                print("Applying correction: \(cleanName) -> \(correctName) with confidence \(confidence)")
                // Since we can't create a new VNClassificationObservation, we'll just continue with the original
            }
        }
    }
    
    // Clean up food name for better readability
    private func cleanUpFoodName(_ name: String) -> String {
        // Remove any text in parentheses
        var cleanName = name.replacingOccurrences(of: "\\([^)]+\\)", with: "", options: .regularExpression)
        
        // Split by comma and take the first part
        if let firstPart = cleanName.components(separatedBy: ",").first {
            cleanName = firstPart.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Capitalize first letter of each word
        let words = cleanName.components(separatedBy: " ")
        let capitalizedWords = words.map { word in
            if word.count > 0 {
                let firstChar = word.prefix(1).uppercased()
                let restOfWord = word.dropFirst()
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

/// Represents user feedback on food recognition
enum FoodRecognitionFeedback: String, Codable {
    case correct = "Correct"
    case incorrect = "Incorrect"
    case partiallyCorrect = "Partially Correct"
}

struct FoodNutrition {
    let calories: Double
    let protein: Double
    let carbs: Double
    let fats: Double
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
    @StateObject private var feedbackManager = FeedbackManager()
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
                    NutritionRow(title: "Fats", value: Int(food.estimatedNutrition.fats), unit: "g")
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
            FoodRecognitionView(image: image, classifier: FoodClassifier(), rootIsPresented: .constant(false), tabSelection: .constant(0))
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
                        Text("F: \(Int(item.fats))g")
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

// Feedback Manager to collect and store user feedback
class FeedbackManager: ObservableObject {
    @Published var feedbackData: [FeedbackEntry] = []
    private let userDefaults = UserDefaults.standard
    private let feedbackKey = "foodRecognitionFeedback"
    
    struct FeedbackEntry: Codable, Identifiable {
        let id: UUID
        let foodName: String
        let correctFoodName: String?
        let feedback: FoodRecognitionFeedback
        let confidence: Float
        let timestamp: Date
        
        init(id: UUID = UUID(), foodName: String, correctFoodName: String? = nil, 
             feedback: FoodRecognitionFeedback, confidence: Float, timestamp: Date = Date()) {
            self.id = id
            self.foodName = foodName
            self.correctFoodName = correctFoodName
            self.feedback = feedback
            self.confidence = confidence
            self.timestamp = timestamp
        }
    }
    
    init() {
        loadFeedback()
    }
    
    func addFeedback(for food: RecognizedFood, feedback: FoodRecognitionFeedback, correctName: String? = nil) {
        let entry = FeedbackEntry(
            foodName: food.name,
            correctFoodName: correctName,
            feedback: feedback,
            confidence: food.confidence
        )
        
        feedbackData.append(entry)
        saveFeedback()
    }
    
    func loadFeedback() {
        if let data = userDefaults.data(forKey: feedbackKey),
           let decoded = try? JSONDecoder().decode([FeedbackEntry].self, from: data) {
            feedbackData = decoded
        }
    }
    
    func saveFeedback() {
        if let encoded = try? JSONEncoder().encode(feedbackData) {
            userDefaults.set(encoded, forKey: feedbackKey)
        }
    }
    
    func exportFeedback() -> Data? {
        return try? JSONEncoder().encode(feedbackData)
    }
}

struct FeedbackView: View {
    let food: RecognizedFood
    @Binding var localFood: RecognizedFood
    @State private var feedbackType: FoodRecognitionFeedback = .correct
    @State private var correctFoodName: String = ""
    @State private var showingThankYou = false
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var feedbackManager: FeedbackManager
    
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
