import Foundation
import SwiftAzureOpenAI

// MARK: - Example demonstrating the new multi-modal input and response chaining features

/// This example shows how to use the enhanced SwiftAzureOpenAI library to meet the requirements
/// specified in the GitHub issue for multi-modal input support and response chaining.

// MARK: - Configuration Setup
nonisolated(unsafe) let azureConfig = SAOAIAzureConfiguration(
    endpoint: "https://your-resource.openai.azure.com",
    apiKey: "your-api-key",
    deploymentName: "gpt-4o"
)

nonisolated(unsafe) let client = SAOAIClient(configuration: azureConfig)

// MARK: - Example 1: Multi-modal input with image URL (as requested in the issue)
func demonstrateMultiModalWithImageURL() async throws {
    print("=== Example 1: Multi-modal input with image URL ===")
    
    // This matches the Python-style API requested in the issue:
    // input=[
    //     {
    //         "role": "user",
    //         "content": [
    //             { "type": "input_text", "text": "what is in this image?" },
    //             {
    //                 "type": "input_image",
    //                 "image_url": "<image_URL>"
    //             }
    //         ]
    //     }
    // ]
    
    let message = SAOAIMessage(
        role: .user,
        text: "what is in this image?",
        imageURL: "https://example.com/image.jpg"
    )
    
    let response = try await client.responses.create(
        model: "gpt-4o",
        input: [message]
    )
    
    print("Response ID: \(response.id ?? "N/A")")
    print("Model: \(response.model ?? "N/A")")
    // Process response...
}

// MARK: - Example 2: Multi-modal input with base64 image (as requested in the issue)
func demonstrateMultiModalWithBase64Image() async throws {
    print("\n=== Example 2: Multi-modal input with base64 image ===")
    
    // This matches the Python-style API with base64 encoding requested in the issue:
    // def encode_image(image_path):
    //     with open(image_path, "rb") as image_file:
    //         return base64.b64encode(image_file.read()).decode("utf-8")
    // base64_image = encode_image(image_path)
    
    let base64Image = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg=="
    
    let message = SAOAIMessage(
        role: .user,
        text: "what is in this image?",
        base64Image: base64Image,
        mimeType: "image/png"
    )
    
    let response = try await client.responses.create(
        model: "gpt-4o",
        input: [message]
    )
    
    print("Response ID: \(response.id ?? "N/A")")
    print("Model: \(response.model ?? "N/A")")
    // Process response...
}

// MARK: - Example 3: Response chaining with previous_response_id (as requested in the issue)
func demonstrateResponseChaining() async throws {
    print("\n=== Example 3: Response chaining with previous_response_id ===")
    
    // This matches the Python-style API with chaining requested in the issue:
    // response = client.responses.create(
    //     model="gpt-4o",
    //     input="Define and explain the concept of catastrophic forgetting?"
    // )
    // second_response = client.responses.create(
    //     model="gpt-4o",
    //     previous_response_id=response.id,
    //     input=[{"role": "user", "content": "Explain this at a level that could be understood by a college freshman"}]
    // )
    
    // First request
    let firstResponse = try await client.responses.create(
        model: "gpt-4o",
        input: "Define and explain the concept of catastrophic forgetting?"
    )
    
    print("First response ID: \(firstResponse.id ?? "N/A")")
    
    // Second request chaining from the first
    let secondResponse = try await client.responses.create(
        model: "gpt-4o",
        input: [SAOAIMessage(role: .user, text: "Explain this at a level that could be understood by a college freshman")],
        previousResponseId: firstResponse.id
    )
    
    print("Second response ID: \(secondResponse.id ?? "N/A")")
    print("Chained from: \(firstResponse.id ?? "N/A")")
    // Process chained response...
}

// MARK: - Example 4: Complex multi-modal request with manual content creation
func demonstrateComplexMultiModal() async throws {
    print("\n=== Example 4: Complex multi-modal request ===")
    
    // For more complex scenarios, you can still manually create content arrays
    let message = SAOAIMessage(
        role: .user,
        content: [
            .inputText(.init(text: "Please analyze these images and compare them:")),
            .inputImage(.init(imageURL: "https://example.com/image1.jpg")),
            .inputImage(.init(base64Data: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg==", mimeType: "image/png")),
            .inputText(.init(text: "What are the key differences?"))
        ]
    )
    
    let response = try await client.responses.create(
        model: "gpt-4o",
        input: [message]
    )
    
    print("Complex response ID: \(response.id ?? "N/A")")
    // Process response...
}

// MARK: - Example 5: Complete workflow demonstrating all new features
func demonstrateCompleteWorkflow() async throws {
    print("\n=== Example 5: Complete workflow with all new features ===")
    
    // Step 1: Initial image analysis
    let analysisResponse = try await client.responses.create(
        model: "gpt-4o",
        input: [SAOAIMessage(
            role: .user,
            text: "Analyze this architectural diagram",
            imageURL: "https://example.com/architecture.png"
        )]
    )
    
    // Step 2: Follow-up question with chaining
    let followUpResponse = try await client.responses.create(
        model: "gpt-4o",
        input: "Can you suggest improvements to this architecture?",
        previousResponseId: analysisResponse.id
    )
    
    // Step 3: Compare with another image using base64
    let base64Image = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg=="
    let comparisonResponse = try await client.responses.create(
        model: "gpt-4o",
        input: [SAOAIMessage(
            role: .user,
            text: "Compare the previous architecture with this improved version",
            base64Image: base64Image,
            mimeType: "image/png"
        )],
        previousResponseId: followUpResponse.id
    )
    
    print("Analysis response ID: \(analysisResponse.id ?? "N/A")")
    print("Follow-up response ID: \(followUpResponse.id ?? "N/A")")
    print("Comparison response ID: \(comparisonResponse.id ?? "N/A")")
}

// MARK: - Main execution

func runExamples() async {
    print("🚀 SwiftAzureOpenAI - Multi-Modal Input and Response Chaining Examples")
    print("======================================================================")
    
    // Note: These examples would make actual HTTP calls if run with real credentials
    print("📝 Example code demonstrates the new capabilities:")
    print("   • Multi-modal input with image URLs")
    print("   • Multi-modal input with base64-encoded images")
    print("   • Response chaining with previous_response_id")
    print("   • Complex multi-modal requests")
    print("   • Complete workflows combining all features")
    
    print("\n🔧 To run these examples with real API calls:")
    print("   1. Replace the configuration with your actual Azure OpenAI credentials")
    print("   2. Replace example image URLs with real image URLs")
    print("   3. Replace example base64 data with real image data")
    print("   4. Uncomment the function calls below")
    
    // Uncomment these lines to run with real API calls:
    // try await demonstrateMultiModalWithImageURL()
    // try await demonstrateMultiModalWithBase64Image()
    // try await demonstrateResponseChaining()
    // try await demonstrateComplexMultiModal()
    // try await demonstrateCompleteWorkflow()
}

// Run the examples
// Task { await runExamples() }

@main
struct MultiModalExample {
    static func main() async {
        print("\n✨ All examples are ready to use!")
        print("The SwiftAzureOpenAI library now supports:")
        print("  ✅ Multi-modal input (text + images)")
        print("  ✅ Base64 image encoding")
        print("  ✅ Response chaining with previous_response_id")
        print("  ✅ Python-style API matching the GitHub issue requirements")
        print("  ✅ Full backward compatibility")
        
        await runExamples()
    }
}