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
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \WarrantyItem.createdAt, ascending: false)],
        animation: .default)
    private var warrantyItems: FetchedResults<WarrantyItem>

    init() {
        let context = PersistenceController.shared.container.viewContext
        _warrantyService = StateObject(wrappedValue: WarrantyService(context: context))
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(warrantyItems) { item in
                    NavigationLink(destination: WarrantyItemDetailView(item: item, warrantyService: warrantyService)) {
                        WarrantyItemRowView(item: item, warrantyService: warrantyService)
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .navigationTitle("Warranty Wallet")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: { showingAddItem = true }) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddItem) {
                AddWarrantyItemView(warrantyService: warrantyService)
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { warrantyItems[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

struct WarrantyItemRowView: View {
    let item: WarrantyItem
    let warrantyService: WarrantyService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text(item.itemName ?? "Default Name")
                        .font(.headline)
                    if let storeName = item.storeName {
                        Text(storeName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    if item.price > 0 {
                        Text("$\(String(format: "%.2f", item.price))")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    let warrantyStatus = warrantyService.getWarrantyStatus(for: item)
                    Text(warrantyStatus.displayName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(warrantyStatus.color).opacity(0.2))
                        .foregroundColor(Color(warrantyStatus.color))
                        .cornerRadius(8)
                }
            }
            
            if let warrantyEndDate = item.warrantyEndDate {
                Text("Warranty expires: \(warrantyEndDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
