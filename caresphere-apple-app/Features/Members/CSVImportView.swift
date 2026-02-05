import SwiftUI
import UniformTypeIdentifiers

/// CSV file import view for bulk member creation
struct CSVImportView: View {
    @EnvironmentObject private var theme: CareSphereTheme
    @EnvironmentObject private var memberService: MemberService
    @Environment(\.dismiss) private var dismiss

    @State private var isImporting = false
    @State private var selectedFileURL: URL?
    @State private var showingFilePicker = false
    @State private var errorMessage = ""
    @State private var showError = false

    let onImportComplete: (String) -> Void

    var body: some View {
        NavigationView {
            VStack(spacing: CareSphereSpacing.xl) {
                // Header
                VStack(spacing: CareSphereSpacing.md) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 60))
                        .foregroundColor(theme.colors.primary)

                    Text("Import Members from CSV")
                        .font(CareSphereTypography.titleLarge)
                        .fontWeight(.bold)
                        .foregroundColor(theme.colors.onBackground)

                    Text("Upload a CSV file to add multiple members at once")
                        .font(CareSphereTypography.bodyMedium)
                        .foregroundColor(theme.colors.onSurface.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, CareSphereSpacing.lg)
                }
                .padding(.top, CareSphereSpacing.xxl)

                // File selection
                VStack(spacing: CareSphereSpacing.md) {
                    if let fileURL = selectedFileURL {
                        HStack {
                            Image(systemName: "doc.fill")
                                .foregroundColor(theme.colors.primary)
                            Text(fileURL.lastPathComponent)
                                .font(CareSphereTypography.bodyMedium)
                                .foregroundColor(theme.colors.onSurface)
                            Spacer()
                            Button(action: { selectedFileURL = nil }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(theme.colors.onSurface.opacity(0.5))
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: CareSphereRadius.md)
                                .fill(theme.colors.surface)
                                .overlay(
                                    RoundedRectangle(cornerRadius: CareSphereRadius.md)
                                        .stroke(theme.colors.primary, lineWidth: 2)
                                )
                        )
                        .padding(.horizontal, CareSphereSpacing.lg)
                    }

                    Button(action: { showingFilePicker = true }) {
                        HStack {
                            Image(systemName: "folder")
                            Text(
                                selectedFileURL == nil ? "Choose CSV File" : "Choose Different File"
                            )
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(theme.colors.surface)
                        .foregroundColor(theme.colors.primary)
                        .cornerRadius(CareSphereRadius.md)
                        .overlay(
                            RoundedRectangle(cornerRadius: CareSphereRadius.md)
                                .stroke(theme.colors.primary, lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, CareSphereSpacing.lg)
                }

                // Instructions
                VStack(alignment: .leading, spacing: CareSphereSpacing.sm) {
                    Text("CSV Format Requirements:")
                        .font(CareSphereTypography.bodySmall)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.colors.onSurface)

                    VStack(alignment: .leading, spacing: 4) {
                        InstructionRow(text: "First row must be headers")
                        InstructionRow(text: "Required: Full Name column")
                        InstructionRow(text: "Optional: Email, Phone, Country, etc.")
                        InstructionRow(text: "Encoding: UTF-8")
                    }
                }
                .padding(CareSphereSpacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: CareSphereRadius.md)
                        .fill(theme.colors.surface.opacity(0.5))
                )
                .padding(.horizontal, CareSphereSpacing.lg)

                Spacer()

                // Import button
                CareSphereButton(
                    "Import Members",
                    action: importCSV,
                    style: .primary,
                    isLoading: isImporting,
                    isDisabled: selectedFileURL == nil || isImporting
                )
                .padding(.horizontal, CareSphereSpacing.lg)
                .padding(.bottom, CareSphereSpacing.lg)
            }
            .background(theme.colors.background)
            .navigationTitle("Import CSV")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [.commaSeparatedText, .plainText],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        selectedFileURL = url
                    }
                case .failure(let error):
                    errorMessage = "Failed to select file: \(error.localizedDescription)"
                    showError = true
                }
            }
            .alert("Import Error", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func importCSV() {
        guard let fileURL = selectedFileURL else { return }

        isImporting = true

        Task {
            do {
                // Read CSV file
                guard fileURL.startAccessingSecurityScopedResource() else {
                    throw CSVImportError.accessDenied
                }
                defer { fileURL.stopAccessingSecurityScopedResource() }

                let csvString = try String(contentsOf: fileURL, encoding: .utf8)

                // Send to API
                let result = try await memberService.importMembersFromCSV(csvContent: csvString)

                await MainActor.run {
                    isImporting = false
                    dismiss()
                    onImportComplete("Successfully imported \(result.successCount) members")
                }

            } catch {
                await MainActor.run {
                    isImporting = false
                    errorMessage = "Import failed: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
}

struct InstructionRow: View {
    @EnvironmentObject private var theme: CareSphereTheme
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.caption)
                .foregroundColor(theme.colors.primary)
            Text(text)
                .font(CareSphereTypography.bodySmall)
                .foregroundColor(theme.colors.onSurface.opacity(0.7))
        }
    }
}

enum CSVImportError: LocalizedError {
    case accessDenied
    case invalidFormat

    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Unable to access the selected file"
        case .invalidFormat:
            return "Invalid CSV file format"
        }
    }
}

#Preview {
    CSVImportView { result in
        print(result)
    }
    .environmentObject(CareSphereTheme.shared)
    .environmentObject(MemberService.shared)
}
