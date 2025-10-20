//
//  AddWarrantyItemView.swift
//  WarrantyWallet
//
//  Created by Ethan on 19/10/2025.
//

import SwiftUI
import PhotosUI
import CoreData
import AVFoundation

struct AddWarrantyItemView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var warrantyService: WarrantyService
    
    @State private var itemName = ""
    @State private var storeName = ""
    @State private var price = ""
    @State private var purchaseDate = Date()
    @State private var warrantyLengthMonths = Config.defaultWarrantyMonths
    @State private var returnWindowDays = Config.defaultReturnDays
    @State private var warrantyConditions = "Standard warranty terms apply"
    @State private var returnConditions = "Standard return policy applies"
    @State private var warrantyEvidenceUrl = ""
    @State private var returnEvidenceUrl = ""
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var isProcessing = false
    @State private var isProcessingReturn = false
    @State private var errorMessage = ""
    @State private var showingError = false
    @State private var cameraPermissionStatus: AVAuthorizationStatus = .notDetermined
    
    // Track which fields were populated by AI
    @State private var aiPopulatedFields: Set<String> = []
    
    // Navigation state for detail views
    @State private var showingWarrantyDetails = false
    @State private var showingReturnDetails = false
    @State private var showingEditDetails = false
    
    init(warrantyService: WarrantyService) {
        _warrantyService = StateObject(wrappedValue: warrantyService)
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Receipt section at the top
                Section {
                    if selectedImage != nil {
                        VStack(spacing: 12) {
                            if let image = selectedImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxHeight: 200)
                                    .cornerRadius(12)
                                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                            }
                            
                            HStack {
                                Button(role: .destructive) {
                                    self.selectedImage = nil
                                    self.aiPopulatedFields.removeAll()
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "trash")
                                        Text("Remove")
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.regular)
                            }
                            .padding(.top, 4)
                        }
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "receipt")
                                .font(.system(size: 48))
                                .foregroundColor(.gray)
                            
                            Text("Add Receipt Photo")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 12) {
                                Button {
                                    checkCameraPermission()
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "camera")
                                        Text("New Photo")
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.regular)
                                
                                Button {
                                    showingImagePicker = true
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "photo.on.rectangle")
                                        Text("Choose")
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.regular)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        
                    }
                    
                    if selectedImage != nil {
                        Button(action: processReceipt) {
                            HStack {
                                if isProcessing {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "sparkles")
                                        .foregroundColor(.blue)
                                }
                                Text(isProcessing ? "Processing with AI..." : "Extract Information with AI")
                            }
                        }
                        .disabled(isProcessing)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                } header: {
                    Text("Receipt")
                }
                
                // Item Information section
                Section {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            if aiPopulatedFields.contains("itemName") {
                                Image(systemName: "sparkles")
                                    .foregroundColor(.blue)
                                    .font(.caption)
                            }
                            TextField("Item Name", text: $itemName)
                        }
                        
                        HStack {
                            if aiPopulatedFields.contains("storeName") {
                                Image(systemName: "sparkles")
                                    .foregroundColor(.blue)
                                    .font(.caption)
                            }
                            TextField("Store Name", text: $storeName)
                        }
                        
                        HStack {
                            if aiPopulatedFields.contains("price") {
                                Image(systemName: "sparkles")
                                    .foregroundColor(.blue)
                                    .font(.caption)
                            }
                            TextField("Price", text: $price)
                                .keyboardType(.decimalPad)
                        }
                        
                        HStack {
                            if aiPopulatedFields.contains("purchaseDate") {
                                Image(systemName: "sparkles")
                                    .foregroundColor(.blue)
                                    .font(.caption)
                            }
                            DatePicker("Purchase Date", selection: $purchaseDate, displayedComponents: .date)
                        }
                    }
                } header: {
                    Text("Item Information")
                } footer: {
                    if !aiPopulatedFields.isEmpty {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundColor(.blue)
                                .font(.caption)
                            Text("Filled by AI")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Warranty & Return section
                Section {
                    Button {
                        showingEditDetails = true
                    } label: {
                        VStack(spacing: 16) {
                            HStack {
                                if aiPopulatedFields.contains("purchaseDate") {
                                    Image(systemName: "sparkles")
                                        .foregroundColor(.blue)
                                        .font(.caption)
                                }
                                Text("Warranty Period")
                                Spacer()
                                Text("\(warrantyLengthMonths) months")
                                    .foregroundColor(.secondary)
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                            HStack {
                                if aiPopulatedFields.contains("purchaseDate") {
                                    Image(systemName: "sparkles")
                                        .foregroundColor(.blue)
                                        .font(.caption)
                                }
                                Text("Return Period")
                                Spacer()
                                Text("\(returnWindowDays) days")
                                    .foregroundColor(.secondary)
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }

                        }
                    }
                    .buttonStyle(.plain)
                    
                    if !itemName.isEmpty && !storeName.isEmpty {
                        Button {
                            findReturn()
                        } label: {
                            HStack {
                                if isProcessingReturn {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "sparkles")
                                        .foregroundColor(.blue)
                                }
                                Text(isProcessingReturn ? "Processing with AI..." : "Find information using web and AI")
                            }
                        }
                        .disabled(isProcessingReturn)
                    }
                    
                } header: {
                    Text("Warranty and Return")
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
                UnifiedImagePicker(selectedImage: $selectedImage, sourceType: .photoLibrary)
            }
            .fullScreenCover(isPresented: $showingCamera) {
                UnifiedImagePicker(selectedImage: $selectedImage, sourceType: .camera)
                    .ignoresSafeArea()
            }
            .sheet(isPresented: $showingEditDetails) {
                EditWarrantyDetailsView(
                    warrantyLengthMonths: $warrantyLengthMonths,
                    returnWindowDays: $returnWindowDays,
                    warrantyConditions: $warrantyConditions,
                    returnConditions: $returnConditions,
                    warrantyEvidenceUrl: $warrantyEvidenceUrl,
                    returnEvidenceUrl: $returnEvidenceUrl
                )
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func checkCameraPermission() {
        cameraPermissionStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch cameraPermissionStatus {
        case .authorized:
            showingCamera = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        self.showingCamera = true
                    } else {
                        self.errorMessage = "Camera access is required to take photos. Please enable it in Settings."
                        self.showingError = true
                    }
                }
            }
        case .denied, .restricted:
            errorMessage = "Camera access is required to take photos. Please enable it in Settings."
            showingError = true
        @unknown default:
            errorMessage = "Camera access is required to take photos. Please enable it in Settings."
            showingError = true
        }
    }
    
    private func processReceipt() {
        guard let image = selectedImage,
              let imageData = image.jpegData(compressionQuality: 0.8) else {
            return
        }
        
        isProcessing = true
        aiPopulatedFields.removeAll()
        
        Task {
            do {
                let receiptData = try await warrantyService.processReceiptImageForForm(imageData)
                
                await MainActor.run {
                    // Track which fields are being populated by AI
                    var populatedFields: Set<String> = []
                    
                    // Update form fields with extracted data
                    if let itemName = receiptData.itemName, !itemName.isEmpty {
                        self.itemName = itemName
                        populatedFields.insert("itemName")
                    }
                    
                    if let storeName = receiptData.storeName, !storeName.isEmpty {
                        self.storeName = storeName
                        populatedFields.insert("storeName")
                    }
                    
                    if !receiptData.formattedPrice.isEmpty {
                        self.price = receiptData.formattedPrice
                        populatedFields.insert("price")
                    }
                    
                    if let parsedDate = receiptData.parsedDate {
                        self.purchaseDate = parsedDate
                        populatedFields.insert("purchaseDate")
                    }
                    
                    aiPopulatedFields = populatedFields
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
    
    private func findReturn() {
        isProcessingReturn = true
        
        Task {
            do {
                let returnInfo = try await warrantyService.findReturnInfo(for: storeName)
                let warrantyInfo = try await warrantyService.findWarrantyInfo(for: itemName)
                
                await MainActor.run {
                    if let returnDays = returnInfo?.returnDays {
                        self.returnWindowDays = returnDays
                    }
                    
                    if let conditions = returnInfo?.conditions {
                        self.returnConditions = conditions
                    }
                    
                    if let evidenceUrl = returnInfo?.evidenceUrl {
                        self.returnEvidenceUrl = evidenceUrl
                    }
                    
                    if let warrantyMonths = warrantyInfo?.warrantyMonths {
                        self.warrantyLengthMonths = warrantyMonths
                    }
                    
                    if let warrantyConditions = warrantyInfo?.conditions {
                        self.warrantyConditions = warrantyConditions
                    }
                    
                    if let warrantyEvidenceUrl = warrantyInfo?.evidenceUrl {
                        self.warrantyEvidenceUrl = warrantyEvidenceUrl
                    }
                    
                    isProcessingReturn = false
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
                    extractedText: nil,
                    warrantyConditions: warrantyConditions.isEmpty ? nil : warrantyConditions,
                    warrantyEvidenceUrl: warrantyEvidenceUrl.isEmpty ? nil : warrantyEvidenceUrl,
                    returnConditions: returnConditions.isEmpty ? nil : returnConditions,
                    returnEvidenceUrl: returnEvidenceUrl.isEmpty ? nil : returnEvidenceUrl
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

struct UnifiedImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    let sourceType: UIImagePickerController.SourceType
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: UnifiedImagePicker
        
        init(_ parent: UnifiedImagePicker) {
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

