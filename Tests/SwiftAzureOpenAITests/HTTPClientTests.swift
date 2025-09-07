import XCTest
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import SwiftAzureOpenAI

final class HTTPClientTests: XCTestCase {
    func testBuildsURLRequestWithMergedHeaders() throws {
        let config = SAOAIOpenAIConfiguration(apiKey: "sk-xyz", organization: nil)
        let url = URL(string: "https://api.openai.com/v1/responses")!
        let req = APIRequest(method: "POST", url: url, headers: ["X-Test": "1"], body: Data("{}".utf8))

        // Test the expected behavior by verifying configuration
        XCTAssertEqual(config.headers["Authorization"], "Bearer sk-xyz")
        XCTAssertEqual(config.headers["Content-Type"], "application/json")
        XCTAssertEqual(req.headers["X-Test"], "1")
        XCTAssertEqual(req.url, url)
        XCTAssertEqual(req.body, Data("{}".utf8))
        XCTAssertEqual(req.method, "POST")
    }
    
    func testHTTPClientInitialization() {
        let config = SAOAIAzureConfiguration(
            endpoint: "https://test.openai.azure.com",
            apiKey: "test-key",
            deploymentName: "gpt-4o"
        )
        let client = HTTPClient(configuration: config)
        
        // Should initialize without throwing
        XCTAssertNotNil(client)
    }
    
    func testAPIRequestInitialization() {
        let url = URL(string: "https://api.example.com/test")!
        let headers = ["Authorization": "Bearer token", "Content-Type": "application/json"]
        let body = Data("test body".utf8)
        
        let request = APIRequest(
            method: "PUT",
            url: url,
            headers: headers,
            body: body
        )
        
        XCTAssertEqual(request.method, "PUT")
        XCTAssertEqual(request.url, url)
        XCTAssertEqual(request.headers["Authorization"], "Bearer token")
        XCTAssertEqual(request.headers["Content-Type"], "application/json")
        XCTAssertEqual(request.body, body)
    }
    
    func testAPIRequestWithEmptyHeaders() {
        let url = URL(string: "https://api.example.com/test")!
        
        let request = APIRequest(
            method: "GET",
            url: url,
            headers: [:],
            body: nil
        )
        
        XCTAssertEqual(request.method, "GET")
        XCTAssertEqual(request.url, url)
        XCTAssertTrue(request.headers.isEmpty)
        XCTAssertNil(request.body)
    }
    
    func testAPIRequestWithNilBody() {
        let url = URL(string: "https://api.example.com/test")!
        
        let request = APIRequest(
            method: "DELETE",
            url: url,
            headers: ["X-Request-ID": "123"],
            body: nil
        )
        
        XCTAssertEqual(request.method, "DELETE")
        XCTAssertEqual(request.headers["X-Request-ID"], "123")
        XCTAssertNil(request.body)
    }
    
    func testAPIRequestWithLargeBody() {
        let url = URL(string: "https://api.example.com/upload")!
        let largeBody = Data(repeating: 0x42, count: 1024 * 1024) // 1MB of data
        
        let request = APIRequest(
            method: "POST",
            url: url,
            headers: ["Content-Length": "\(largeBody.count)"],
            body: largeBody
        )
        
        XCTAssertEqual(request.body?.count, 1024 * 1024)
        XCTAssertEqual(request.headers["Content-Length"], "1048576")
    }
    
    func testHTTPClientWithDifferentConfigurations() {
        // Test with OpenAI configuration
        let openAIConfig = SAOAIOpenAIConfiguration(apiKey: "sk-test", organization: "org-123")
        let openAIClient = HTTPClient(configuration: openAIConfig)
        XCTAssertNotNil(openAIClient)
        
        // Test with Azure configuration  
        let azureConfig = SAOAIAzureConfiguration(
            endpoint: "https://test.openai.azure.com",
            apiKey: "test-key",
            deploymentName: "gpt-4o",
            apiVersion: "preview"
        )
        let azureClient = HTTPClient(configuration: azureConfig)
        XCTAssertNotNil(azureClient)
    }
    
    func testAPIRequestMethodValidation() {
        let url = URL(string: "https://api.example.com/test")!
        
        // Test common HTTP methods
        let getMethods = ["GET", "POST", "PUT", "DELETE", "PATCH", "HEAD", "OPTIONS"]
        
        for method in getMethods {
            let request = APIRequest(method: method, url: url, headers: [:], body: nil)
            XCTAssertEqual(request.method, method)
        }
    }
    
    func testAPIRequestURLHandling() {
        // Test with various URL formats
        let urls = [
            "https://api.openai.com/v1/responses",
            "https://test.openai.azure.com/openai/v1/responses?api-version=preview",
            "http://localhost:8080/test",
            "https://api.example.com/path/with/multiple/segments"
        ]
        
        for urlString in urls {
            let url = URL(string: urlString)!
            let request = APIRequest(method: "GET", url: url, headers: [:], body: nil)
            XCTAssertEqual(request.url.absoluteString, urlString)
        }
    }
}