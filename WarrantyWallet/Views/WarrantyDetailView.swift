//
//  WarrantyDetailView.swift
//  WarrantyWallet
//
//  Created by Ethan on 22/10/2025.
//

import SwiftUI
import CoreData

struct WarrantyDetailView: View {
    @ObservedObject var item: WarrantyItem
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Warranty Status Card
                warrantyStatusCard
                
                // Warranty Details Section
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
                .padding(.horizontal)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Warranty Status Card
    private var warrantyStatusCard: some View {
        let daysRemaining = item.warrantyEndDate != nil ? Calendar.current.dateComponents([.day], from: Date(), to: item.warrantyEndDate!).day ?? 0 : 0
        let isExpired = item.warrantyEndDate != nil && Date() > item.warrantyEndDate!
        
        return VStack(spacing: 16) {
            HStack {
                Image(systemName: "checkmark.shield.fill")
                    .foregroundColor(.blue)
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
                        Text(item.warrantyEndDate?.formatted(date: .long, time: .omitted) ?? "Unknown")
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
        .padding(.horizontal)
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let item = WarrantyItem(context: context)
    item.itemName = "Sample Item"
    item.warrantyEndDate = Calendar.current.date(byAdding: .day, value: 120, to: Date())
    return NavigationView { WarrantyDetailView(item: item) }
}
