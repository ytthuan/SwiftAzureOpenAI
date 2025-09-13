import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// A simplified client for the Responses API that mimics the Python OpenAI SDK
public final class ResponsesClient {
    private let httpClient: HTTPClient
    private let responseService: ResponseServiceProtocol
    private let configuration: SAOAIConfiguration
    
    internal init(httpClient: HTTPClient, responseService: ResponseServiceProtocol, configuration: SAOAIConfiguration) {
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
        reasoning: SAOAIReasoning? = nil,
        text: SAOAIText? = nil
    ) async throws -> SAOAIResponse {
        let message = SAOAIMessage(
            role: .user,
            content: [.inputText(.init(text: input))]
        )
        
        let request = SAOAIRequest(
            model: model,
            input: [.message(message)],
            maxOutputTokens: maxOutputTokens,
            temperature: temperature,
            topP: topP,
            previousResponseId: previousResponseId,
            reasoning: reasoning,
            text: text
        )
        
        return try await sendRequest(request)
    }
    
    /// Create a streaming response with simple string input (Python-style)
    public func createStreaming(
        model: String,
        input: String,
        maxOutputTokens: Int? = nil,
        temperature: Double? = nil,
        topP: Double? = nil,
        previousResponseId: String? = nil,
        reasoning: SAOAIReasoning? = nil,
        text: SAOAIText? = nil
    ) -> AsyncThrowingStream<SAOAIStreamingResponse, Error> {
        let message = SAOAIMessage(
            role: .user,
            content: [.inputText(.init(text: input))]
        )
        
        let request = SAOAIRequest(
            model: model,
            input: [.message(message)],
            maxOutputTokens: maxOutputTokens,
            temperature: temperature,
            topP: topP,
            previousResponseId: previousResponseId,
            reasoning: reasoning,
            text: text,
            stream: true
        )
        
        return sendStreamingRequest(request)
    }

    /// Create a response with simple string input and tools (Python-style)
    public func create(
        model: String,
        input: String,
        tools: [SAOAITool],
        maxOutputTokens: Int? = nil,
        temperature: Double? = nil,
        topP: Double? = nil,
        previousResponseId: String? = nil,
        reasoning: SAOAIReasoning? = nil,
        text: SAOAIText? = nil
    ) async throws -> SAOAIResponse {
        let message = SAOAIMessage(
            role: .user,
            content: [.inputText(.init(text: input))]
        )
        
        let request = SAOAIRequest(
            model: model,
            input: [.message(message)],
            maxOutputTokens: maxOutputTokens,
            temperature: temperature,
            topP: topP,
            tools: tools,
            previousResponseId: previousResponseId,
            reasoning: reasoning,
            text: text
        )
        
        return try await sendRequest(request)
    }
    
    /// Create a streaming response with simple string input and tools (Python-style)
    public func createStreaming(
        model: String,
        input: String,
        tools: [SAOAITool],
        maxOutputTokens: Int? = nil,
        temperature: Double? = nil,
        topP: Double? = nil,
        previousResponseId: String? = nil,
        reasoning: SAOAIReasoning? = nil,
        text: SAOAIText? = nil
    ) -> AsyncThrowingStream<SAOAIStreamingResponse, Error> {
        let message = SAOAIMessage(
            role: .user,
            content: [.inputText(.init(text: input))]
        )
        
        let request = SAOAIRequest(
            model: model,
            input: [.message(message)],
            maxOutputTokens: maxOutputTokens,
            temperature: temperature,
            topP: topP,
            tools: tools,
            previousResponseId: previousResponseId,
            reasoning: reasoning,
            text: text,
            stream: true
        )
        
        return sendStreamingRequest(request)
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
        reasoning: SAOAIReasoning? = nil,
        text: SAOAIText? = nil
    ) async throws -> SAOAIResponse {
        let inputArray = input.map { SAOAIInput.message($0) }
        let request = SAOAIRequest(
            model: model,
            input: inputArray,
            maxOutputTokens: maxOutputTokens,
            temperature: temperature,
            topP: topP,
            tools: tools,
            previousResponseId: previousResponseId,
            reasoning: reasoning,
            text: text
        )
        
        return try await sendRequest(request)
    }
    
    /// Create a streaming response with array of messages (for more complex conversations)
    public func createStreaming(
        model: String,
        input: [SAOAIMessage],
        maxOutputTokens: Int? = nil,
        temperature: Double? = nil,
        topP: Double? = nil,
        tools: [SAOAITool]? = nil,
        previousResponseId: String? = nil,
        reasoning: SAOAIReasoning? = nil,
        text: SAOAIText? = nil
    ) -> AsyncThrowingStream<SAOAIStreamingResponse, Error> {
        let inputArray = input.map { SAOAIInput.message($0) }
        let request = SAOAIRequest(
            model: model,
            input: inputArray,
            maxOutputTokens: maxOutputTokens,
            temperature: temperature,
            topP: topP,
            tools: tools,
            previousResponseId: previousResponseId,
            reasoning: reasoning,
            text: text,
            stream: true
        )
        
        return sendStreamingRequest(request)
    }
    
    /// Create a streaming response with function call outputs (for tool results)
    /// This method only sends minimal parameters to match Azure OpenAI requirements
    public func createStreaming(
        model: String,
        functionCallOutputs: [SAOAIInputContent.FunctionCallOutput],
        previousResponseId: String? = nil
    ) -> AsyncThrowingStream<SAOAIStreamingResponse, Error> {
        let inputArray = functionCallOutputs.map { SAOAIInput.functionCallOutput($0) }
        
        // Create a minimal request with only required fields
        var request = SAOAIMinimalRequest(
            model: model,
            input: inputArray,
            stream: true
        )
        
        // Only add previousResponseId if it's not nil
        if let previousResponseId = previousResponseId {
            request.previousResponseId = previousResponseId
        }
        
        return sendMinimalStreamingRequest(request)
    }
    
    /// Send minimal streaming request with only essential parameters
    private func sendMinimalStreamingRequest(_ request: SAOAIMinimalRequest) -> AsyncThrowingStream<SAOAIStreamingResponse, Error> {
        // Pre-encode the request to avoid capturing it in the closure
        let requestData: Data
        do {
            requestData = try JSONEncoder().encode(request)
        } catch {
            return AsyncThrowingStream { continuation in
                continuation.finish(throwing: error)
            }
        }
        
        // Capture needed values outside the stream
        let baseURL = self.configuration.baseURL
        let httpClient = self.httpClient
        let configHeaders = self.configuration.headers
        
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    // Merge configuration headers with streaming-specific headers
                    var streamingHeaders = configHeaders
                    streamingHeaders["Accept"] = "text/event-stream"
                    
                    let apiRequest = APIRequest(
                        method: "POST",
                        url: baseURL,
                        headers: streamingHeaders,
                        body: requestData
                    )
                    
                    let stream = httpClient.sendStreaming(apiRequest)
                    
                    for try await chunk in stream {
                        if let response = try OptimizedSSEParser.parseSSEChunkOptimized(chunk) {
                            continuation.yield(response)
                        }
                        
                        if OptimizedSSEParser.isCompletionChunkOptimized(chunk) {
                            continuation.finish()
                            return
                        }
                    }
                    
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    /// Create a streaming response with function call outputs (for tool results) - Extended version
    /// This method allows all parameters but should be used carefully
    public func createStreamingWithAllParameters(
        model: String,
        functionCallOutputs: [SAOAIInputContent.FunctionCallOutput],
        maxOutputTokens: Int? = nil,
        temperature: Double? = nil,
        topP: Double? = nil,
        tools: [SAOAITool]? = nil,
        previousResponseId: String? = nil,
        reasoning: SAOAIReasoning? = nil,
        text: SAOAIText? = nil
    ) -> AsyncThrowingStream<SAOAIStreamingResponse, Error> {
        let inputArray = functionCallOutputs.map { SAOAIInput.functionCallOutput($0) }
        let request = SAOAIRequest(
            model: model,
            input: inputArray,
            maxOutputTokens: maxOutputTokens,
            temperature: temperature,
            topP: topP,
            tools: tools, // Include tools for function output responses
            previousResponseId: previousResponseId,
            reasoning: reasoning,
            text: text,
            stream: true
        )
        
        return sendStreamingRequest(request)
    }
    
    /// Create a non-streaming response with function call outputs (for tool results)
    /// This is the non-streaming equivalent of `createStreamingWithAllParameters`
    public func createWithFunctionCallOutputs(
        model: String,
        functionCallOutputs: [SAOAIInputContent.FunctionCallOutput],
        maxOutputTokens: Int? = nil,
        temperature: Double? = nil,
        topP: Double? = nil,
        tools: [SAOAITool]? = nil,
        previousResponseId: String? = nil,
        reasoning: SAOAIReasoning? = nil,
        text: SAOAIText? = nil
    ) async throws -> SAOAIResponse {
        let inputArray = functionCallOutputs.map { SAOAIInput.functionCallOutput($0) }
        let request = SAOAIRequest(
            model: model,
            input: inputArray,
            maxOutputTokens: maxOutputTokens,
            temperature: temperature,
            topP: topP,
            tools: tools, // Include tools for function output responses
            previousResponseId: previousResponseId,
            reasoning: reasoning,
            text: text,
            stream: false // Non-streaming
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
    
    private func sendStreamingRequest(_ request: SAOAIRequest) -> AsyncThrowingStream<SAOAIStreamingResponse, Error> {
        // Pre-encode the request to avoid capturing it in the closure
        let requestData: Data
        do {
            requestData = try JSONEncoder().encode(request)
        } catch {
            return AsyncThrowingStream { continuation in
                continuation.finish(throwing: error)
            }
        }
        
        // Capture needed values outside the stream
        let baseURL = self.configuration.baseURL
        let httpClient = self.httpClient
        let configHeaders = self.configuration.headers
        
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    // Merge configuration headers with streaming-specific headers
                    var streamingHeaders = configHeaders
                    streamingHeaders["Accept"] = "text/event-stream"
                    
                    let apiRequest = APIRequest(
                        method: "POST",
                        url: baseURL,
                        headers: streamingHeaders,
                        body: requestData
                    )
                    
                    let stream = httpClient.sendStreaming(apiRequest)
                    
                    for try await chunk in stream {
                        if let response = try OptimizedSSEParser.parseSSEChunkOptimized(chunk) {
                            continuation.yield(response)
                        }
                        
                        if OptimizedSSEParser.isCompletionChunkOptimized(chunk) {
                            continuation.finish()
                            return
                        }
                    }
                    
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}