import SwiftUI

struct AddMemberView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var theme: CareSphereTheme
    @EnvironmentObject private var memberService: MemberService
    @EnvironmentObject private var fieldConfigService: FieldConfigService

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var phoneNumber = ""
    @State private var whatsAppNumber = ""
    @State private var weChatID = ""
    @State private var dateOfBirth: Date?
    @State private var address = ""
    @State private var customFields: [String: String] = [:]
    @State private var showingAddCustomField = false
    @State private var newFieldName = ""
    @State private var newFieldValue = ""
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        NavigationView {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("First Name")
                            .font(CareSphereTypography.labelSmall)
                            .foregroundColor(theme.colors.onSurface.opacity(0.7))
                        TextField("Required", text: $firstName)
                            .textInputAutocapitalization(.words)
                    }
                    .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Last Name")
                            .font(CareSphereTypography.labelSmall)
                            .foregroundColor(theme.colors.onSurface.opacity(0.7))
                        TextField("Required", text: $lastName)
                            .textInputAutocapitalization(.words)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Basic Information")
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email Address")
                            .font(CareSphereTypography.labelSmall)
                            .foregroundColor(theme.colors.onSurface.opacity(0.7))
                        TextField("example@email.com", text: $email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                    }
                    .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Phone Number")
                            .font(CareSphereTypography.labelSmall)
                            .foregroundColor(theme.colors.onSurface.opacity(0.7))
                        TextField("+1 (555) 123-4567", text: $phoneNumber)
                            .keyboardType(.phonePad)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Contact Information")
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("WhatsApp Number")
                            .font(CareSphereTypography.labelSmall)
                            .foregroundColor(theme.colors.onSurface.opacity(0.7))
                        TextField("+1 (555) 123-4567", text: $whatsAppNumber)
                            .keyboardType(.phonePad)
                    }
                    .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("WeChat ID")
                            .font(CareSphereTypography.labelSmall)
                            .foregroundColor(theme.colors.onSurface.opacity(0.7))
                        TextField("WeChat username", text: $weChatID)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Social Media")
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Date of Birth")
                            .font(CareSphereTypography.labelSmall)
                            .foregroundColor(theme.colors.onSurface.opacity(0.7))
                        DatePicker(
                            "Select date",
                            selection: Binding(
                                get: { dateOfBirth ?? Date() },
                                set: { dateOfBirth = $0 }
                            ),
                            displayedComponents: .date
                        )
                        .datePickerStyle(.compact)
                    }
                    .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Address")
                            .font(CareSphereTypography.labelSmall)
                            .foregroundColor(theme.colors.onSurface.opacity(0.7))
                        TextField(
                            "Street address, City, State, ZIP", text: $address, axis: .vertical
                        )
                        .lineLimit(2...4)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Additional Information")
                }

                if !customFields.isEmpty {
                    Section {
                        ForEach(Array(customFields.keys.sorted()), id: \.self) { key in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(key)
                                        .font(CareSphereTypography.labelSmall)
                                        .foregroundColor(theme.colors.onSurface.opacity(0.7))
                                    Spacer()
                                    Button {
                                        customFields.removeValue(forKey: key)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(theme.colors.onSurface.opacity(0.4))
                                    }
                                }
                                TextField(
                                    "Value",
                                    text: Binding(
                                        get: { customFields[key] ?? "" },
                                        set: { customFields[key] = $0 }
                                    ))
                            }
                            .padding(.vertical, 4)
                        }
                    } header: {
                        Text("Custom Fields")
                    }
                }

                Section {
                    Button {
                        showingAddCustomField = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Custom Field")
                        }
                        .foregroundColor(theme.colors.primary)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(theme.colors.background)
            .navigationTitle("Add Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button("Save") {
                            Task {
                                await saveMember()
                            }
                        }
                        .disabled(firstName.isEmpty || lastName.isEmpty)
                        .fontWeight(.semibold)
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "An error occurred")
            }
            .sheet(isPresented: $showingAddCustomField) {
                addCustomFieldSheet
            }
        }
    }

    private var addCustomFieldSheet: some View {
        NavigationView {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Field Name")
                            .font(CareSphereTypography.labelSmall)
                            .foregroundColor(theme.colors.onSurface.opacity(0.7))
                        TextField("e.g., Emergency Contact", text: $newFieldName)
                            .textInputAutocapitalization(.words)
                    }
                    .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Value")
                            .font(CareSphereTypography.labelSmall)
                            .foregroundColor(theme.colors.onSurface.opacity(0.7))
                        TextField("Enter value", text: $newFieldValue, axis: .vertical)
                            .lineLimit(1...3)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Custom Field Details")
                } footer: {
                    Text("Add any additional information you want to track for this member.")
                        .font(CareSphereTypography.caption)
                }
            }
            .scrollContentBackground(.hidden)
            .background(theme.colors.background)
            .navigationTitle("Add Custom Field")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        newFieldName = ""
                        newFieldValue = ""
                        showingAddCustomField = false
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        customFields[newFieldName] = newFieldValue
                        newFieldName = ""
                        newFieldValue = ""
                        showingAddCustomField = false
                    }
                    .disabled(newFieldName.isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func saveMember() async {
        guard !firstName.isEmpty, !lastName.isEmpty else { return }

        isSaving = true
        defer { isSaving = false }

        // Convert custom fields to proper format
        let customFieldsDict: [String: String] = customFields

        let request = CreateMemberRequest(
            firstName: firstName.trimmingCharacters(in: .whitespacesAndNewlines),
            lastName: lastName.trimmingCharacters(in: .whitespacesAndNewlines),
            email: email.isEmpty ? nil : email.trimmingCharacters(in: .whitespacesAndNewlines),
            phoneNumber: phoneNumber.isEmpty
                ? nil : phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines),
            whatsAppNumber: whatsAppNumber.isEmpty
                ? nil : whatsAppNumber.trimmingCharacters(in: .whitespacesAndNewlines),
            weChatID: weChatID.isEmpty
                ? nil : weChatID.trimmingCharacters(in: .whitespacesAndNewlines),
            dateOfBirth: dateOfBirth,
            address: address.isEmpty
                ? nil
                : Address(
                    street: address.trimmingCharacters(in: .whitespacesAndNewlines),
                    city: nil,
                    state: nil,
                    postalCode: nil,
                    country: nil
                ),
            tags: [],
            customFields: customFieldsDict,
            emergencyContact: nil,
            householdId: nil
        )

        do {
            _ = try await memberService.createMember(request)
            // Reload members list
            try? await memberService.loadMembers()
            dismiss()
        } catch {
            errorMessage = "Failed to create member: \(error.localizedDescription)"
            showError = true
        }
    }
}
