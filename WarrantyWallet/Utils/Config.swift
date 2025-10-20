//
//  Config.swift
//  WarrantyWallet
//
//  Created by Ethan on 19/10/2025.
//

import Foundation

struct Config {
    // MARK: - OpenAI Configuration
    static let openAIAPIKey: String = {
        
        // Yes, I know the API key is not supposed to be stored in plain text in the code, but this is the easiest way to demonstrate the app for you (the tutor)
        if let key = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] {
            print("API key detected.")
            return key
        } else {
            print("⚠️ Warning: OPENAI_API_KEY not set in environment.")
            return ""
        }
    }()
    
    // MARK: - App Configuration
    
    static let appName = "Warranty Wallet"
    static let appVersion = "1.0.0"
    
    // MARK: - Default Values
    
    static let defaultWarrantyMonths = 12
    static let defaultReturnDays = 30
    static let warrantyExpiringSoonDays = 30
    static let returnExpiringSoonDays = 7
    
    // MARK: - Validation
    
    static var isOpenAIKeyConfigured: Bool {
        return !openAIAPIKey.isEmpty
    }
}
