//
//  OCRService.swift
//  WarrantyWallet
//
//  Created by Ethan on 20/10/2025.
//

import Foundation
import Vision
import UIKit
import Combine

class OCRService: ObservableObject {
    
    @Published var isProcessing = false
    @Published var lastExtractedText = ""
    
    // MARK: - Text Extraction from Images using Vision Framework
    
    func extractTextFromImage(_ imageData: Data) async throws -> String {
        print("🔍 OCRService: Starting text extraction from image data")
        print("📊 OCRService: Image data size: \(imageData.count) bytes")
        
        await MainActor.run {
            isProcessing = true
        }
        print("⏳ OCRService: Processing state set to true")
        
        defer {
            Task { @MainActor in
                isProcessing = false
            }
        }
        
        guard let image = UIImage(data: imageData),
              let cgImage = image.cgImage else {
            print("❌ OCRService: Failed to create UIImage or CGImage from data")
            throw OCRError.invalidImageData
        }
        print("✅ OCRService: Successfully created CGImage from data")
        
        let extractedText = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            print("🔧 OCRService: Creating VNRecognizeTextRequest")
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    print("❌ OCRService: Vision framework error: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    print("❌ OCRService: No text observations found in image")
                    continuation.resume(throwing: OCRError.noTextFound)
                    return
                }
                
                print("📝 OCRService: Found \(observations.count) text observations")
                let extractedText = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }.joined(separator: "\n")
                
                print("📄 OCRService: Extracted text length: \(extractedText.count) characters")
                print("📄 OCRService: Extracted text preview: \(String(extractedText.prefix(100)))...")
                continuation.resume(returning: extractedText)
            }
            
            // Configure for accurate text recognition
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["en"]
            request.usesLanguageCorrection = true
            print("⚙️ OCRService: Configured request with accurate recognition level")
            
            let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                print("🚀 OCRService: Performing text recognition request")
                try requestHandler.perform([request])
                print("✅ OCRService: Text recognition request completed successfully")
            } catch {
                print("❌ OCRService: Failed to perform text recognition: \(error.localizedDescription)")
                continuation.resume(throwing: error)
            }
        }
        
        print("📝 OCRService: Final extracted text: \(extractedText)")
        await MainActor.run {
            lastExtractedText = extractedText
        }
        print("✅ OCRService: Text extraction completed successfully")
        
        return extractedText
    }
    
    // MARK: - Alternative method using UIImage directly
    
    func extractTextFromImage(_ image: UIImage) async throws -> String {
        await MainActor.run {
            isProcessing = true
        }
        
        defer {
            Task { @MainActor in
                isProcessing = false
            }
        }
        
        guard let cgImage = image.cgImage else {
            throw OCRError.invalidImageData
        }
        
        let extractedText = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(throwing: OCRError.noTextFound)
                    return
                }
                
                let extractedText = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }.joined(separator: "\n")
                
                continuation.resume(returning: extractedText)
            }
            
            // Configure for accurate text recognition
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["en"]
            request.usesLanguageCorrection = true
            print("⚙️ OCRService: Configured request with accurate recognition level")
            
            let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                print("🚀 OCRService: Performing text recognition request")
                try requestHandler.perform([request])
                print("✅ OCRService: Text recognition request completed successfully")
            } catch {
                print("❌ OCRService: Failed to perform text recognition: \(error.localizedDescription)")
                continuation.resume(throwing: error)
            }
        }
        
        print("📝 OCRService: Final extracted text: \(extractedText)")
        await MainActor.run {
            lastExtractedText = extractedText
        }
        print("✅ OCRService: Text extraction completed successfully")
        
        return extractedText
    }
}

// MARK: - OCR Errors

enum OCRError: Error, LocalizedError {
    case invalidImageData
    case noTextFound
    case visionFrameworkError
    
    var errorDescription: String? {
        switch self {
        case .invalidImageData:
            return "Invalid image data provided"
        case .noTextFound:
            return "No text found in the image"
        case .visionFrameworkError:
            return "Vision framework error occurred"
        }
    }
}
