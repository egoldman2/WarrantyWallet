//
//  ContentView.swift
//  WarrantyWallet
//
//  Created by Ethan on 19/10/2025.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var warrantyService: WarrantyService
    @State private var showingAddItem = false
    @State private var searchText = ""

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \WarrantyItem.createdAt, ascending: false)],
        animation: .default)
    private var warrantyItems: FetchedResults<WarrantyItem>

    init() {
        let context = PersistenceController.shared.container.viewContext
        _warrantyService = StateObject(wrappedValue: WarrantyService(context: context))
    }
    
    var filteredItems: [WarrantyItem] {
        if searchText.isEmpty {
            return Array(warrantyItems)
        } else {
            return warrantyItems.filter { item in
                let itemName = item.itemName?.lowercased() ?? ""
                let storeName = item.storeName?.lowercased() ?? ""
                let searchLower = searchText.lowercased()
                return itemName.contains(searchLower) || storeName.contains(searchLower)
            }
        }
    }
    
    var activeItems: [WarrantyItem] {
        filteredItems.filter { item in
            let status = warrantyService.getWarrantyStatus(for: item)
            return status == .active || status == .expiringSoon
        }
    }
    
    var expiredItems: [WarrantyItem] {
        filteredItems.filter { item in
            warrantyService.getWarrantyStatus(for: item) == .expired
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                if warrantyItems.isEmpty {
                    emptyStateView
                } else {
                    itemsList
                }
            }
            .navigationTitle("Warranty Wallet")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddItem = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showingAddItem) {
                AddWarrantyItemView(warrantyService: warrantyService)
            }
        }
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "receipt.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue.opacity(0.3))
            
            VStack(spacing: 12) {
                Text("No Warranties Yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Add your first purchase receipt to keep track of warranties and return policies")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Button(action: { showingAddItem = true }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add First Item")
                }
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(Color.blue)
                .cornerRadius(12)
            }
            .padding(.top, 8)
            
            Spacer()
            Spacer()
        }
    }
    
    // MARK: - Items List
    
    private var itemsList: some View {
        VStack(spacing: 0) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search items or stores", text: $searchText)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 12)
            
            // Summary Cards
            if !filteredItems.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        SummaryCard(
                            title: "Total Items",
                            value: "\(filteredItems.count)",
                            icon: "bag.fill",
                            color: .blue
                        )
                        
                        SummaryCard(
                            title: "Active",
                            value: "\(activeItems.count)",
                            icon: "checkmark.shield.fill",
                            color: .green
                        )
                        
                        SummaryCard(
                            title: "Expired",
                            value: "\(expiredItems.count)",
                            icon: "exclamationmark.triangle.fill",
                            color: .red
                        )
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 16)
            }
            
            // Items List
            List {
                if !activeItems.isEmpty {
                    Section {
                        ForEach(activeItems) { item in
                            NavigationLink(destination: WarrantyItemDetailView(item: item, warrantyService: warrantyService)) {
                                WarrantyItemRowView(item: item, warrantyService: warrantyService)
                            }
                        }
                        .onDelete { indexSet in
                            deleteItems(from: activeItems, at: indexSet)
                        }
                    } header: {
                        Text("Active Warranties")
                            .font(.headline)
                    }
                }
                
                if !expiredItems.isEmpty {
                    Section {
                        ForEach(expiredItems) { item in
                            NavigationLink(destination: WarrantyItemDetailView(item: item, warrantyService: warrantyService)) {
                                WarrantyItemRowView(item: item, warrantyService: warrantyService)
                            }
                        }
                        .onDelete { indexSet in
                            deleteItems(from: expiredItems, at: indexSet)
                        }
                    } header: {
                        Text("Expired")
                            .font(.headline)
                    }
                }
                
                if filteredItems.isEmpty && !searchText.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No results found")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Try a different search term")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(.insetGrouped)
        }
        .background(Color(.systemGroupedBackground))
    }
    
    private func deleteItems(from items: [WarrantyItem], at offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                print("Error deleting item: \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

// MARK: - Summary Card Component

struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                Spacer()
            }
            
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.primary)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(width: 140)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}

// MARK: - Warranty Item Row Component

struct WarrantyItemRowView: View {
    let item: WarrantyItem
    let warrantyService: WarrantyService
    
    var body: some View {
        HStack(spacing: 16) {
            // Receipt Image or Icon
            if let imageData = item.receiptImageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "receipt.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
            }
            
            // Item Details
            VStack(alignment: .leading, spacing: 6) {
                Text(item.itemName ?? "Unknown Item")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                if let storeName = item.storeName {
                    Text(storeName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                HStack(spacing: 12) {
                    if item.price > 0 {
                        Text("$\(String(format: "%.2f", item.price))")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                    
                    if let warrantyEndDate = item.warrantyEndDate {
                        let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: warrantyEndDate).day ?? 0
                        
                        if daysRemaining >= 0 {
                            Text("\(daysRemaining)d left")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Status Badge
            let warrantyStatus = warrantyService.getWarrantyStatus(for: item)
            VStack(spacing: 4) {
                Image(systemName: statusIcon(for: warrantyStatus))
                    .font(.title3)
                    .foregroundColor(Color(warrantyStatus.color))
                
                Text(warrantyStatus.displayName)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(Color(warrantyStatus.color))
            }
        }
        .padding(.vertical, 4)
    }
    
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
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
