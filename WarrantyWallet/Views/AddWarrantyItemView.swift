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
            ScrollView {
                VStack(spacing: 24) {
                    // Receipt Section
                    receiptSection
                    
                    // Item Information Section
                    itemInformationSection
                    
                    // Warranty & Return Section
                    warrantyReturnSection
                    
                    // Save Button
                    saveButton
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
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
    
    // MARK: - Receipt Section
    
    private var receiptSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Receipt")
                    .font(.title3)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            if selectedImage != nil {
                VStack(spacing: 16) {
                    // Receipt Image
                    if let image = selectedImage {
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 250)
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                            
                            Button(action: {
                                withAnimation {
                                    self.selectedImage = nil
                                    self.aiPopulatedFields.removeAll()
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .background(Circle().fill(Color.black.opacity(0.6)))
                            }
                            .padding(8)
                        }
                    }
                    
                    // Extract Button
                    Button(action: processReceipt) {
                        HStack(spacing: 8) {
                            if isProcessing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.9)
                            } else {
                                Image(systemName: "sparkles")
                            }
                            Text(isProcessing ? "Extracting..." : "Extract with AI")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isProcessing ? Color.blue.opacity(0.6) : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isProcessing)
                    
                    if !aiPopulatedFields.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                            Text("Information extracted successfully")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(16)
            } else {
                // Empty State
                VStack(spacing: 20) {
                    Image(systemName: "doc.text.image")
                        .font(.system(size: 56))
                        .foregroundColor(.blue.opacity(0.6))
                        .padding(.top, 20)
                    
                    VStack(spacing: 8) {
                        Text("Add a Receipt")
                            .font(.headline)
                        Text("Take a photo or choose from library")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    HStack(spacing: 12) {
                        Button(action: checkCameraPermission) {
                            VStack(spacing: 8) {
                                Image(systemName: "camera.fill")
                                    .font(.title2)
                                Text("Camera")
                                    .font(.subheadline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(12)
                        }
                        
                        Button(action: { showingImagePicker = true }) {
                            VStack(spacing: 8) {
                                Image(systemName: "photo.fill")
                                    .font(.title2)
                                Text("Library")
                                    .font(.subheadline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.bottom, 20)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(16)
            }
        }
    }
    
    // MARK: - Item Information Section
    
    private var itemInformationSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Item Details")
                    .font(.title3)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            VStack(spacing: 16) {
                CustomTextField(
                    icon: "tag.fill",
                    placeholder: "Item Name",
                    text: $itemName,
                    isAIPopulated: aiPopulatedFields.contains("itemName")
                )
                
                CustomTextField(
                    icon: "storefront.fill",
                    placeholder: "Store Name",
                    text: $storeName,
                    isAIPopulated: aiPopulatedFields.contains("storeName")
                )
                
                CustomTextField(
                    icon: "dollarsign.circle.fill",
                    placeholder: "Price",
                    text: $price,
                    keyboardType: .decimalPad,
                    isAIPopulated: aiPopulatedFields.contains("price")
                )
                
                HStack(spacing: 12) {
                    if aiPopulatedFields.contains("purchaseDate") {
                        Image(systemName: "sparkles")
                            .foregroundColor(.blue)
                            .font(.body)
                    }
                    Image(systemName: "calendar")
                        .foregroundColor(.blue)
                        .font(.body)
                    DatePicker("Purchase Date", selection: $purchaseDate, displayedComponents: .date)
                        .labelsHidden()
                    Spacer()
                }
                .padding()
                .background(Color(.tertiarySystemGroupedBackground))
                .cornerRadius(12)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(16)
        }
    }
    
    // MARK: - Warranty & Return Section
    
    private var warrantyReturnSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Warranty & Returns")
                    .font(.title3)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            VStack(spacing: 12) {
                Button(action: { showingEditDetails = true }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Warranty Period")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("\(warrantyLengthMonths) months")
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                    }
                    .padding()
                    .background(Color(.tertiarySystemGroupedBackground))
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
                
                Button(action: { showingEditDetails = true }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Return Window")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("\(returnWindowDays) days")
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                    }
                    .padding()
                    .background(Color(.tertiarySystemGroupedBackground))
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
                
                if !itemName.isEmpty && !storeName.isEmpty {
                    Button(action: findReturn) {
                        HStack(spacing: 8) {
                            if isProcessingReturn {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.9)
                            } else {
                                Image(systemName: "magnifyingglass")
                            }
                            Text(isProcessingReturn ? "Searching..." : "Find Policy Online")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isProcessingReturn ? Color.green.opacity(0.6) : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isProcessingReturn)
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(16)
        }
    }
    
    // MARK: - Save Button
    
    private var saveButton: some View {
        Button(action: saveItem) {
            Text("Save Item")
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(itemName.isEmpty ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
        }
        .disabled(itemName.isEmpty || isProcessing)
        .padding(.top, 8)
    }
    
    // MARK: - Helper Functions
    
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
                    var populatedFields: Set<String> = []
                    
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
                    isProcessingReturn = false
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

// MARK: - Custom TextField Component

struct CustomTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    let isAIPopulated: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            if isAIPopulated {
                Image(systemName: "sparkles")
                    .foregroundColor(.blue)
                    .font(.body)
            }
            Image(systemName: icon)
                .foregroundColor(.blue)
                .font(.body)
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
        }
        .padding()
        .background(Color(.tertiarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

// MARK: - Image Picker

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
