import Foundation

/// Parser for OpenAI/Azure OpenAI Server-Sent Events (SSE) streaming format
public final class SSEParser: Sendable {
    
    /// Parse SSE data chunks and extract JSON payload
    public static func parseSSEChunk(_ data: Data) throws -> SAOAIStreamingResponse? {
        guard let string = String(data: data, encoding: .utf8) else {
            throw SAOAIError.decodingError(NSError(domain: "SSEParser", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid UTF-8 data"]))
        }
        
        let lines = string.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Check for completion signal
            if trimmedLine == "data: [DONE]" {
                return nil // Signals completion
            }
            
            // Parse data lines
            if trimmedLine.hasPrefix("data: ") {
                let jsonString = String(trimmedLine.dropFirst(6)) // Remove "data: " prefix
                
                // Skip empty data lines
                if jsonString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    continue
                }
                
                guard let jsonData = jsonString.data(using: .utf8) else {
                    continue
                }
                
                do {
                    let decoder = JSONDecoder()
                    let response = try decoder.decode(SAOAIStreamingResponse.self, from: jsonData)
                    return response
                } catch {
                    // Skip malformed JSON chunks
                    continue
                }
            }
        }
        
        return nil
    }
    
    /// Check if SSE chunk indicates completion
    public static func isCompletionChunk(_ data: Data) -> Bool {
        guard let string = String(data: data, encoding: .utf8) else {
            return false
        }
        
        return string.trimmingCharacters(in: .whitespacesAndNewlines).contains("data: [DONE]")
    }
}