import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

struct TestRequest: Codable {
    let model: String
    let input: [InputMessage]
    let max_output_tokens: Int?
    let reasoning: ReasoningConfig?
    let text: TextConfig?
}

struct InputMessage: Codable {
    let role: String
    let content: [ContentPart]
}

struct ContentPart: Codable {
    let type: String
    let text: String?
}

struct ReasoningConfig: Codable {
    let effort: String
    let summary: String?
}

struct TextConfig: Codable {
    let verbosity: String
}

func testHighReasoning() async {
    guard let endpoint = ProcessInfo.processInfo.environment["AZURE_OPENAI_ENDPOINT"],
          let apiKey = ProcessInfo.processInfo.environment["COPILOT_AGENT_AZURE_OPENAI_API_KEY"],
          let deployment = ProcessInfo.processInfo.environment["AZURE_OPENAI_DEPLOYMENT"] else {
        print("Missing required environment variables")
        return
    }
    
    let url = URL(string: "\(endpoint)/openai/v1/responses?api-version=preview")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue(apiKey, forHTTPHeaderField: "api-key")
    
    let testRequest = TestRequest(
        model: deployment,
        input: [InputMessage(
            role: "user",
            content: [ContentPart(type: "input_text", text: "Calculate the square root of 144")]
        )],
        max_output_tokens: 500,
        reasoning: ReasoningConfig(effort: "high", summary: "detailed"),
        text: TextConfig(verbosity: "low")
    )
    
    do {
        let jsonData = try JSONEncoder().encode(testRequest)
        request.httpBody = jsonData
        
        print("Making request with high reasoning...")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("Status: \(httpResponse.statusCode)")
        }
        
        print("Raw response:")
        if let responseString = String(data: data, encoding: .utf8) {
            print(responseString)
        }
        
    } catch {
        print("Error: \(error)")
    }
}

await testHighReasoning()
