import SwiftUI

struct SaveSnapshotView: View {
    @Binding var isPresented: Bool
    var onSave: (String) -> Void

    @State private var snapshotName: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Snapshot Details") {
                    TextField("Snapshot Name", text: $snapshotName, prompt: Text("e.g., Baseline 2024"))
                }

                Section {
                    Text("This projection will be saved with the current accounts and assumptions for comparison later.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle("Save Projection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(snapshotName.isEmpty ? "Projection" : snapshotName)
                        isPresented = false
                    }
                }
            }
        }
    }
}

#Preview {
    SaveSnapshotView(isPresented: .constant(true)) { _ in }
}
