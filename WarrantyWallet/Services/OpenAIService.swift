//
//  OpenAIService.swift
//  WarrantyWallet
//
//  Created by Ethan on 19/10/2025.
//

import Foundation
import Combine

class OpenAIService: ObservableObject {

    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1"
    private let ocrService = OCRService()
    
    init() {
        self.apiKey = Config.openAIAPIKey
        guard !apiKey.isEmpty else {
            fatalError("OpenAI API key is not configured. Please set OPENAI_API_KEY environment variable.")
        }
    }
    
    // MARK: - Text Extraction from Images using OCR + OpenAI
    
    func extractTextFromImage(_ imageData: Data) async throws -> String {
        print("🤖 OpenAIService: Starting text extraction from image")
        print("📊 OpenAIService: Image data size: \(imageData.count) bytes")
        
        // First, use OCR to extract text from the image
        print("🔍 OpenAIService: Calling OCR service to extract text")
        let extractedText = try await ocrService.extractTextFromImage(imageData)
        print("📝 OpenAIService: OCR extracted text: \(extractedText)")
        
        // Then, use OpenAI to clean up and improve the extracted text
        print("🧠 OpenAIService: Calling OpenAI to clean up extracted text")
        let cleanedText = try await processTextWithOpenAI(extractedText, returnType: .cleanedText) as! String
        print("✨ OpenAIService: OpenAI cleaned text: \(cleanedText)")
        
        return cleanedText
    }
    
    // MARK: - Extract Receipt Data as JSON
    
    func extractReceiptData(_ imageData: Data) async throws -> ReceiptData {
        print("🤖 OpenAIService: Starting receipt data extraction from image")
        print("📊 OpenAIService: Image data size: \(imageData.count) bytes")
        
        // First, use OCR to extract text from the image
        print("🔍 OpenAIService: Calling OCR service to extract text")
        let extractedText = try await ocrService.extractTextFromImage(imageData)
        print("📝 OpenAIService: OCR extracted text: \(extractedText)")
        
        // Then, use OpenAI to parse the text into structured JSON data
        print("🧠 OpenAIService: Calling OpenAI to parse receipt data")
        let receiptData = try await processTextWithOpenAI(extractedText, returnType: .receiptData) as! ReceiptData
        print("✨ OpenAIService: Parsed receipt data: \(receiptData)")
        
        return receiptData
    }
    
    // MARK: - Process Warranty Information
    
    func processWarrantyInfo(_ itemName: String, storeName: String = "") async throws -> WarrantyInfo {
        print("🧠 OpenAIService: Processing warranty info from search results")

        var prompt1: String
        if itemName == "" {
            prompt1 = "Find the warranty policy of \(itemName). Only provide results applicable to Australia. Provide the warranty period in months, a summary of the conditions, and the URL of the source."
        } else {
            prompt1 = "Find the warranty policy of \(itemName) from \(storeName). Only provide results applicable to Australia. Provide the warranty period in months, a summary of the conditions, and the URL of the source."
        }
        
        let response = try await fetchJSONResponse(
            prompt: prompt1,
            useWebSearch: true,
            responseType: String.self
        )
        
        let prompt2 = """
        Given the following summary of a warranty, extract warranty information and output a JSON object with the following fields:
        {
            "warrantyMonths": <integer or null>, // warranty period in months, use null if unknown
            "conditions": "<key warranty conditions and exclusions>",
            "evidenceUrl": "<the URL to the link for this information>"
        }

        IMPORTANT:
        - If a field cannot be determined, use null (not "Unknown").
        - Respond ONLY with a valid JSON object (no markdown or explanation).

        Summary:
        \(response)
        """
        
        return try await fetchJSONResponse(
            prompt: prompt2,
            useWebSearch: false,
            responseType: WarrantyInfo.self
        )
    }
    
    // MARK: - Process Return Policy Information
    
    func processReturnPolicyInfo(_ storeName: String, itemName: String = "") async throws -> ReturnPolicyInfo {
        print("🧠 OpenAIService: Processing return policy info from search results")
        var prompt1: String
        if itemName == "" {
            prompt1 = "Find the return policy of \(storeName). Prefer the policy regarding change of mind returns in Australia. Provide the return window in days, a summary of the conditions, and the URL of the source."
        } else {
            prompt1 = "Find the return policy of \(storeName) for the \(itemName). Prefer the policy regarding change of mind returns in Australia. Provide the return window in days, a summary of the conditions, and the URL of the source."
        }
        
        
        let response = try await fetchJSONResponse(
            prompt: prompt1,
            useWebSearch: true,
            responseType: String.self
        )
        
        
        let prompt2 = """
        Given the following summary of a store's return policy, extract return policy information and output a JSON object with the following fields:
        {
            "returnDays": <integer or null>, // return period in days, use null if unknown
            "conditions": "<key return conditions and requirements>",
            "evidenceUrl": "<the URL to the link for this information>"
        }

        IMPORTANT:
        - If a field cannot be determined, use null (not "Unknown").
        - Do not mention warranty information; strictly give return policy details and days.
        - Respond ONLY with a valid JSON object (no markdown).

        Summary:
        \(response)
        """
        
        
        return try await fetchJSONResponse(
            prompt: prompt2,
            useWebSearch: false,
            responseType: ReturnPolicyInfo.self
        )
    }
    
    // MARK: - Process Text with OpenAI (Combined Function)
    
    private func processTextWithOpenAI(_ text: String, returnType: ProcessType) async throws -> Any {
        print("🧹 OpenAIService: Starting text processing with OpenAI")
        print("📝 OpenAIService: Input text length: \(text.count) characters")
        print("🎯 OpenAIService: Processing type: \(returnType)")
        
        let prompt = """
        Given the following OCR-extracted text from a receipt, extract and output a JSON object with the following fields:
        {
            "itemName": "<name of the purchased item>",
            "storeName": "<store name, not link>",
            "storeUrl": "<link to the store>",
            "price": <price as a decimal>,
            "purchaseDate": "<date in DD-MM-YYYY format>"
        }
        If you cannot detect any of the fields, make your best guess based on the text. Return only the JSON object and nothing else. If there are multiple products, return the details of the product that appears first. 
        Fix small mistakes like spelling and OCR parsing errors, however, still be aware of model numbers and names.

        OCR Text:
        \(text)    
        """

        print("📝 OpenAIService: Created prompt for OpenAI")
        
        return try await fetchJSONResponse(
            prompt: prompt,
            useWebSearch: false,
            responseType: ReceiptData.self
        )
    }
    
    enum OpenAIClientError: LocalizedError {
        case httpFailure(String)
        case malformedContainer
        case missingText
        case incompatibleModes(expectedString: Bool)

        var errorDescription: String? {
            switch self {
            case .httpFailure(let body): return "Request failed: \(body)"
            case .malformedContainer:    return "Malformed Responses API container"
            case .missingText:           return "No text content in response"
            case .incompatibleModes(let expectedString):
                return expectedString
                ? "web_search returns plain text. Use responseType == String when useWebSearch == true."
                : "web_search is not compatible with JSON mode. Call again with useWebSearch == false for JSON."
            }
        }
    }

    func fetchJSONResponse<T: Decodable>(
        prompt: String,
        model: String = "gpt-4o-mini",
        useWebSearch: Bool = false,
        responseType: T.Type
    ) async throws -> T {
        let apiKey = apiKey
        let url = URL(string: "https://api.openai.com/v1/responses")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        // Build payload
        var payload: [String: Any] = [
            "model": model,
            "input": prompt
        ]

        if useWebSearch {
            // web_search is NOT compatible with JSON mode → request plain text
            payload["tools"] = [["type": "web_search"]]
            payload["text"] = ["format": ["type": "text"]]
        } else {
            // Strict JSON mode
            payload["text"] = ["format": ["type": "json_object"]]
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        // Execute
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw OpenAIClientError.httpFailure(body)
        }
        
        // Parse Responses API envelope (skip tool calls; pick first message)
        let any = try JSONSerialization.jsonObject(with: data, options: [])
        guard let root = any as? [String: Any],
              let output = root["output"] as? [[String: Any]] else {
            throw OpenAIClientError.malformedContainer
        }
        
        guard let message = output.first(where: { ($0["type"] as? String) == "message" }),
              let content = message["content"] as? [[String: Any]] else {
            throw OpenAIClientError.missingText
        }
        
        let text: String = {
            for part in content {
                if let t = part["text"] as? String { return t }
                if let t = part["output_text"] as? String { return t }
            }
            return ""
        }()

        guard !text.isEmpty else { throw OpenAIClientError.missingText }

        if useWebSearch {
            // Caller will re-invoke without web_search to get JSON. Return raw text ONLY when requested.
            guard T.self == String.self else {
                throw OpenAIClientError.incompatibleModes(expectedString: true)
            }
            return (text as! T)
        } else {
            // Strict JSON mode → decode directly, no recovery attempts.
            guard let jsonData = text.data(using: .utf8) else {
                throw OpenAIClientError.missingText
            }
            return try JSONDecoder().decode(T.self, from: jsonData)
        }
    }
    
    // MARK: - Process Type Enum
    
    private enum ProcessType {
        case cleanedText
        case receiptData
    }
}

// MARK: - Data Models

struct WarrantyInfo: Codable {
    let warrantyMonths: Int?
    let conditions: String
    let evidenceUrl: String?
}

struct ReturnPolicyInfo: Codable {
    let returnDays: Int?
    let conditions: String
    let evidenceUrl: String?
}

// MARK: - Errors

enum OpenAIError: Error, LocalizedError {
    case noContent
    case invalidResponse
    case apiKeyMissing
    
    var errorDescription: String? {
        switch self {
        case .noContent:
            return "No content received from OpenAI"
        case .invalidResponse:
            return "Invalid response format from OpenAI"
        case .apiKeyMissing:
            return "OpenAI API key is missing"
        }
    }
}
