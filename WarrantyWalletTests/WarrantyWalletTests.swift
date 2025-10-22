//
//  WarrantyWalletTests.swift
//  WarrantyWalletTests
//
//  Created by Ethan on 20/10/2025.
//

import Testing
import Foundation
@testable import WarrantyWallet

struct WarrantyWalletTests {

    // MARK: - ReceiptData Tests
    
    @Test func testReceiptDataFormattedPrice() {
        let receiptData = ReceiptData(
            itemName: "Test Item",
            storeName: "Test Store",
            price: 29.99,
            purchaseDate: "01-01-2024"
        )
        
        #expect(receiptData.formattedPrice == "29.99")
    }
    
    @Test func testReceiptDataFormattedPriceWithNil() {
        let receiptData = ReceiptData(
            itemName: "Test Item",
            storeName: "Test Store",
            price: nil,
            purchaseDate: "01-01-2024"
        )
        
        #expect(receiptData.formattedPrice == "0.00")
    }
    
    @Test func testReceiptDataParsedDate() {
        let receiptData = ReceiptData(
            itemName: "Test Item",
            storeName: "Test Store",
            price: 29.99,
            purchaseDate: "15-03-2024"
        )
        
        let parsedDate = receiptData.parsedDate
        #expect(parsedDate != nil)
        
        if let date = parsedDate {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.day, .month, .year], from: date)
            #expect(components.day == 15)
            #expect(components.month == 3)
            #expect(components.year == 2024)
        }
    }
    
    @Test func testReceiptDataParsedDateWithNil() {
        let receiptData = ReceiptData(
            itemName: "Test Item",
            storeName: "Test Store",
            price: 29.99,
            purchaseDate: nil
        )
        
        #expect(receiptData.parsedDate == nil)
    }
    
    // MARK: - WarrantyStatus Tests
    
    @Test func testWarrantyStatusDisplayNames() {
        #expect(WarrantyStatus.active.displayName == "Active")
        #expect(WarrantyStatus.expiringSoon.displayName == "Expiring Soon")
        #expect(WarrantyStatus.expired.displayName == "Expired")
        #expect(WarrantyStatus.unknown.displayName == "Unknown")
    }
    
    @Test func testWarrantyStatusColors() {
        #expect(WarrantyStatus.active.color == "green")
        #expect(WarrantyStatus.expiringSoon.color == "orange")
        #expect(WarrantyStatus.expired.color == "red")
        #expect(WarrantyStatus.unknown.color == "gray")
    }
    
    // MARK: - ReturnStatus Tests
    
    @Test func testReturnStatusDisplayNames() {
        #expect(ReturnStatus.active.displayName == "Active")
        #expect(ReturnStatus.expiringSoon.displayName == "Expiring Soon")
        #expect(ReturnStatus.expired.displayName == "Expired")
        #expect(ReturnStatus.unknown.displayName == "Unknown")
    }
    
    @Test func testReturnStatusColors() {
        #expect(ReturnStatus.active.color == "green")
        #expect(ReturnStatus.expiringSoon.color == "orange")
        #expect(ReturnStatus.expired.color == "red")
        #expect(ReturnStatus.unknown.color == "gray")
    }
    
    // MARK: - Config Tests
    
    @Test func testConfigDefaultValues() {
        #expect(Config.defaultWarrantyMonths == 12)
        #expect(Config.defaultReturnDays == 30)
        #expect(Config.warrantyExpiringSoonDays == 30)
        #expect(Config.returnExpiringSoonDays == 7)
    }
    
    @Test func testConfigAppInfo() {
        #expect(Config.appName == "Warranty Wallet")
        #expect(Config.appVersion == "1.0.0")
    }
    
    // MARK: - OCR Error Tests
    
    @Test func testOCRErrorDescriptions() {
        #expect(OCRError.invalidImageData.errorDescription == "Invalid image data provided")
        #expect(OCRError.noTextFound.errorDescription == "No text found in the image")
        #expect(OCRError.visionFrameworkError.errorDescription == "Vision framework error occurred")
    }
    
    // MARK: - Date Calculation Tests
    
    @Test func testDateCalculations() {
        let calendar = Calendar.current
        let testDate = Date()
        
        // Test warranty end date calculation (12 months)
        let warrantyEndDate = calendar.date(byAdding: .month, value: 12, to: testDate)
        #expect(warrantyEndDate != nil)
        
        // Test return end date calculation (30 days)
        let returnEndDate = calendar.date(byAdding: .day, value: 30, to: testDate)
        #expect(returnEndDate != nil)
    }
    
    // MARK: - String Formatting Tests
    
    @Test func testPriceFormatting() {
        let price = 123.456
        let formatted = String(format: "%.2f", price)
        #expect(formatted == "123.46")
    }
    
    @Test func testPriceFormattingWithZero() {
        let price = 0.0
        let formatted = String(format: "%.2f", price)
        #expect(formatted == "0.00")
    }
    
    // MARK: - Simple Validation Tests
    
    @Test func testBasicStringValidation() {
        let validItemName = "iPhone 15 Pro"
        let emptyItemName = ""
        let nilItemName: String? = nil
        
        #expect(!validItemName.isEmpty)
        #expect(emptyItemName.isEmpty)
        #expect(nilItemName?.isEmpty ?? true)
    }
    
    @Test func testNumericValidation() {
        let validPrice = 299.99
        let zeroPrice = 0.0
        let negativePrice = -10.0
        
        #expect(validPrice > 0)
        #expect(zeroPrice == 0)
        #expect(negativePrice < 0)
    }
    
    // MARK: - Date Formatting Tests
    
    @Test func testDateFormatter() {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        
        let testDate = Date()
        let dateString = formatter.string(from: testDate)
        
        #expect(!dateString.isEmpty)
        #expect(dateString.contains("-"))
    }
    
    @Test func testDateParsing() {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        
        let dateString = "15-03-2024"
        let parsedDate = formatter.date(from: dateString)
        
        #expect(parsedDate != nil)
        
        if let date = parsedDate {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.day, .month, .year], from: date)
            #expect(components.day == 15)
            #expect(components.month == 3)
            #expect(components.year == 2024)
        }
    }
}
