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
            return "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"
        }
    }()
    
    // MARK: - Brave Search Configuration
    static let braveSearchAPIKey: String = {
        if let key = ProcessInfo.processInfo.environment["BRAVE_SEARCH_API_KEY"] {
            print("Brave Search API key detected.")
            return key
        } else {
            print("⚠️ Warning: BRAVE_SEARCH_API_KEY not set in environment.")
            return "BSAlpNEQgvp6OadSKOR-DfRWYUk4X8Z"
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
    
    static var isBraveSearchKeyConfigured: Bool {
        return !braveSearchAPIKey.isEmpty
    }
}
