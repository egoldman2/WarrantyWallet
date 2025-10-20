//
//  Config.swift
//  WarrantyWallet
//
//  Created by Ethan on 19/10/2025.
//

import Foundation

// Try to import Secrets.swift if present; fall back to empty values when missing
// Secrets.swift should define struct Secrets with optional API keys

struct Config {
    // MARK: - OpenAI Configuration
    static let openAIAPIKey: String = {
        if let key = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !key.isEmpty {
            return key
        }
        // If Secrets.swift exists and contains a key, use it
        let secretsKey = (Secrets.openAIAPIKey as String?) ?? ""
        if !secretsKey.isEmpty { return secretsKey }
        print("⚠️ Warning: OPENAI_API_KEY not configured (env or Secrets.swift)")
        return ""
    }()
    
    // MARK: - Brave Search Configuration
    static let braveSearchAPIKey: String = {
        if let key = ProcessInfo.processInfo.environment["BRAVE_SEARCH_API_KEY"], !key.isEmpty {
            return key
        }
        
        let secretsKey = (Secrets.braveSearchAPIKey as String?) ?? ""
        if !secretsKey.isEmpty { return secretsKey }
        
        print("⚠️ Warning: BRAVE_SEARCH_API_KEY not configured (env or Secrets.swift)")
        return ""
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
