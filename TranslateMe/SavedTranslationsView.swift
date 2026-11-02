import SwiftUI

struct SavedTranslationsView: View {
    @EnvironmentObject var viewModel: TranslationViewModel

    var body: some View {
        List(viewModel.history) { item in
            Text(item.translated)
        }
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Button {
                Task { await viewModel.clearHistory() }
            } label: {
                Text("Clear All Translations")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding(.bottom, 8)
        }
    }
}
