//
//  ReceiptData.swift
//  WarrantyWallet
//
//  Created by Ethan on 20/10/2025.
//

import Foundation

struct ReceiptData: Codable {
    let itemName: String?
    let storeName: String?
    let price: Double?
    let purchaseDate: String?
    
    // Helper computed properties for easier use
    var formattedPrice: String {
        guard let price = price else { return "0.00" }
        return String(format: "%.2f", price)
    }
    
    var parsedDate: Date? {
        guard let dateString = purchaseDate else { return nil }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        return formatter.date(from: dateString)
    }
}
