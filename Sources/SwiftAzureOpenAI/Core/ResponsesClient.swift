import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// A simplified client for the Responses API that mimics the Python OpenAI SDK
public final class ResponsesClient {
    private let httpClient: HTTPClient
    private let responseService: ResponseService
    private let configuration: SAOAIConfiguration
    
    internal init(httpClient: HTTPClient, responseService: ResponseService, configuration: SAOAIConfiguration) {
        self.httpClient = httpClient
        self.responseService = responseService
        self.configuration = configuration
    }
    
    /// Create a response with simple string input (Python-style)
    public func create(
        model: String,
        input: String,
        maxOutputTokens: Int? = nil,
        temperature: Double? = nil,
        topP: Double? = nil,
        previousResponseId: String? = nil,
        reasoning: SAOAIReasoning? = nil
    ) async throws -> SAOAIResponse {
        let message = SAOAIMessage(
            role: .user,
            content: [.inputText(.init(text: input))]
        )
        
        let request = SAOAIRequest(
            model: model,
            input: [message],
            maxOutputTokens: maxOutputTokens,
            temperature: temperature,
            topP: topP,
            previousResponseId: previousResponseId,
            reasoning: reasoning
        )
        
        return try await sendRequest(request)
    }
    
    /// Create a response with array of messages (for more complex conversations)
    public func create(
        model: String,
        input: [SAOAIMessage],
        maxOutputTokens: Int? = nil,
        temperature: Double? = nil,
        topP: Double? = nil,
        tools: [SAOAITool]? = nil,
        previousResponseId: String? = nil,
        reasoning: SAOAIReasoning? = nil
    ) async throws -> SAOAIResponse {
        let request = SAOAIRequest(
            model: model,
            input: input,
            maxOutputTokens: maxOutputTokens,
            temperature: temperature,
            topP: topP,
            tools: tools,
            previousResponseId: previousResponseId,
            reasoning: reasoning
        )
        
        return try await sendRequest(request)
    }
    
    /// Retrieve a response by ID
    public func retrieve(_ responseId: String) async throws -> SAOAIResponse {
        var retrieveURL = configuration.baseURL
        retrieveURL = retrieveURL.appendingPathComponent(responseId)
        
        let request = APIRequest(
            method: "GET",
            url: retrieveURL,
            headers: configuration.headers
        )
        
        let (data, httpResponse) = try await httpClient.send(request)
        let result: APIResponse<SAOAIResponse> = try await responseService.processResponse(data, response: httpResponse, type: SAOAIResponse.self)
        return result.data
    }
    
    /// Delete a response by ID
    public func delete(_ responseId: String) async throws -> Bool {
        var deleteURL = configuration.baseURL
        deleteURL = deleteURL.appendingPathComponent(responseId)
        
        let request = APIRequest(
            method: "DELETE",
            url: deleteURL,
            headers: configuration.headers
        )
        
        let (_, httpResponse) = try await httpClient.send(request)
        return httpResponse.statusCode == 200 || httpResponse.statusCode == 204
    }
    
    // MARK: - Private Methods
    
    private func sendRequest(_ request: SAOAIRequest) async throws -> SAOAIResponse {
        let jsonData = try JSONEncoder().encode(request)
        
        let apiRequest = APIRequest(
            method: "POST",
            url: configuration.baseURL,
            headers: configuration.headers,
            body: jsonData
        )
        
        let (data, httpResponse) = try await httpClient.send(apiRequest)
        let result: APIResponse<SAOAIResponse> = try await responseService.processResponse(data, response: httpResponse, type: SAOAIResponse.self)
        return result.data
    }
}