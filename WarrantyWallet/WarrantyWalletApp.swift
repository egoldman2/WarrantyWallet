//
//  WarrantyWalletApp.swift
//  WarrantyWallet
//
//  Created by Ethan on 20/10/2025.
//

import SwiftUI
import CoreData

@main
struct WarrantyWalletApp: App {
    let persistenceController = PersistenceController.shared
    @State private var sharedImage: UIImage?
    @State private var showingAddItem = false
    @State private var shouldShowAddItem = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            if shouldShowAddItem, let sharedImage = sharedImage {
                NavigationView {
                    AddWarrantyItemView(
                        warrantyService: WarrantyService(context: persistenceController.container.viewContext),
                        preloadedImage: sharedImage,
                        onDismiss: {
                            // Reset the state when AddWarrantyItemView is dismissed
                            shouldShowAddItem = false
                            self.sharedImage = nil
                        }
                    )
                }
            } else {
                ContentView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .onOpenURL { url in
                        print("WarrantyWalletApp: URL opened - \(url)")
                        handleURL(url)
                    }
                    .onAppear {
                        print("WarrantyWalletApp: ContentView appeared")
                        checkForSharedImage()
                    }
                    .sheet(isPresented: $showingAddItem) {
                        if let sharedImage = sharedImage {
                            AddWarrantyItemView(
                                warrantyService: WarrantyService(context: persistenceController.container.viewContext),
                                preloadedImage: sharedImage
                            )
                        }
                    }
            }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                print("WarrantyWalletApp: App became active")
                checkForSharedImage()
            }
        }
    }
    
    private func handleURL(_ url: URL) {
        if url.scheme == "warrantywallet" && url.host == "add-item" {
            checkForSharedImage()
        }
    }
    
    private func checkForSharedImage() {
        print("WarrantyWalletApp: checkForSharedImage called")
        let sharedDefaults = UserDefaults(suiteName: "group.com.warrantywallet.shared")
        
        // Debug: Check if App Groups are working
        if sharedDefaults == nil {
            print("WarrantyWalletApp: ERROR - App Groups not configured! sharedDefaults is nil")
            return
        }
        
        print("WarrantyWalletApp: App Groups working, checking for shared image...")
        
        // Debug: List all keys in shared defaults
        let allKeys: [String] = sharedDefaults?.dictionaryRepresentation().keys.map { String($0) } ?? []
        print("WarrantyWalletApp: All keys in shared defaults: \(Array(allKeys))")
        
        if let hasSharedImage = sharedDefaults?.bool(forKey: "has_shared_image"), hasSharedImage {
            print("WarrantyWalletApp: Found has_shared_image = true")
            if let imageData = sharedDefaults?.data(forKey: "shared_image_data") {
                print("WarrantyWalletApp: Found image data, size: \(imageData.count) bytes")
                if let image = UIImage(data: imageData) {
                    print("WarrantyWalletApp: Successfully created UIImage")
                    sharedImage = image
                    shouldShowAddItem = true
                    print("WarrantyWalletApp: Set shouldShowAddItem = true")
                    
                    // Clean up the shared data
                    sharedDefaults?.removeObject(forKey: "shared_image_data")
                    sharedDefaults?.removeObject(forKey: "has_shared_image")
                    sharedDefaults?.synchronize()
                    print("WarrantyWalletApp: Cleaned up shared data")
                } else {
                    print("WarrantyWalletApp: Failed to create UIImage from data")
                }
            } else {
                print("WarrantyWalletApp: No image data found")
            }
        } else {
            print("WarrantyWalletApp: No shared image found")
        }
    }
}

