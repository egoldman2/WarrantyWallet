//
//  WarrantyService.swift
//  WarrantyWallet
//
//  Created by Ethan on 19/10/2025.
//

import Foundation
import CoreData
import Combine

class WarrantyService: ObservableObject {
    
    private let context: NSManagedObjectContext
    private let openAIService: OpenAIService
    
    init(context: NSManagedObjectContext) {
        self.context = context
        self.openAIService = OpenAIService()
    }
    
    // MARK: - Create Warranty Item
    
    func createWarrantyItem(
        itemName: String,
        storeName: String?,
        price: Double,
        purchaseDate: Date,
        warrantyLengthMonths: Int,
        returnWindowDays: Int,
        receiptImageData: Data?,
        extractedText: String?,
        warrantyConditions: String? = nil,
        warrantyEvidenceUrl: String? = nil,
        returnConditions: String? = nil,
        returnEvidenceUrl: String? = nil
    ) async throws -> WarrantyItem {
        
        let warrantyItem = WarrantyItem(context: context)
        warrantyItem.id = UUID()
        warrantyItem.itemName = itemName
        warrantyItem.storeName = storeName
        warrantyItem.price = price
        warrantyItem.purchaseDate = purchaseDate
        warrantyItem.warrantyLengthMonths = Int16(warrantyLengthMonths)
        warrantyItem.returnWindowDays = Int16(returnWindowDays)
        warrantyItem.receiptImageData = receiptImageData
        warrantyItem.extractedText = extractedText
        warrantyItem.warrantyConditions = warrantyConditions
        warrantyItem.warrantyEvidenceUrl = warrantyEvidenceUrl
        warrantyItem.returnConditions = returnConditions
        warrantyItem.returnEvidenceUrl = returnEvidenceUrl
        warrantyItem.createdAt = Date()
        warrantyItem.updatedAt = Date()
        
        // Calculate warranty and return end dates≥
        warrantyItem.warrantyEndDate = calculateWarrantyEndDate(from: purchaseDate, months: warrantyLengthMonths)
        warrantyItem.returnEndDate = calculateReturnEndDate(from: purchaseDate, days: returnWindowDays)
        
        try context.save()
        return warrantyItem
    }
    
    // MARK: - Process Receipt Image
    
    func processReceiptImage(_ imageData: Data) async throws -> WarrantyItem {
        // Extract structured data from image using the new method
        let receiptData = try await openAIService.extractReceiptData(imageData)
        
        // Use default warranty information since lookupWarrantyInformation was removed
        let warrantyLengthMonths = Config.defaultWarrantyMonths
        let returnWindowDays = Config.defaultReturnDays
        
        // Parse purchase date
        let purchaseDate = receiptData.parsedDate ?? Date()
        
        // Create warranty item
        return try await createWarrantyItem(
            itemName: receiptData.itemName ?? "Unknown Item",
            storeName: receiptData.storeName,
            price: receiptData.price ?? 0.0,
            purchaseDate: purchaseDate,
            warrantyLengthMonths: warrantyLengthMonths,
            returnWindowDays: returnWindowDays,
            receiptImageData: imageData,
            extractedText: nil
        )
    }
    
    // MARK: - Process Receipt Image for Form Population
    
    func processReceiptImageForForm(_ imageData: Data) async throws -> ReceiptData {
        // Extract structured data from image using the new method
        return try await openAIService.extractReceiptData(imageData)
    }
    
    // MARK: - Date Calculations
    
    private func calculateWarrantyEndDate(from purchaseDate: Date, months: Int) -> Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: .month, value: months, to: purchaseDate) ?? purchaseDate
    }
    
    private func calculateReturnEndDate(from purchaseDate: Date, days: Int) -> Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: .day, value: days, to: purchaseDate) ?? purchaseDate
    }
    
    // MARK: - Warranty Status
    
    func getWarrantyStatus(for item: WarrantyItem) -> WarrantyStatus {
        let now = Date()
        
        if let warrantyEndDate = item.warrantyEndDate {
            if now > warrantyEndDate {
                return .expired
            } else {
                let daysRemaining = Calendar.current.dateComponents([.day], from: now, to: warrantyEndDate).day ?? 0
                if daysRemaining <= Config.warrantyExpiringSoonDays {
                    return .expiringSoon
                } else {
                    return .active
                }
            }
        }
        
        return .unknown
    }
    
    func getReturnStatus(for item: WarrantyItem) -> ReturnStatus {
        let now = Date()
        
        if let returnEndDate = item.returnEndDate {
            if now > returnEndDate {
                return .expired
            } else {
                let daysRemaining = Calendar.current.dateComponents([.day], from: now, to: returnEndDate).day ?? 0
                if daysRemaining <= Config.returnExpiringSoonDays {
                    return .expiringSoon
                } else {
                    return .active
                }
            }
        }
        
        return .unknown
    }
    
    // MARK: - Search and find warranty info
    func findWarrantyInfo(for itemName: String, storeName: String = "") async throws -> WarrantyInfo? {
        return try await openAIService.processWarrantyInfo(itemName)
    }
    
    // MARK: - Search and find return info
    func findReturnInfo(for storeName: String, itemName: String = "") async throws -> ReturnPolicyInfo? {
        return try await openAIService.processReturnPolicyInfo(storeName)
    }
    
    // MARK: - Export Warranty Card
    
    func generateWarrantyCard(for item: WarrantyItem) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        let warrantyStatus = getWarrantyStatus(for: item)
        let returnStatus = getReturnStatus(for: item)
        
        return """
        WARRANTY CARD
        
        Item: \(item.itemName ?? "N/A")
        Store: \(item.storeName ?? "N/A")
        Price: $\(String(format: "%.2f", item.price))
        Purchase Date: \(formatter.string(from: item.purchaseDate ?? Date()))
        
        Warranty Information:
        - Warranty Period: \(item.warrantyLengthMonths) months
        - Warranty End Date: \(item.warrantyEndDate != nil ? formatter.string(from: item.warrantyEndDate!) : "N/A")
        - Warranty Status: \(warrantyStatus.displayName)
        - Warranty Conditions: \(item.warrantyConditions ?? "Not specified")
        - Warranty Evidence: \(item.warrantyEvidenceUrl ?? "Not available")
        
        Return Information:
        - Return Window: \(item.returnWindowDays) days
        - Return End Date: \(item.returnEndDate != nil ? formatter.string(from: item.returnEndDate!) : "N/A")
        - Return Status: \(returnStatus.displayName)
        - Return Conditions: \(item.returnConditions ?? "Not specified")
        - Return Evidence: \(item.returnEvidenceUrl ?? "Not available")
        
        Generated on: \(formatter.string(from: Date()))
        """
    }
}

// MARK: - Status Enums

enum WarrantyStatus {
    case active
    case expiringSoon
    case expired
    case unknown
    
    var displayName: String {
        switch self {
        case .active:
            return "Active"
        case .expiringSoon:
            return "Expiring Soon"
        case .expired:
            return "Expired"
        case .unknown:
            return "Unknown"
        }
    }
    
    var color: String {
        switch self {
        case .active:
            return "green"
        case .expiringSoon:
            return "orange"
        case .expired:
            return "red"
        case .unknown:
            return "gray"
        }
    }
}

enum ReturnStatus {
    case active
    case expiringSoon
    case expired
    case unknown
    
    var displayName: String {
        switch self {
        case .active:
            return "Active"
        case .expiringSoon:
            return "Expiring Soon"
        case .expired:
            return "Expired"
        case .unknown:
            return "Unknown"
        }
    }
    
    var color: String {
        switch self {
        case .active:
            return "green"
        case .expiringSoon:
            return "orange"
        case .expired:
            return "red"
        case .unknown:
            return "gray"
        }
    }
}
