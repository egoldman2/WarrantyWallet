//
//  AddWarrantyItemView.swift
//  WarrantyWallet
//
//  Created by Ethan on 19/10/2025.
//

import SwiftUI
import PhotosUI
import CoreData

struct AddWarrantyItemView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var warrantyService: WarrantyService
    
    @State private var itemName = ""
    @State private var storeName = ""
    @State private var price = ""
    @State private var purchaseDate = Date()
    @State private var warrantyLengthMonths = Config.defaultWarrantyMonths
    @State private var returnWindowDays = Config.defaultReturnDays
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var isProcessing = false
    @State private var errorMessage = ""
    @State private var showingError = false
    
    init(warrantyService: WarrantyService) {
        _warrantyService = StateObject(wrappedValue: warrantyService)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Item Information") {
                    TextField("Item Name", text: $itemName)
                    TextField("Store Name", text: $storeName)
                    TextField("Price", text: $price)
                        .keyboardType(.decimalPad)
                    DatePicker("Purchase Date", selection: $purchaseDate, displayedComponents: .date)
                }
                
                Section("Warranty & Return") {
                    Stepper("Warranty: \(warrantyLengthMonths) months", value: $warrantyLengthMonths, in: 1...60)
                    Stepper("Return Window: \(returnWindowDays) days", value: $returnWindowDays, in: 1...365)
                }
                
                Section("Receipt") {
                    if let selectedImage = selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 200)
                            .cornerRadius(8)
                    }
                    
                    HStack {
                        Button("Take Photo") {
                            showingCamera = true
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Choose from Library") {
                            showingImagePicker = true
                        }
                        .buttonStyle(.bordered)
                        
                        if selectedImage != nil {
                            Button("Remove") {
                                selectedImage = nil
                            }
                            .buttonStyle(.bordered)
                            .foregroundColor(.red)
                        }
                    }
                }
                
                Section {
                    Button(action: processReceipt) {
                        HStack {
                            if isProcessing {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            Text(isProcessing ? "Processing..." : "Process Receipt with AI")
                        }
                    }
                    .disabled(selectedImage == nil || isProcessing)
                }
            }
            .navigationTitle("Add Warranty Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveItem()
                    }
                    .disabled(itemName.isEmpty || isProcessing)
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(selectedImage: $selectedImage)
            }
            .sheet(isPresented: $showingCamera) {
                CameraView(selectedImage: $selectedImage)
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func processReceipt() {
        guard let image = selectedImage,
              let imageData = image.jpegData(compressionQuality: 0.8) else {
            return
        }
        
        isProcessing = true
        
        Task {
            do {
                let warrantyItem = try await warrantyService.processReceiptImage(imageData)
                
                await MainActor.run {
                    // Update form fields with extracted data
                    itemName = warrantyItem.itemName ?? "Default Name"
                    storeName = warrantyItem.storeName ?? "Default Store"
                    price = String(format: "%.2f", warrantyItem.price)
                    purchaseDate = warrantyItem.purchaseDate ?? Date()
                    warrantyLengthMonths = Int(warrantyItem.warrantyLengthMonths)
                    returnWindowDays = Int(warrantyItem.returnWindowDays)
                    isProcessing = false
                }
            } catch {	
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                    isProcessing = false
                }
            }
        }
    }
    
    private func saveItem() {
        guard !itemName.isEmpty else { return }
        
        let priceValue = Double(price) ?? 0.0
        
        Task {
            do {
                _ = try await warrantyService.createWarrantyItem(
                    itemName: itemName,
                    storeName: storeName.isEmpty ? nil : storeName,
                    price: priceValue,
                    purchaseDate: purchaseDate,
                    warrantyLengthMonths: warrantyLengthMonths,
                    returnWindowDays: returnWindowDays,
                    receiptImageData: selectedImage?.jpegData(compressionQuality: 0.8),
                    extractedText: nil
                )
                
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

struct CameraView: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    AddWarrantyItemView(warrantyService: WarrantyService(context: PersistenceController.preview.container.viewContext))
}
