# Asset Structure for Personalized Content

## Directory Structure in Assets.xcassets

```
Assets.xcassets/
├── RecommendationImages/
│   ├── General/
│   │   ├── yogurt_berries.imageset
│   │   ├── overnight_oats.imageset
│   │   └── ...
│   ├── LowCarb/
│   │   ├── cauliflower_rice.imageset
│   │   ├── zucchini_noodles.imageset
│   │   └── ...
│   ├── HighProtein/
│   │   ├── grilled_chicken.imageset
│   │   ├── salmon_fillet.imageset
│   │   └── ...
│   ├── Diabetes/
│   │   ├── low_gi_meals.imageset
│   │   ├── sugar_free_desserts.imageset
│   │   └── ...
│   ├── HeartHealth/
│   │   ├── mediterranean_bowl.imageset
│   │   ├── omega3_rich.imageset
│   │   └── ...
│   └── GlutenFree/
│       ├── quinoa_bowl.imageset
│       ├── rice_alternatives.imageset
│       └── ...
├── Categories/
│   ├── breakfast.imageset
│   ├── lunch.imageset
│   ├── dinner.imageset
│   ├── snacks.imageset
│   └── healthy_alternatives.imageset
└── UserContent/
    └── ProfileImages/
        └── default_avatar.imageset

## Image Requirements

1. Food Images:
   - Resolution: 1024x1024 pixels (will be scaled down as needed)
   - Format: JPEG or PNG
   - Quality: High quality, appetizing food photography
   - Style: Consistent lighting and styling
   - Background: Light, neutral backgrounds
   - Naming: lowercase_with_underscores.jpg

2. Category Icons:
   - Resolution: 512x512 pixels
   - Format: PNG with transparency
   - Style: Consistent icon design
   - Colors: Using app's color scheme

3. Profile Images:
   - Resolution: 256x256 pixels
   - Format: JPEG or PNG
   - Aspect Ratio: 1:1 (square)

## Localization

Create language-specific asset catalogs for text content:
```
Resources/
├── en.lproj/
│   └── Localizable.strings
├── es.lproj/
│   └── Localizable.strings
└── fr.lproj/
    └── Localizable.strings
```

## Content Categories

1. General Recommendations:
   - Basic healthy eating guidelines
   - Universal nutritional advice
   - Common healthy foods

2. Dietary Goal Specific:
   - Weight Loss
   - Muscle Gain
   - Maintenance
   - Low Carb
   - High Protein

3. Health Condition Specific:
   - Diabetes Management
   - Heart Health
   - Gluten Free
   - Lactose Intolerance
   - Low Sodium

4. Cultural and Dietary Preferences:
   - Vegetarian
   - Vegan
   - Mediterranean
   - Asian Cuisine
   - Middle Eastern

## Content Management

1. Image Loading:
```swift
if let image = UIImage(named: "\(dietaryGoal.rawValue)/\(recommendation.image)") {
    // Use specific image for dietary goal
} else if let image = UIImage(named: "General/\(recommendation.image)") {
    // Fallback to general image
} else {
    // Use placeholder image
}
```

2. Text Localization:
```swift
let localizedReason = NSLocalizedString(
    "recommendation.reason.\(recommendation.id)",
    comment: "Reason for food recommendation"
)
```

3. Dynamic Content:
```swift
func getRecommendationContent(for profile: HealthProfile) -> [FoodRecommendation] {
    var recommendations: [FoodRecommendation] = []
    
    // Add goal-specific recommendations
    recommendations += getRecommendations(for: profile.dietaryGoal)
    
    // Add health condition specific recommendations
    for condition in profile.healthConditions {
        recommendations += getRecommendations(for: condition)
    }
    
    // Filter based on restrictions
    recommendations = recommendations.filter { recommendation in
        !profile.dietaryRestrictions.contains { restriction in
            recommendation.hasRestriction(restriction)
        }
    }
    
    return recommendations
}
``` 