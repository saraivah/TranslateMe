import Foundation
import Combine
import FirebaseFirestore

// MARK: - Model

struct Translation: Identifiable {
    let id: String
    let original: String
    let translated: String
}

// MARK: - Translation API (MyMemory — free, no API key needed)

struct TranslationService {
    private struct Response: Decodable {
        let responseData: ResponseData
    }

    private struct ResponseData: Decodable {
        let translatedText: String
    }

    func translate(_ text: String, from source: String = "en", to target: String = "es") async throws -> String {
        var components = URLComponents(string: "https://api.mymemory.translated.net/get")!
        components.queryItems = [
            URLQueryItem(name: "q", value: text),
            URLQueryItem(name: "langpair", value: "\(source)|\(target)")
        ]
        let (data, _) = try await URLSession.shared.data(from: components.url!)
        return try JSONDecoder().decode(Response.self, from: data).responseData.translatedText
    }
}

// MARK: - View Model

@MainActor
final class TranslationViewModel: ObservableObject {
    @Published var inputText = ""
    @Published var translatedText = ""
    @Published var history: [Translation] = []
    @Published var isTranslating = false
    @Published var errorMessage: String?

    private let service = TranslationService()
    private var listener: ListenerRegistration?

    // Computed so Firestore is only touched after FirebaseApp.configure() has run
    private var collection: CollectionReference {
        Firestore.firestore().collection("translations")
    }

    init() {
        startListening()
    }

    /// Keeps `history` in sync with Firestore in real time.
    private func startListening() {
        listener = collection
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error {
                    Task { @MainActor in self?.errorMessage = error.localizedDescription }
                    return
                }
                let items: [Translation] = snapshot?.documents.compactMap { doc in
                    let data = doc.data()
                    guard let original = data["original"] as? String,
                          let translated = data["translated"] as? String else { return nil }
                    return Translation(id: doc.documentID, original: original, translated: translated)
                } ?? []
                Task { @MainActor in self?.history = items }
            }
    }

    func translate() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        isTranslating = true
        defer { isTranslating = false }

        do {
            let result = try await service.translate(text)
            translatedText = result
            try await collection.addDocument(data: [
                "original": text,
                "translated": result,
                "timestamp": Timestamp(date: Date())
            ])
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func clearHistory() async {
        do {
            let snapshot = try await collection.getDocuments()
            let batch = Firestore.firestore().batch()
            snapshot.documents.forEach { batch.deleteDocument($0.reference) }
            try await batch.commit()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
