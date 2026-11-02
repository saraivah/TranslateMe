import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: TranslationViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                // Input field
                TextField("Enter text", text: $viewModel.inputText)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal, 12)

                // Translate button
                Button {
                    Task { await viewModel.translate() }
                } label: {
                    Text("Translate Me")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(viewModel.isTranslating)

                // Output field (initially empty)
                ZStack {
                    Text(viewModel.translatedText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                    if viewModel.isTranslating {
                        ProgressView()
                    }
                }
                .frame(height: 100)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.blue, lineWidth: 1)
                )

                NavigationLink("View Saved Translations") {
                    SavedTranslationsView()
                }

                Spacer()
                Spacer()
            }
            .padding(.horizontal, 8)
            .navigationTitle("Translate Me")
            .alert("Something went wrong",
                   isPresented: Binding(
                       get: { viewModel.errorMessage != nil },
                       set: { if !$0 { viewModel.errorMessage = nil } }
                   )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(TranslationViewModel())
}
