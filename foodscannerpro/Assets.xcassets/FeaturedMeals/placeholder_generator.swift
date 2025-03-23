import UIKit

// Function to create a placeholder image
func createPlaceholderImage(name: String, size: CGSize = CGSize(width: 400, height: 300)) -> UIImage {
    // Create a new image context
    UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
    defer { UIGraphicsEndImageContext() }
    
    // Background color
    let backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0)
    backgroundColor.setFill()
    UIRectFill(CGRect(origin: .zero, size: size))
    
    // Draw text
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.alignment = .center
    
    let attributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 24, weight: .medium),
        .foregroundColor: UIColor.darkGray,
        .paragraphStyle: paragraphStyle
    ]
    
    let displayName = name.replacingOccurrences(of: "_", with: " ")
                        .split(separator: " ")
                        .map { $0.prefix(1).uppercased() + $0.dropFirst() }
                        .joined(separator: " ")
    
    let textRect = CGRect(x: 0, y: size.height / 2 - 20, width: size.width, height: 40)
    displayName.draw(in: textRect, withAttributes: attributes)
    
    // Draw food icon
    let foodEmoji = "🍽️"
    let iconAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 60),
        .paragraphStyle: paragraphStyle
    ]
    let iconRect = CGRect(x: 0, y: size.height / 2 - 100, width: size.width, height: 60)
    foodEmoji.draw(in: iconRect, withAttributes: iconAttributes)
    
    // Create the image from the context
    guard let image = UIGraphicsGetImageFromCurrentImageContext() else {
        return UIImage()
    }
    
    return image
}

// Usage in a playground:
// let image = createPlaceholderImage(name: "greek_salad")
// if let data = image.pngData() {
//     try? data.write(to: URL(fileURLWithPath: "/path/to/save/greek_salad.png"))
// }

// List of all meal images
let mealNames = [
    "avocado_toast",
    "oatmeal_bowl",
    "smoothie_bowl",
    "protein_pancakes",
    "veggie_frittata",
    "chia_pudding",
    "breakfast_burrito",
    "quinoa_breakfast",
    "cottage_cheese_toast",
    "grilled_fish",
    "hummus_plate",
    "ratatouille",
    "mediterranean_pasta",
    "falafel_wrap",
    "seafood_paella",
    "tabbouleh",
    "stuffed_peppers",
    "shakshuka",
    "salmon_bowl",
    "turkey_meatballs",
    "lentil_curry",
    "tuna_steak",
    "protein_bowl",
    "tofu_stirfry",
    "yogurt_bowl",
    "egg_white_omelette",
    "shrimp_skewers"
]

// Generate placeholders for each meal
// for name in mealNames {
//     let image = createPlaceholderImage(name: name)
//     if let data = image.pngData() {
//         try? data.write(to: URL(fileURLWithPath: "/path/to/save/\(name).png"))
//     }
// } 