//
//  WarrantyItemDetailView.swift
//  WarrantyWallet
//
//  Created by Ethan on 19/10/2025.
//

import SwiftUI
import CoreData

struct WarrantyItemDetailView: View {
    @ObservedObject var item: WarrantyItem
    let warrantyService: WarrantyService
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingFullImage = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Receipt Image Section
                if let imageData = item.receiptImageData,
                   let uiImage = UIImage(data: imageData) {
                    receiptImageSection(image: uiImage)
                }
                
                // Item Overview Card
                itemOverviewCard
                
                // Warranty Status Card
                warrantyStatusCard
                
                // Return Window Card
                if let returnEndDate = item.returnEndDate {
                    returnStatusCard(returnEndDate: returnEndDate)
                }
                
                // Warranty Details
                warrantyDetailsSection
                
                // Return Policy Details
                returnPolicyDetailsSection
                
                // Additional Information
                additionalInfoSection
                
                // Delete Button
                deleteButton
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(item.itemName ?? "Item Details")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    showingEditSheet = true
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditWarrantyItemView(item: item, warrantyService: warrantyService)
        }
        .fullScreenCover(isPresented: $showingFullImage) {
            if let imageData = item.receiptImageData,
               let uiImage = UIImage(data: imageData) {
                FullScreenImageView(image: uiImage, isPresented: $showingFullImage)
            }
        }
        .alert("Delete Item", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteItem()
            }
        } message: {
            Text("Are you sure you want to delete this warranty item? This action cannot be undone.")
        }
    }
    
    // MARK: - Receipt Image Section
    
    private func receiptImageSection(image: UIImage) -> some View {
        VStack(spacing: 12) {
            Button(action: { showingFullImage = true }) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 250)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            }
            
            HStack {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Tap to view full size")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Item Overview Card
    
    private var itemOverviewCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Purchase Details")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text(item.itemName ?? "Unknown Item")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                Spacer()
            }
            
            Divider()
            
            VStack(spacing: 16) {
                if let storeName = item.storeName, !storeName.isEmpty {
                    InfoRow(
                        icon: "storefront.fill",
                        label: "Store",
                        value: storeName,
                        color: .blue
                    )
                }
                
                if item.price > 0 {
                    InfoRow(
                        icon: "dollarsign.circle.fill",
                        label: "Price",
                        value: "$\(String(format: "%.2f", item.price))",
                        color: .green
                    )
                }
                
                InfoRow(
                    icon: "calendar",
                    label: "Purchase Date",
                    value: item.purchaseDate?.formatted(date: .long, time: .omitted) ?? "Unknown",
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
    
    // MARK: - Warranty Status Card
    
    private var warrantyStatusCard: some View {
        let status = warrantyService.getWarrantyStatus(for: item)
        let daysRemaining = item.warrantyEndDate != nil ? Calendar.current.dateComponents([.day], from: Date(), to: item.warrantyEndDate!).day ?? 0 : 0
        
        return VStack(spacing: 16) {
            HStack {
                Image(systemName: "checkmark.shield.fill")
                    .foregroundColor(Color(status.color))
                    .font(.title2)
                Text("Warranty Status")
                    .font(.headline)
                Spacer()
            }
            
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Status")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(status.displayName)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(status.color))
                    }
                    Spacer()
                    Image(systemName: statusIcon(for: status))
                        .font(.system(size: 40))
                        .foregroundColor(Color(status.color))
                }
                
                if status != .expired && status != .unknown {
                    Divider()
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Time Remaining")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("\(daysRemaining) days")
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                        Spacer()
                    }
                }
                
                if let warrantyEndDate = item.warrantyEndDate {
                    Divider()
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Expires On")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(warrantyEndDate.formatted(date: .long, time: .omitted))
                                .font(.body)
                                .fontWeight(.medium)
                        }
                        Spacer()
                    }
                }
            }
            .padding()
            .background(Color(status.color).opacity(0.1))
            .cornerRadius(12)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
    
    // MARK: - Return Status Card
    
    private func returnStatusCard(returnEndDate: Date) -> some View {
        let isExpired = returnEndDate < Date()
        let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: returnEndDate).day ?? 0
        
        return VStack(spacing: 16) {
            HStack {
                Image(systemName: "arrow.uturn.backward.circle.fill")
                    .foregroundColor(isExpired ? .red : .green)
                    .font(.title2)
                Text("Return Window")
                    .font(.headline)
                Spacer()
            }
            
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Status")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(isExpired ? "Expired" : "Active")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(isExpired ? .red : .green)
                    }
                    Spacer()
                    Image(systemName: isExpired ? "xmark.circle.fill" : "checkmark.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(isExpired ? .red : .green)
                }
                
                if !isExpired {
                    Divider()
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Time Remaining")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("\(daysRemaining) days")
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                        Spacer()
                    }
                }
                
                Divider()
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(isExpired ? "Expired On" : "Expires On")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(returnEndDate.formatted(date: .long, time: .omitted))
                            .font(.body)
                            .fontWeight(.medium)
                    }
                    Spacer()
                }
            }
            .padding()
            .background((isExpired ? Color.red : Color.green).opacity(0.1))
            .cornerRadius(12)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
    
    // MARK: - Warranty Details Section
    
    private var warrantyDetailsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(.blue)
                Text("Warranty Details")
                    .font(.headline)
                Spacer()
            }
            
            VStack(spacing: 12) {
                if let conditions = item.warrantyConditions, !conditions.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Conditions")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        Text(conditions)
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.tertiarySystemGroupedBackground))
                    .cornerRadius(12)
                }
                
                if let url = item.warrantyEvidenceUrl, !url.isEmpty, let validUrl = URL(string: url) {
                    Link(destination: validUrl) {
                        HStack {
                            Image(systemName: "link.circle.fill")
                                .foregroundColor(.blue)
                            Text("View Warranty Policy")
                                .font(.body)
                                .fontWeight(.medium)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                        }
                        .foregroundColor(.blue)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
                
                if (item.warrantyConditions == nil || item.warrantyConditions?.isEmpty == true) &&
                   (item.warrantyEvidenceUrl == nil || item.warrantyEvidenceUrl?.isEmpty == true) {
                    Text("No additional warranty details available")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.tertiarySystemGroupedBackground))
                        .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
    
    // MARK: - Return Policy Details Section
    
    private var returnPolicyDetailsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(.green)
                Text("Return Policy Details")
                    .font(.headline)
                Spacer()
            }
            
            VStack(spacing: 12) {
                if let conditions = item.returnConditions, !conditions.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Conditions")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        Text(conditions)
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.tertiarySystemGroupedBackground))
                    .cornerRadius(12)
                }
                
                if let url = item.returnEvidenceUrl, !url.isEmpty, let validUrl = URL(string: url) {
                    Link(destination: validUrl) {
                        HStack {
                            Image(systemName: "link.circle.fill")
                                .foregroundColor(.green)
                            Text("View Return Policy")
                                .font(.body)
                                .fontWeight(.medium)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                        }
                        .foregroundColor(.green)
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
                
                if (item.returnConditions == nil || item.returnConditions?.isEmpty == true) &&
                   (item.returnEvidenceUrl == nil || item.returnEvidenceUrl?.isEmpty == true) {
                    Text("No additional return policy details available")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.tertiarySystemGroupedBackground))
                        .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
    
    // MARK: - Additional Information Section
    
    private var additionalInfoSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.purple)
                Text("Additional Information")
                    .font(.headline)
                Spacer()
            }
            
            VStack(spacing: 12) {
                InfoRow(
                    icon: "calendar.badge.plus",
                    label: "Added On",
                    value: item.createdAt?.formatted(date: .long, time: .omitted) ?? "Unknown",
                    color: .purple
                )
                
                if item.warrantyLengthMonths > 0 {
                    InfoRow(
                        icon: "clock.fill",
                        label: "Warranty Period",
                        value: "\(item.warrantyLengthMonths) \(item.warrantyLengthMonths == 1 ? "month" : "months")",
                        color: .purple
                    )
                }
                
                if item.returnWindowDays > 0 {
                    InfoRow(
                        icon: "clock.arrow.circlepath",
                        label: "Return Window",
                        value: "\(item.returnWindowDays) \(item.returnWindowDays == 1 ? "day" : "days")",
                        color: .purple
                    )
                }
            }
            .padding()
            .background(Color(.tertiarySystemGroupedBackground))
            .cornerRadius(12)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
    
    // MARK: - Delete Button
    
    private var deleteButton: some View {
        Button(action: { showingDeleteAlert = true }) {
            HStack {
                Image(systemName: "trash.fill")
                Text("Delete Item")
            }
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.red)
            .cornerRadius(12)
        }
        .padding(.top, 8)
    }
    
    // MARK: - Helper Functions
    
    private func statusIcon(for status: WarrantyStatus) -> String {
        switch status {
        case .active:
            return "checkmark.circle.fill"
        case .expiringSoon:
            return "clock.fill"
        case .expired:
            return "xmark.circle.fill"
        case .unknown:
            return "questionmark.circle.fill"
        }
    }
    
    private func deleteItem() {
        withAnimation {
            viewContext.delete(item)
            
            do {
                try viewContext.save()
                dismiss()
            } catch {
                let nsError = error as NSError
                print("Error deleting item: \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

// MARK: - Info Row Component

struct InfoRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.body)
                    .fontWeight(.medium)
            }
            
            Spacer()
        }
    }
}

// MARK: - Full Screen Image View

struct FullScreenImageView: View {
    let image: UIImage
    @Binding var isPresented: Bool
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .scaleEffect(scale)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            scale = lastScale * value
                        }
                        .onEnded { _ in
                            lastScale = scale
                            if scale < 1.0 {
                                withAnimation {
                                    scale = 1.0
                                    lastScale = 1.0
                                }
                            }
                        }
                )
            
            VStack {
                HStack {
                    Spacer()
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                            .shadow(radius: 4)
                    }
                    .padding()
                }
                Spacer()
            }
        }
    }
}

// MARK: - Edit Warranty Item View Placeholder

struct EditWarrantyItemView: View {
    @ObservedObject var item: WarrantyItem
    let warrantyService: WarrantyService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Text("Edit functionality coming soon")
            .navigationTitle("Edit Item")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
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
    item.warrantyConditions = "Limited warranty covering manufacturing defects"
    item.warrantyEvidenceUrl = "https://apple.com/warranty"
    
    return NavigationView {
        WarrantyItemDetailView(
            item: item,
            warrantyService: WarrantyService(context: context)
        )
    }
}
