//
//  Untitled.swift
//  WarrantyWallet
//
//  Created by Ethan on 22/10/2025.
//

import SwiftUI
import CoreData

struct EditWarrantyItemView: View {
    @ObservedObject var item: WarrantyItem
    let warrantyService: WarrantyService
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var itemName: String = ""
    @State private var storeName: String = ""
    @State private var price: String = ""
    @State private var purchaseDate: Date = Date()
    @State private var warrantyLengthMonths: Int = Config.defaultWarrantyMonths
    @State private var returnWindowDays: Int = Config.defaultReturnDays
    @State private var warrantyConditions: String = ""
    @State private var returnConditions: String = ""
    @State private var warrantyEvidenceUrl: String = ""
    @State private var returnEvidenceUrl: String = ""
    
    @State private var isProcessingReturn = false
    @State private var errorMessage = ""
    @State private var showingError = false
    @State private var showingEditDetails = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
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
            .navigationTitle("Edit Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .fontWeight(.semibold)
                }
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
            .onAppear {
                loadItemData()
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
                    isAIPopulated: false
                )
                
                CustomTextField(
                    icon: "storefront.fill",
                    placeholder: "Store Name",
                    text: $storeName,
                    isAIPopulated: false
                )
                
                CustomTextField(
                    icon: "dollarsign.circle.fill",
                    placeholder: "Price",
                    text: $price,
                    keyboardType: .decimalPad,
                    isAIPopulated: false
                )
                
                HStack(spacing: 12) {
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
                            HStack {
                                Text("\(warrantyLengthMonths) months")
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                            }
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
                            HStack {
                                Text("\(returnWindowDays) days")
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                            }
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
        Button(action: saveChanges) {
            Text("Save Changes")
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(itemName.isEmpty ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
        }
        .disabled(itemName.isEmpty)
        .padding(.top, 8)
    }
    
    // MARK: - Helper Functions
    
    private func loadItemData() {
        itemName = item.itemName ?? ""
        storeName = item.storeName ?? ""
        price = String(format: "%.2f", item.price)
        purchaseDate = item.purchaseDate ?? Date()
        warrantyLengthMonths = Int(item.warrantyLengthMonths)
        returnWindowDays = Int(item.returnWindowDays)
        warrantyConditions = item.warrantyConditions ?? ""
        returnConditions = item.returnConditions ?? ""
        warrantyEvidenceUrl = item.warrantyEvidenceUrl ?? ""
        returnEvidenceUrl = item.returnEvidenceUrl ?? ""
    }
    
    private func findReturn() {
        isProcessingReturn = true
        
        Task {
            do {
                let returnInfo = try await warrantyService.findReturnInfo(for: storeName, itemName: itemName)
                let warrantyInfo = try await warrantyService.findWarrantyInfo(for: itemName, storeName: storeName)
                
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
    
    private func saveChanges() {
        guard !itemName.isEmpty else { return }
        
        let priceValue = Double(price) ?? 0.0
        
        // Update the item
        item.itemName = itemName
        item.storeName = storeName.isEmpty ? nil : storeName
        item.price = priceValue
        item.purchaseDate = purchaseDate
        item.warrantyLengthMonths = Int16(warrantyLengthMonths)
        item.returnWindowDays = Int16(returnWindowDays)
        item.warrantyConditions = warrantyConditions.isEmpty ? nil : warrantyConditions
        item.warrantyEvidenceUrl = warrantyEvidenceUrl.isEmpty ? nil : warrantyEvidenceUrl
        item.returnConditions = returnConditions.isEmpty ? nil : returnConditions
        item.returnEvidenceUrl = returnEvidenceUrl.isEmpty ? nil : returnEvidenceUrl
        item.updatedAt = Date()
        
        // Recalculate dates
        item.warrantyEndDate = Calendar.current.date(byAdding: .month, value: warrantyLengthMonths, to: purchaseDate) ?? purchaseDate
        item.returnEndDate = Calendar.current.date(byAdding: .day, value: returnWindowDays, to: purchaseDate) ?? purchaseDate
        
        // Save to Core Data
        do {
            try viewContext.save()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let item = WarrantyItem(context: context)
    item.itemName = "iPhone 15 Pro"
    item.storeName = "Apple Store"
    item.price = 999.99
    item.purchaseDate = Date()
    item.warrantyLengthMonths = 12
    item.returnWindowDays = 14
    item.warrantyConditions = "Limited warranty"
    item.warrantyEvidenceUrl = "https://apple.com/warranty"
    
    return NavigationView {
        EditWarrantyItemView(
            item: item,
            warrantyService: WarrantyService(context: context)
        )
    }
}
