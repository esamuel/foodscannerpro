import SwiftUI
import Charts
import UIKit

enum TimeRange: String, CaseIterable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
    case year = "Year"
    
    var calendarComponent: Calendar.Component {
        switch self {
        case .day:
            return .hour
        case .week:
            return .day
        case .month:
            return .day
        case .year:
            return .month
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct StatisticView: View {
    let value: Double
    let label: String
    let color: Color
    
    var body: some View {
        VStack {
            Text("\(Int(value))%")
                .font(.title)
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// UIKit-based text field wrapper
struct UIKitTextField: UIViewRepresentable {
    @Binding var text: String
    let placeholder: String
    
    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator
        textField.placeholder = placeholder
        textField.borderStyle = .roundedRect
        textField.autocorrectionType = .no // Disable autocorrection
        textField.autocapitalizationType = .none // Disable auto-capitalization
        textField.backgroundColor = .systemBackground
        textField.returnKeyType = .done
        
        // Add target for text changes
        textField.addTarget(
            context.coordinator,
            action: #selector(Coordinator.textFieldDidChange),
            for: .editingChanged
        )
        
        return textField
    }
    
    func updateUIView(_ uiView: UITextField, context: Context) {
        // Only update if the text is different to avoid cursor jumping
        if uiView.text != text {
            uiView.text = text
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }
    
    class Coordinator: NSObject, UITextFieldDelegate {
        @Binding var text: String
        
        init(text: Binding<String>) {
            self._text = text
        }
        
        @objc func textFieldDidChange(_ textField: UITextField) {
            // Update the binding on the main thread
            DispatchQueue.main.async {
                self.text = textField.text ?? ""
            }
        }
        
        // Handle return key
        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            return true
        }
        
        // Prevent the textfield from updating its own text
        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            if let text = textField.text,
               let textRange = Range(range, in: text) {
                let updatedText = text.replacingCharacters(in: textRange, with: string)
                DispatchQueue.main.async {
                    self.text = updatedText
                }
            }
            return true
        }
    }
}

// UIKit-based text view wrapper
struct UIKitTextView: UIViewRepresentable {
    @Binding var text: String
    let placeholder: String
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = .systemFont(ofSize: 16)
        textView.backgroundColor = .systemBackground
        textView.layer.borderColor = UIColor.systemGray4.cgColor
        textView.layer.borderWidth = 1
        textView.layer.cornerRadius = 8
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        if text != uiView.text {
            uiView.text = text
        }
        if uiView.text.isEmpty && !uiView.isFirstResponder {
            uiView.text = placeholder
            uiView.textColor = .placeholderText
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, placeholder: placeholder)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        @Binding var text: String
        let placeholder: String
        
        init(text: Binding<String>, placeholder: String) {
            self._text = text
            self.placeholder = placeholder
        }
        
        func textViewDidBeginEditing(_ textView: UITextView) {
            if textView.text == self.placeholder {
                DispatchQueue.main.async {
                    textView.text = ""
                    textView.textColor = .label
                }
            }
        }
        
        func textViewDidEndEditing(_ textView: UITextView) {
            if textView.text.isEmpty {
                DispatchQueue.main.async {
                    textView.text = self.placeholder
                    textView.textColor = .placeholderText
                }
            }
        }
        
        func textViewDidChange(_ textView: UITextView) {
            DispatchQueue.main.async {
                self.text = textView.text
            }
        }
    }
}

struct FeedbackAnalysisView: View {
    @StateObject private var feedbackManager = FeedbackManager.shared
    @State private var correctedName = ""
    @State private var additionalNotes = ""
    @State private var showingAlert = false
    @State private var isSubmitting = false
    @Binding var isPresented: Bool
    let originalResult: FoodRecognitionResult
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // Original Recognition Card
                VStack(alignment: .leading, spacing: 12) {
                    Text("Original Recognition")
                        .font(.title2)
                        .bold()
                    
                    HStack {
                        Text(originalResult.name)
                            .font(.headline)
                        Spacer()
                        Text("\(Int(originalResult.confidence * 100))% confident")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Input Fields
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Correct Food Name")
                            .font(.headline)
                        // Use plain SwiftUI TextField instead
                        TextField("Enter the correct food name", text: $correctedName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocorrectionDisabled(true)
                            .textInputAutocapitalization(.never)
                            .frame(height: 44)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Additional Notes")
                            .font(.headline)
                        UIKitTextView(text: $additionalNotes, placeholder: "Add any additional notes (optional)")
                            .frame(height: 100)
                    }
                }
                .padding()
                
                Spacer()
                
                // Submit Button
                Button {
                    submitFeedback()
                } label: {
                    HStack {
                        Text("Submit Feedback")
                            .fontWeight(.semibold)
                        if isSubmitting {
                            Spacer()
                            ProgressView()
                                .tint(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(correctedName.isEmpty ? Color.blue.opacity(0.5) : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(correctedName.isEmpty || isSubmitting)
                .padding()
            }
            .navigationTitle("Submit Feedback")
            .navigationBarItems(trailing: Button("Cancel") {
                isPresented = false
            })
            .alert(isPresented: $showingAlert) {
                if let error = feedbackManager.lastError {
                    return Alert(
                        title: Text("Error"),
                        message: Text(error),
                        dismissButton: .default(Text("OK"))
                    )
                } else {
                    return Alert(
                        title: Text("Success"),
                        message: Text("Thank you for your feedback!"),
                        dismissButton: .default(Text("OK")) {
                            isPresented = false
                        }
                    )
                }
            }
        }
    }
    
    private func submitFeedback() {
        guard !correctedName.isEmpty else { return }
        
        isSubmitting = true
        
        Task {
            do {
                await feedbackManager.submitFeedback(
                    originalResult: originalResult,
                    correctedName: correctedName,
                    additionalNotes: additionalNotes.isEmpty ? nil : additionalNotes
                )
                
                DispatchQueue.main.async {
                    isSubmitting = false
                    showingAlert = true
                }
            } catch {
                DispatchQueue.main.async {
                    isSubmitting = false
                    feedbackManager.lastError = error.localizedDescription
                    showingAlert = true
                }
            }
        }
    }
}

struct FeedbackAnalysisView_Previews: PreviewProvider {
    static var previews: some View {
        FeedbackAnalysisView(isPresented: .constant(true), originalResult: FoodRecognitionResult(
            id: UUID(),
            name: "Sample Food",
            confidence: 0.85,
            nutrition: nil,
            healthConsiderations: [],
            allergens: [],
            portionSize: nil,
            preparationMethod: nil,
            isFresh: nil,
            isDiabetesFriendly: nil,
            glycemicIndex: nil
        ))
    }
} 