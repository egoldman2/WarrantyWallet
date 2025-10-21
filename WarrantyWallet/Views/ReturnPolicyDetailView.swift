//
//  ReturnPolicyDetailView.swift
//  WarrantyWallet
//
//  Created by Ethan on 22/10/2025.
//

import SwiftUI
import CoreData

struct ReturnPolicyDetailView: View {
    @ObservedObject var item: WarrantyItem
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Return Window Status Card
                returnWindowStatusCard
                
                // Return Policy Details Section
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
                .padding(.horizontal)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Return Window Status Card
    private var returnWindowStatusCard: some View {
        let isExpired = item.returnEndDate != nil && Date() > item.returnEndDate!
        let daysRemaining = item.returnEndDate != nil ? Calendar.current.dateComponents([.day], from: Date(), to: item.returnEndDate!).day ?? 0 : 0
        
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
                        Text(item.returnEndDate?.formatted(date: .long, time: .omitted) ?? "Unknown")
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
    item.returnEndDate = Calendar.current.date(byAdding: .day, value: 14, to: Date())
    return NavigationView { ReturnPolicyDetailView(item: item) }
}
