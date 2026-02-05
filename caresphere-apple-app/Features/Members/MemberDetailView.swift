import SwiftUI

/// Member detail view
struct MemberDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let member: Member

    var body: some View {
        NavigationView {
            Text("Member Detail: \(member.fullName)")
                .navigationTitle(member.fullName)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
        }
    }
}
