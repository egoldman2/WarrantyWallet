//
//  ActionViewController.swift
//  WarrantyWalletActionExtension
//
//  Created by Ethan on 22/10/2025.
//

import UIKit
import MobileCoreServices
import UniformTypeIdentifiers

class ActionViewController: UIViewController {
    
    @IBOutlet weak var containerView: UIView!
    
    private var sharedImage: UIImage?
    private var processingTimeout: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("ActionViewController: viewDidLoad called")
        
        // Test App Groups immediately
        let sharedDefaults = UserDefaults(suiteName: "group.com.warrantywallet.shared")
        if sharedDefaults == nil {
            print("ActionViewController: ERROR - App Groups not configured! sharedDefaults is nil")
            showErrorAndDismiss("App Groups not configured")
            return
        } else {
            print("ActionViewController: App Groups working")
        }
        
        // Set up timeout to prevent hanging
        processingTimeout = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { [weak self] _ in
            print("ActionViewController: Processing timeout")
            self?.showErrorAndDismiss("Processing timeout - please try again")
        }
        
        processSharedContent()
    }
    
    deinit {
        processingTimeout?.invalidate()
    }
    
    private func processSharedContent() {
        print("ActionViewController: processSharedContent called")
        
        guard let inputItems = extensionContext?.inputItems as? [NSExtensionItem] else {
            print("ActionViewController: No input items found")
            showErrorAndDismiss("No input items found")
            return
        }
        
        print("ActionViewController: Found \(inputItems.count) input items")
        
        var imageFound = false
        for inputItem in inputItems {
            guard let attachments = inputItem.attachments else { continue }
            
            for attachment in attachments {
                // Check for various image type identifiers
                let imageTypes = [
                    UTType.image.identifier,
                    "public.image",
                    "public.jpeg",
                    "public.png",
                    "public.heic"
                ]
                
                for imageType in imageTypes {
                    if attachment.hasItemConformingToTypeIdentifier(imageType) {
                        attachment.loadItem(forTypeIdentifier: imageType, options: nil) { [weak self] (item, error) in
                            DispatchQueue.main.async {
                                if let error = error {
                                    print("Error loading item: \(error)")
                                    self?.showErrorAndDismiss("Failed to load image: \(error.localizedDescription)")
                                    return
                                }
                                
                                if let image = item as? UIImage {
                                    self?.sharedImage = image
                                    self?.saveImageAndOpenApp()
                                } else if let imageURL = item as? URL {
                                    if let imageData = try? Data(contentsOf: imageURL),
                                       let image = UIImage(data: imageData) {
                                        self?.sharedImage = image
                                        self?.saveImageAndOpenApp()
                                    } else {
                                        self?.showErrorAndDismiss("Failed to load image from URL")
                                    }
                                } else if let imageData = item as? Data {
                                    if let image = UIImage(data: imageData) {
                                        self?.sharedImage = image
                                        self?.saveImageAndOpenApp()
                                    } else {
                                        self?.showErrorAndDismiss("Failed to create image from data")
                                    }
                                } else {
                                    print("Unexpected item type: \(type(of: item))")
                                    self?.showErrorAndDismiss("Unsupported image format")
                                }
                            }
                        }
                        imageFound = true
                        break
                    }
                }
                
                if imageFound {
                    break
                }
            }
            
            if imageFound {
                break
            }
        }
        
        if !imageFound {
            showErrorAndDismiss("No image found in shared content")
        }
    }
    
    private func saveImageAndOpenApp() {
        processingTimeout?.invalidate()
        
        guard let sharedImage = sharedImage else {
            print("ActionViewController: No shared image available")
            showErrorAndDismiss("No image available")
            return
        }
        
        print("ActionViewController: Saving image and opening app")
        
        // Save image to shared container using a simpler approach
        if let imageData = sharedImage.jpegData(compressionQuality: 0.8) {
            print("ActionViewController: Image data size: \(imageData.count) bytes")
            
            // Use UserDefaults with a shared suite
            let sharedDefaults = UserDefaults(suiteName: "group.com.warrantywallet.shared")
            sharedDefaults?.set(imageData, forKey: "shared_image_data")
            sharedDefaults?.set(true, forKey: "has_shared_image")
            sharedDefaults?.synchronize()
            
            print("ActionViewController: Saved image to shared defaults")
            
            // Open the main app with URL scheme
            if let url = URL(string: "warrantywallet://add-item") {
                print("ActionViewController: Opening URL: \(url)")
                var responder = self as UIResponder?
                while responder != nil {
                    if let application = responder as? UIApplication {
                        application.open(url, options: [:]) { success in
                            DispatchQueue.main.async {
                                print("ActionViewController: URL open result: \(success)")
                                if success {
                                    self.extensionContext?.completeRequest(returningItems: nil)
                                } else {
                                    self.showErrorAndDismiss("Could not open WarrantyWallet app")
                                }
                            }
                        }
                        break
                    }
                    responder = responder?.next
                }
            } else {
                print("ActionViewController: Invalid URL scheme")
                showErrorAndDismiss("Invalid URL scheme")
            }
        } else {
            print("ActionViewController: Failed to create image data")
            showErrorAndDismiss("Failed to process image")
        }
    }
    
    private func showErrorAndDismiss(_ message: String) {
        processingTimeout?.invalidate()
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            self.extensionContext?.completeRequest(returningItems: nil)
        })
        present(alert, animated: true)
    }

    @IBAction func done() {
        extensionContext?.completeRequest(returningItems: nil)
    }
}