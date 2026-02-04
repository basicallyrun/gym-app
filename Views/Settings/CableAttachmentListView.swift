import SwiftUI
import SwiftData

struct CableAttachmentListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CableAttachment.name) private var attachments: [CableAttachment]
    @State private var showingAddAlert = false
    @State private var newName = ""

    var body: some View {
        List {
            ForEach(attachments) { attachment in
                Text(attachment.name)
            }
            .onDelete(perform: deleteAttachments)

            if attachments.isEmpty {
                ContentUnavailableView(
                    "No Cable Attachments",
                    systemImage: "link",
                    description: Text("Add your available cable attachments")
                )
            }
        }
        .navigationTitle("Cable Attachments")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddAlert = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .alert("Add Attachment", isPresented: $showingAddAlert) {
            TextField("Name (e.g., Rope, V-Bar)", text: $newName)
            Button("Cancel", role: .cancel) {
                newName = ""
            }
            Button("Add") {
                addAttachment()
            }
        }
    }

    private func addAttachment() {
        guard !newName.isEmpty else { return }
        let attachment = CableAttachment(name: newName)
        modelContext.insert(attachment)
        newName = ""
    }

    private func deleteAttachments(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(attachments[index])
        }
    }
}
