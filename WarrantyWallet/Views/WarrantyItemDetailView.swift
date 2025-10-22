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
                
                // Warranty & Return Summary Cards
                warrantyReturnSummaryCards
                
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
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: shareWarrantyCard) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title3)
                }
            }
            
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
    
    // MARK: - Warranty & Return Summary Cards
    
    private var warrantyReturnSummaryCards: some View {
        HStack(spacing: 12) {
            NavigationLink(destination: WarrantyDetailView(item: item)) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundColor(.blue)
                            .font(.title3)
                        Spacer()
                    }
                    
                    Text("Warranty")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let warrantyEndDate = item.warrantyEndDate {
                        Text("Expires: \(warrantyEndDate.formatted(date: .abbreviated, time: .omitted))")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                            .truncationMode(.tail)
                            .allowsTightening(true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(16)
                .foregroundColor(.primary)
            }
            
            NavigationLink(destination: ReturnPolicyDetailView(item: item)) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "arrow.uturn.backward.circle.fill")
                            .foregroundColor(.green)
                            .font(.title3)
                        Spacer()
                    }
                    
                    Text("Return")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let returnEndDate = item.returnEndDate {
                        Text("Expires: \(returnEndDate.formatted(date: .abbreviated, time: .omitted))")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                            .truncationMode(.tail)
                            .allowsTightening(true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(16)
                .foregroundColor(.primary)
            }
        }
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
    
    private func shareWarrantyCard() {
        let warrantyCardText = warrantyService.generateWarrantyCard(for: item)
        
        let activityViewController = UIActivityViewController(
            activityItems: [warrantyCardText],
            applicationActivities: nil
        )
        
        // For iPad support
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            
            // Present from the root view controller
            if let presentedViewController = rootViewController.presentedViewController {
                presentedViewController.present(activityViewController, animated: true)
            } else {
                rootViewController.present(activityViewController, animated: true)
            }
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

