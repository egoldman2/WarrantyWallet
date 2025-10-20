//
//  WarrantyItemDetailView.swift
//  WarrantyWallet
//
//  Created by Ethan on 19/10/2025.
//

import SwiftUI
import PDFKit
import CoreData

struct WarrantyItemDetailView: View {
    let item: WarrantyItem
    let warrantyService: WarrantyService
    
    @State private var showingWarrantyCard = false
    @State private var warrantyCardText = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(item.itemName ?? "Default Item Name")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    if let storeName = item.storeName {
                        Text(storeName)
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    
                    if item.price > 0 {
                        Text("$\(String(format: "%.2f", item.price))")
                            .font(.title3)
                            .fontWeight(.medium)
                    }
                }
                .padding(.bottom)
                
                // Status Cards
                HStack(spacing: 16) {
                    StatusCard(
                        title: "Warranty",
                        status: warrantyService.getWarrantyStatus(for: item),
                        endDate: item.warrantyEndDate
                    )
                    
                    StatusCard(
                        title: "Return",
                        status: warrantyService.getReturnStatus(for: item),
                        endDate: item.returnEndDate
                    )
                }
                
                // Purchase Information
                InfoSection(title: "Purchase Information") {
                    InfoRow(label: "Purchase Date", value: formatDate(item.purchaseDate ?? Date()))
                    InfoRow(label: "Warranty Period", value: "\(item.warrantyLengthMonths) months")
                    InfoRow(label: "Return Window", value: "\(item.returnWindowDays) days")
                }
                
                // Dates
                InfoSection(title: "Important Dates") {
                    if let warrantyEndDate = item.warrantyEndDate {
                        InfoRow(label: "Warranty Expires", value: formatDate(warrantyEndDate))
                    }
                    if let returnEndDate = item.returnEndDate {
                        InfoRow(label: "Return Deadline", value: formatDate(returnEndDate))
                    }
                }
                
                // Receipt Image
                if let imageData = item.receiptImageData,
                   let uiImage = UIImage(data: imageData) {
                    InfoSection(title: "Receipt") {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 300)
                            .cornerRadius(8)
                    }
                }
                
                // Extracted Text
                if let extractedText = item.extractedText {
                    InfoSection(title: "Extracted Text") {
                        Text(extractedText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                }
                
                // Actions
                VStack(spacing: 12) {
                    Button(action: generateWarrantyCard) {
                        HStack {
                            Image(systemName: "doc.text")
                            Text("Generate Warranty Card")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    
                    Button(action: shareWarrantyCard) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share Warranty Card")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
                .padding(.top)
            }
            .padding()
        }
        .navigationTitle("Warranty Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingWarrantyCard) {
            WarrantyCardView(text: warrantyCardText)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func generateWarrantyCard() {
        warrantyCardText = warrantyService.generateWarrantyCard(for: item)
        showingWarrantyCard = true
    }
    
    private func shareWarrantyCard() {
        let warrantyCard = warrantyService.generateWarrantyCard(for: item)
        let activityVC = UIActivityViewController(activityItems: [warrantyCard], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
}

struct StatusCard: View {
    let title: String
    let status: any StatusProtocol
    let endDate: Date?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text(status.displayName)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color(status.color))
            
            if let endDate = endDate {
                Text("Expires: \(endDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct InfoSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            content
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

struct WarrantyCardView: View {
    let text: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                Text(text)
                    .font(.system(.body, design: .monospaced))
                    .padding()
            }
            .navigationTitle("Warranty Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

protocol StatusProtocol {
    var displayName: String { get }
    var color: String { get }
}

extension WarrantyStatus: StatusProtocol {}
extension ReturnStatus: StatusProtocol {}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let warrantyService = WarrantyService(context: context)
    
    // Create a sample warranty item for preview
    let sampleItem = WarrantyItem(context: context)
    sampleItem.itemName = "iPhone 15 Pro"
    sampleItem.storeName = "Apple Store"
    sampleItem.price = 999.00
    sampleItem.purchaseDate = Date()
    sampleItem.warrantyLengthMonths = 12
    sampleItem.returnWindowDays = 14
    
    return WarrantyItemDetailView(item: sampleItem, warrantyService: warrantyService)
        .environment(\.managedObjectContext, context)
}
