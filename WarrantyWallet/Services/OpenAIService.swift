//
//  OpenAIService.swift
//  WarrantyWallet
//
//  Created by Ethan on 19/10/2025.
//

import Foundation
import OpenAI
import Combine

class OpenAIService: ObservableObject {

    private let openAI: OpenAI
    
    init() {
        let apiKey = Config.openAIAPIKey
        self.openAI = OpenAI(apiToken: apiKey)
    }
    
    // MARK: - Text Extraction from Images
    
    func extractTextFromImage(_ imageData: Data) async throws -> String {
        // For now, return a placeholder until we can test the correct API
        // This will be updated once the package is properly integrated
        return "Receipt text extraction will be implemented once OpenAI package is properly configured"
    }
    
    // MARK: - Warranty Information Lookup
    
    func lookupWarrantyInformation(for itemName: String, storeName: String? = nil) async throws -> WarrantyInfo {
        // Return default warranty information for now
        return WarrantyInfo(
            warrantyMonths: 12,
            returnDays: 30,
            conditions: "Standard manufacturer warranty"
        )
    }
    
    // MARK: - Parse Receipt Information
    
    func parseReceiptText(_ text: String) async throws -> ReceiptInfo {
        // Return default receipt information for now
        return ReceiptInfo(
            storeName: "Unknown Store",
            items: [ReceiptItem(name: "Unknown Item", price: 0.0)],
            purchaseDate: Date().formatted(),
            totalAmount: 0.0,
            warrantyInfo: nil
        )
    }
}

// MARK: - Data Models

struct WarrantyInfo: Codable {
    let warrantyMonths: Int
    let returnDays: Int
    let conditions: String
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
