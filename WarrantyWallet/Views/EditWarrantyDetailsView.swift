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
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Stepper("\(warrantyLengthMonths) months", value: $warrantyLengthMonths, in: 1...60)
                        
                        TextField("Warranty Conditions", text: $warrantyConditions, axis: .vertical)
                            .lineLimit(3...6)
                        
                        TextField("Evidence URL", text: $warrantyEvidenceUrl)
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                } header: {
                    Text("Warranty Details")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Stepper("\(returnWindowDays) days", value: $returnWindowDays, in: 1...365)
                        
                        TextField("Return Conditions", text: $returnConditions, axis: .vertical)
                            .lineLimit(3...6)
                        
                        TextField("Evidence URL", text: $returnEvidenceUrl)
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                } header: {
                    Text("Return Policy Details")
                }
            }
            .navigationTitle("Edit Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        dismiss()
                    }
                }
            }
        }
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
