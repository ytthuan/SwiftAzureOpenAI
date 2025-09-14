import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Optimized URLSession configuration for SwiftAzureOpenAI network requests
/// Provides tuned settings for improved performance and reliability
public final class OptimizedURLSession: @unchecked Sendable {
    public static let shared = OptimizedURLSession()
    
    public let urlSession: URLSession
    
    private init() {
        let config = URLSessionConfiguration.default
        
        // Optimize connection behavior
        config.httpMaximumConnectionsPerHost = 8
        config.timeoutIntervalForRequest = 30.0
        config.timeoutIntervalForResource = 120.0
        
        // Optimize for API requests
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil // Disable URL cache for API requests
        
        // Disable cookies for API requests
        config.httpShouldSetCookies = false
        
        #if !os(watchOS) && !os(tvOS)
        // Set appropriate service type for network processing
        config.networkServiceType = .default
        #endif
        
        // Configure for concurrent requests
        config.httpMaximumConnectionsPerHost = 6
        
        self.urlSession = URLSession(configuration: config)
    }
    
    deinit {
        urlSession.invalidateAndCancel()
    }
}