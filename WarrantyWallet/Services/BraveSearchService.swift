//
//  BraveSearchService.swift
//  WarrantyWallet
//
//  Created by Ethan on 20/10/2025.
//

import Foundation

class BraveSearchService {
    
    private let apiKey: String
    private let baseURL = "https://api.search.brave.com/res/v1/web/search"
    private let openAIService = OpenAIService()
    
    init() {
        self.apiKey = Config.braveSearchAPIKey
        guard !apiKey.isEmpty else {
            fatalError("Brave Search API key is not configured. Please set BRAVE_SEARCH_API_KEY environment variable.")
        }
    }
    
    // MARK: - Search for Warranty Information
    
    func searchWarrantyInfo(for productName: String, country: String = "australia") async throws -> WarrantyInfo {
        print("🔍 BraveSearchService: Searching for warranty info for product: \(productName)")
        
        
        
        let query = "\(productName) warranty period \(country)"
        let searchResults = try await performSearch(query: query, country: country)
        
        // Pass results to OpenAI for processing
        let warrantyInfo = try await openAIService.processWarrantyInfo(searchResults)
        
        return warrantyInfo
    }
    
    // MARK: - Search for Return Policy Information
    
    func searchReturnPolicyInfo(for storeName: String, country: String = "australia") async throws -> ReturnPolicyInfo {
        print("🔍 BraveSearchService: Searching for return policy info for product: \(storeName)")
        
        let query = "\"\(storeName)\" return policy \(country)"
        let searchResults = try await performSearch(query: query, country: country)
        
        // Pass results to OpenAI for processing
        let returnInfo = try await openAIService.processReturnPolicyInfo(searchResults)
        
        return returnInfo
    }
    
    // MARK: - Perform Search
    
    private func performSearch(query: String, country: String) async throws -> String {
        print("🌐 BraveSearchService: Starting search with query: \(query)")
        
        guard var urlComponents = URLComponents(string: baseURL) else {
            throw BraveSearchError.invalidURL
        }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "count", value: "10"),
            URLQueryItem(name: "search_lang", value: "en"),
            URLQueryItem(name: "country", value: "AU"),
            URLQueryItem(name: "result_filter", value: "web")
        ]
        
        guard let url = urlComponents.url else {
            throw BraveSearchError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("gzip", forHTTPHeaderField: "Accept-Encoding")
        request.setValue(apiKey, forHTTPHeaderField: "X-Subscription-Token")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ BraveSearchService: Non-HTTP response received.")
            throw BraveSearchError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            let bodyPreview = String(data: data, encoding: .utf8) ?? "<non-utf8 body>"
            print("❌ BraveSearchService: HTTP status code: \(httpResponse.statusCode)\nResponse body: \(bodyPreview)")
            throw BraveSearchError.invalidResponse
        }
        
        let searchResponse = try JSONDecoder().decode(BraveSearchResponse.self, from: data)
        
        guard let webResults = searchResponse.web?.results, !webResults.isEmpty else {
            throw BraveSearchError.noResults
        }
        
        // Combine search results into a single text for OpenAI processing
        let combinedText = webResults.prefix(5).map { result in
            "Title: \(result.title)\nDescription: \(result.description)\nURL: \(result.url)"
        }.joined(separator: "\n\n")
        
        print(combinedText)
        
        return combinedText
    }
}

// MARK: - Data Models

struct BraveSearchResponse: Codable {
    let web: WebResults?
}

struct WebResults: Codable {
    let results: [BraveSearchResult]?
}

struct BraveSearchResult: Codable {
    let title: String
    let url: String
    let description: String
    let age: String?
    let extraSnippets: [String]?
}

// MARK: - Errors

enum BraveSearchError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case noResults
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL for Brave Search API"
        case .invalidResponse:
            return "Invalid response from Brave Search API"
        case .noResults:
            return "No search results found"
        }
    }
}
