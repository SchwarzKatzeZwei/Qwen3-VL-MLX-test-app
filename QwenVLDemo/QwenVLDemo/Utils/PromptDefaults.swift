import Foundation

struct PromptDefaultsError: LocalizedError {
    var errorDescription: String?
}

final class PromptDefaults {
    static let shared = PromptDefaults()

    private enum Constants {
        static let promptResourceName = "DefaultPrompt"
        static let promptResourceExtension = "json"
        static let modelDirectoryName = "Qwen3-VL-4B-Instruct-MLX-4bit"
        static let modelsFolderName = "Models"
    }

    let defaultPrompt: String

    private init() {
        if let prompt = PromptDefaults.loadPromptFromBundle() {
            defaultPrompt = prompt
        } else {
            defaultPrompt = "写真の内容を詳しく説明し、重要な要素を箇条書きしてください。"
        }
    }

    func resolveModelDirectory() throws -> URL {
        let supportURL = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let modelsFolder = supportURL.appendingPathComponent(Constants.modelsFolderName, isDirectory: true)
        let modelURL = modelsFolder.appendingPathComponent(Constants.modelDirectoryName, isDirectory: true)
        guard FileManager.default.fileExists(atPath: modelURL.path) else {
            throw PromptDefaultsError(errorDescription: "モデルフォルダが \(modelURL.lastPathComponent) に見つかりませんでした。
Application Support/Models 内に Hugging Face からダウンロードしたモデルを配置してください。")
        }
        return modelURL
    }

    private static func loadPromptFromBundle() -> String? {
        guard let url = Bundle.main.url(forResource: Constants.promptResourceName, withExtension: Constants.promptResourceExtension) else {
            return nil
        }
        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode(PromptPayload.self, from: data)
            return decoded.prompt
        } catch {
            print("Failed to decode default prompt: \(error)")
            return nil
        }
    }

    private struct PromptPayload: Decodable {
        let prompt: String
    }
}
