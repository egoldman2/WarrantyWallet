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
    
    func processWarrantyInfo(_ searchResults: String) async throws -> WarrantyInfo {
        print("🧠 OpenAIService: Processing warranty info from search results")
        
        let url = URL(string: "\(baseURL)/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let prompt = """
        Given the following search results about a product, extract warranty information and output a JSON object with the following fields:
        {
            "warrantyMonths": "<warranty period as in integer in months>",
            "conditions": "<key warranty conditions and exclusions>",
            "evidenceUrl": "<the URL to the link for this information>"
        }
        
        If you cannot find specific information for any field, use "Unknown" as the value.
        Return only the JSON object and nothing else.
        
        Search Results:
        \(searchResults)
        """
        
        let payload: [String: Any] = [
            "model": "gpt-5-mini",
            "messages": [
                [
                    "role": "user",
                    "content": prompt
                ]
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw OpenAIError.invalidResponse
        }
        
        let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let choices = jsonResponse?["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw OpenAIError.noContent
        }
        
        guard let jsonData = content.data(using: .utf8) else {
            throw OpenAIError.invalidResponse
        }
        
        do {
            let warrantyInfo = try JSONDecoder().decode(WarrantyInfo.self, from: jsonData)
            return warrantyInfo
        } catch {
            // Return default values if parsing fails
            return WarrantyInfo(
                warrantyMonths: 12,
                conditions: "Standard warranty terms apply",
                evidenceUrl: "No evidence"
            )
        }
    }
    
    // MARK: - Process Return Policy Information
    
    func processReturnPolicyInfo(_ searchResults: String) async throws -> ReturnPolicyInfo {
        print("🧠 OpenAIService: Processing return policy info from search results")
        
        let url = URL(string: "\(baseURL)/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let prompt = """
        Given the following search results about a product, extract return policy information and output a JSON object with the following fields:
        {
            "returnDays": "<return period as an integer in days>",
            "conditions": "<key return conditions and requirements>",
            "evidenceUrl": "<the URL to the link for this information>"
        }
        
        If you cannot find specific information for any field, use "Unknown" as the value.
        Return only the JSON object and nothing else.
        
        Search Results:
        \(searchResults)
        """
        
        let payload: [String: Any] = [
            "model": "gpt-5-mini",
            "messages": [
                [
                    "role": "user",
                    "content": prompt
                ]
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw OpenAIError.invalidResponse
        }
        
        let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let choices = jsonResponse?["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw OpenAIError.noContent
        }
        
        guard let jsonData = content.data(using: .utf8) else {
            throw OpenAIError.invalidResponse
        }
        
        do {
            let returnInfo = try JSONDecoder().decode(ReturnPolicyInfo.self, from: jsonData)
            return returnInfo
        } catch {
            // Return default values if parsing fails
            return ReturnPolicyInfo(
                returnDays: 30,
                conditions: "Standard return policy applies",
                evidenceUrl: "No evidence"
            )
        }
    }
    
    // MARK: - Process Text with OpenAI (Combined Function)
    
    private func processTextWithOpenAI(_ text: String, returnType: ProcessType) async throws -> Any {
        print("🧹 OpenAIService: Starting text processing with OpenAI")
        print("📝 OpenAIService: Input text length: \(text.count) characters")
        print("🎯 OpenAIService: Processing type: \(returnType)")
        
        let url = URL(string: "\(baseURL)/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        print("🌐 OpenAIService: Created request to OpenAI API")
        
        let prompt: String
        switch returnType {
        case .cleanedText:
            prompt = """
            Clean up and improve this OCR-extracted text from a receipt. 
            Fix any OCR errors, correct spelling mistakes, and format it properly.
            Return only the cleaned text without any additional commentary.
            
            OCR Text:
            \(text)
            """
        case .receiptData:
            prompt = """
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
        }
        print("📝 OpenAIService: Created prompt for OpenAI")
        
        let payload: [String: Any] = [
            "model": "gpt-5-mini",
            "messages": [
                [
                    "role": "user",
                    "content": prompt
                ]
            ]
        ]
        print("📦 OpenAIService: Created payload for OpenAI request")
        
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        print("📤 OpenAIService: Sending request to OpenAI API")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        print("📥 OpenAIService: Received response from OpenAI API")
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            print("❌ OpenAIService: Invalid response status: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
            throw OpenAIError.invalidResponse
        }
        print("✅ OpenAIService: Received successful response from OpenAI")
        
        let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        print("🔍 OpenAIService: Parsing JSON response from OpenAI")
        guard let choices = jsonResponse?["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String else {
            print("❌ OpenAIService: Failed to parse OpenAI response")
            throw OpenAIError.noContent
        }
        
        print("📄 OpenAIService: Raw response: \(content)")
        
        switch returnType {
        case .cleanedText:
            print("✨ OpenAIService: Successfully cleaned text: \(content)")
            return content
            
        case .receiptData:
            // Parse the JSON content into ReceiptData
            guard let jsonData = content.data(using: .utf8) else {
                print("❌ OpenAIService: Failed to convert content to data")
                throw OpenAIError.invalidResponse
            }
            
            do {
                let receiptData = try JSONDecoder().decode(ReceiptData.self, from: jsonData)
                print("✨ OpenAIService: Successfully parsed receipt data: \(receiptData)")
                return receiptData
            } catch {
                print("❌ OpenAIService: Failed to decode JSON: \(error.localizedDescription)")
                // Return a default ReceiptData if parsing fails
                return ReceiptData(
                    itemName: "Unknown Item",
                    storeName: "Unknown Store",
                    price: 0.0,
                    purchaseDate: nil
                )
            }
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
    let warrantyMonths: Int
    let conditions: String
    let evidenceUrl: String?
}

struct ReturnPolicyInfo: Codable {
    let returnDays: Int
    let conditions: String
    let evidenceUrl: String?
}

struct ReceiptInfo: Codable {
    let storeName: String?
    let items: [ReceiptItem]
    let purchaseDate: String
    let totalAmount: Double?
    let warrantyInfo: String?
}

struct ReceiptItem: Codable {
    let name: String
    let price: Double
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
