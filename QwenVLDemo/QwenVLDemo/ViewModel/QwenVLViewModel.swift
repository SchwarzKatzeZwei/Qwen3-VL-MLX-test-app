import Foundation
import SwiftUI
import PhotosUI

@MainActor
final class QwenVLViewModel: ObservableObject {
    @Published var uiImage: UIImage?
    @Published var prompt: String
    @Published var generatedText: String?
    @Published var isProcessing = false
    @Published var errorMessage: String?

    private var model: QwenVLModel?
    private let defaults: PromptDefaults
    private let imageLoader = ImageUtilities()
    private let previewMode: Bool

    init(previewMode: Bool = false, defaults: PromptDefaults = .shared) {
        self.defaults = defaults
        self.previewMode = previewMode
        self.prompt = defaults.defaultPrompt

        if previewMode {
            self.generatedText = "このアプリでは写真を撮影し、Qwen3-VLに説明文を生成させます。"
            self.uiImage = UIImage(systemName: "photo")
        }
    }

    func prepareModelIfNeeded() async {
        guard !previewMode else { return }
        guard model == nil else { return }
        do {
            let url = try defaults.resolveModelDirectory()
            model = try await QwenVLModel(modelFolderURL: url)
            errorMessage = nil
        } catch {
            errorMessage = "モデルを初期化できませんでした: \(error.localizedDescription)"
        }
    }

    func loadImage(from item: PhotosPickerItem) async {
        guard !previewMode else { return }
        do {
            uiImage = try await imageLoader.loadUIImage(from: item)
            errorMessage = nil
        } catch {
            errorMessage = "画像の取得に失敗しました: \(error.localizedDescription)"
        }
    }

    func generateResponse() async {
        guard !previewMode else { return }
        guard let uiImage else {
            errorMessage = "画像を選択してください"
            return
        }
        let trimmedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPrompt.isEmpty else {
            errorMessage = "プロンプトを入力してください"
            return
        }

        await prepareModelIfNeeded()
        guard let model else { return }

        isProcessing = true
        errorMessage = nil
        do {
            let result = try await model.generateResponse(prompt: trimmedPrompt, image: uiImage)
            generatedText = result
        } catch {
            errorMessage = "文章生成に失敗しました: \(error.localizedDescription)"
        }
        isProcessing = false
    }
}
