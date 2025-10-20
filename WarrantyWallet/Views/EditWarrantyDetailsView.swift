//
//  EditWarrantyDetailsView.swift
//  WarrantyWallet
//
//  Created by Ethan on 20/10/2025.
//

import SwiftUI

struct EditWarrantyDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    
    @Binding var warrantyLengthMonths: Int
    @Binding var returnWindowDays: Int
    @Binding var warrantyConditions: String
    @Binding var returnConditions: String
    @Binding var warrantyEvidenceUrl: String
    @Binding var returnEvidenceUrl: String
    
    @FocusState private var focusedField: Field?
    
    enum Field {
        case warrantyConditions, warrantyUrl, returnConditions, returnUrl
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Warranty Section
                    warrantySection
                    
                    // Return Policy Section
                    returnPolicySection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Edit Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    // MARK: - Warranty Section
    
    private var warrantySection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "checkmark.shield.fill")
                    .foregroundColor(.blue)
                    .font(.title3)
                Text("Warranty")
                    .font(.title3)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            VStack(spacing: 16) {
                // Warranty Period Stepper
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.blue)
                            .font(.body)
                        Text("Period")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("\(warrantyLengthMonths)")
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundColor(.primary)
                        Text(warrantyLengthMonths == 1 ? "month" : "months")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        VStack(spacing: 8) {
                            Button(action: { warrantyLengthMonths = min(60, warrantyLengthMonths + 1) }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                            }
                            
                            Button(action: { warrantyLengthMonths = max(1, warrantyLengthMonths - 1) }) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    
                    // Quick select buttons
                    HStack(spacing: 8) {
                        QuickSelectButton(value: 6, currentValue: $warrantyLengthMonths, label: "6m")
                        QuickSelectButton(value: 12, currentValue: $warrantyLengthMonths, label: "1y")
                        QuickSelectButton(value: 24, currentValue: $warrantyLengthMonths, label: "2y")
                        QuickSelectButton(value: 36, currentValue: $warrantyLengthMonths, label: "3y")
                    }
                }
                .padding()
                .background(Color(.tertiarySystemGroupedBackground))
                .cornerRadius(12)
                
                // Warranty Conditions
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundColor(.blue)
                            .font(.body)
                        Text("Conditions")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    TextEditor(text: $warrantyConditions)
                        .focused($focusedField, equals: .warrantyConditions)
                        .frame(minHeight: 100)
                        .padding(8)
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(focusedField == .warrantyConditions ? Color.blue : Color.clear, lineWidth: 1)
                        )
                }
                .padding()
                .background(Color(.tertiarySystemGroupedBackground))
                .cornerRadius(12)
                
                // Evidence URL
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "link")
                            .foregroundColor(.blue)
                            .font(.body)
                        Text("Evidence Link")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        TextField("https://example.com/warranty", text: $warrantyEvidenceUrl)
                            .focused($focusedField, equals: .warrantyUrl)
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .font(.subheadline)
                        
                        if !warrantyEvidenceUrl.isEmpty {
                            Button(action: { warrantyEvidenceUrl = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(focusedField == .warrantyUrl ? Color.blue : Color.clear, lineWidth: 1)
                    )
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
    
    // MARK: - Return Policy Section
    
    private var returnPolicySection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "arrow.uturn.backward.circle.fill")
                    .foregroundColor(.green)
                    .font(.title3)
                Text("Return Policy")
                    .font(.title3)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            VStack(spacing: 16) {
                // Return Window Stepper
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.green)
                            .font(.body)
                        Text("Period")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("\(returnWindowDays)")
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundColor(.primary)
                        Text(returnWindowDays == 1 ? "day" : "days")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        VStack(spacing: 8) {
                            Button(action: { returnWindowDays = min(365, returnWindowDays + 1) }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.green)
                            }
                            
                            Button(action: { returnWindowDays = max(1, returnWindowDays - 1) }) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    
                    // Quick select buttons
                    HStack(spacing: 8) {
                        QuickSelectButton(value: 7, currentValue: $returnWindowDays, label: "7d", color: .green)
                        QuickSelectButton(value: 14, currentValue: $returnWindowDays, label: "14d", color: .green)
                        QuickSelectButton(value: 30, currentValue: $returnWindowDays, label: "30d", color: .green)
                        QuickSelectButton(value: 60, currentValue: $returnWindowDays, label: "60d", color: .green)
                    }
                }
                .padding()
                .background(Color(.tertiarySystemGroupedBackground))
                .cornerRadius(12)
                
                // Return Conditions
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundColor(.green)
                            .font(.body)
                        Text("Conditions")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    TextEditor(text: $returnConditions)
                        .focused($focusedField, equals: .returnConditions)
                        .frame(minHeight: 100)
                        .padding(8)
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(focusedField == .returnConditions ? Color.green : Color.clear, lineWidth: 1)
                        )
                }
                .padding()
                .background(Color(.tertiarySystemGroupedBackground))
                .cornerRadius(12)
                
                // Evidence URL
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "link")
                            .foregroundColor(.green)
                            .font(.body)
                        Text("Evidence Link")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        TextField("https://example.com/returns", text: $returnEvidenceUrl)
                            .focused($focusedField, equals: .returnUrl)
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .font(.subheadline)
                        
                        if !returnEvidenceUrl.isEmpty {
                            Button(action: { returnEvidenceUrl = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(focusedField == .returnUrl ? Color.green : Color.clear, lineWidth: 1)
                    )
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
}

// MARK: - Quick Select Button Component

struct QuickSelectButton: View {
    let value: Int
    @Binding var currentValue: Int
    let label: String
    var color: Color = .blue
    
    var isSelected: Bool {
        currentValue == value
    }
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                currentValue = value
            }
        }) {
            Text(label)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : color)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(isSelected ? color : color.opacity(0.1))
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    EditWarrantyDetailsView(
        warrantyLengthMonths: .constant(12),
        returnWindowDays: .constant(30),
        warrantyConditions: .constant("Standard warranty terms apply"),
        returnConditions: .constant("Standard return policy applies"),
        warrantyEvidenceUrl: .constant("https://example.com/warranty"),
        returnEvidenceUrl: .constant("https://example.com/returns")
    )
}
