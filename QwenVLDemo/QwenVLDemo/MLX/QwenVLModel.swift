import Foundation
import UIKit

#if canImport(MLX)
import MLX
import MLXFast
import MLXNN
#endif

#if canImport(MLXLLM)
import MLXLLM
#endif

enum QwenVLError: LocalizedError {
    case mlxUnavailable
    case modelNotLoaded
    case imageEncodingFailed

    var errorDescription: String? {
        switch self {
        case .mlxUnavailable:
            return "MLX ライブラリをリンクできません。mlx-swift パッケージが正しく解決されているか確認してください。"
        case .modelNotLoaded:
            return "モデルがまだ読み込まれていません。"
        case .imageEncodingFailed:
            return "画像のエンコードに失敗しました。サポートされている形式であることを確認してください。"
        }
    }
}

actor QwenVLModel {
    private let modelFolderURL: URL

    #if canImport(MLXLLM)
    private var pipeline: VisionLanguagePipeline?
    #endif

    init(modelFolderURL: URL) async throws {
        self.modelFolderURL = modelFolderURL

        #if canImport(MLXLLM)
        self.pipeline = try await VisionLanguagePipeline(modelURL: modelFolderURL)
        #else
        throw QwenVLError.mlxUnavailable
        #endif
    }

    func generateResponse(prompt: String, image: UIImage) async throws -> String {
        #if canImport(MLXLLM)
        guard let pipeline else { throw QwenVLError.modelNotLoaded }
        let resized = image.preparingForInference()
        return try await pipeline.generate(prompt: prompt, image: resized)
        #else
        throw QwenVLError.mlxUnavailable
        #endif
    }
}

#if canImport(MLXLLM)

@MainActor
private final class VisionLanguagePipeline {
    private let chat: VisionLanguageChat
    private let visionEncoder: QwenVisionEncoder
    private let config: GenerationConfig

    init(modelURL: URL) async throws {
        let tokenizerPath = modelURL.appendingPathComponent("tokenizer.json")
        let configPath = modelURL.appendingPathComponent("config.json")
        let weightsPath = modelURL.appendingPathComponent("weights").path

        let tokenizer = try Tokenizer(from: tokenizerPath.path)
        let modelConfig = try ModelConfig(contentsOf: configPath)
        visionEncoder = try QwenVisionEncoder(rootURL: modelURL)

        chat = try await VisionLanguageChat(
            modelPath: weightsPath,
            tokenizer: tokenizer,
            configuration: modelConfig,
            visionEncoder: visionEncoder
        )

        config = GenerationConfig(
            maxTokens: 512,
            temperature: 0.15,
            topP: 0.8,
            topK: 40,
            repetitionPenalty: 1.05,
            stopSequences: ["<|im_end|>"]
        )
    }

    func generate(prompt: String, image: UIImage) async throws -> String {
        let input = try visionEncoder.encode(image: image)
        let request = VisionLanguageRequest(prompt: prompt, images: [input], config: config)
        let result = try await chat.generate(request: request)
        return result.text
    }
}

private struct GenerationConfig {
    let maxTokens: Int
    let temperature: Float
    let topP: Float
    let topK: Int
    let repetitionPenalty: Float
    let stopSequences: [String]
}

private struct VisionLanguageRequest {
    let prompt: String
    let images: [Tensor<Float>]
    let config: GenerationConfig
}

private struct GenerationResult {
    let text: String
}

private final class VisionLanguageChat {
    private let runner: MLXLLM.ChatModel
    private let config: ModelConfig
    private let tokenizer: Tokenizer

    init(modelPath: String, tokenizer: Tokenizer, configuration: ModelConfig, visionEncoder: QwenVisionEncoder) async throws {
        self.tokenizer = tokenizer
        self.config = configuration
        self.runner = try await ChatModel.load(
            weightsDirectory: modelPath,
            config: configuration,
            tokenizer: tokenizer,
            visionEncoder: visionEncoder.encoder
        )
    }

    func generate(request: VisionLanguageRequest) async throws -> GenerationResult {
        var generator = try runner.makeGenerator(
            maxGeneratedTokens: request.config.maxTokens,
            temperature: request.config.temperature,
            topP: request.config.topP,
            topK: request.config.topK,
            repetitionPenalty: request.config.repetitionPenalty,
            stopSequences: request.config.stopSequences
        )

        let response = try await generator.generate(
            prompt: request.prompt,
            images: request.images
        )
        return GenerationResult(text: response)
    }
}

private final class QwenVisionEncoder {
    let encoder: MLXLLM.VisionEncoder

    init(rootURL: URL) throws {
        let visionConfigURL = rootURL.appendingPathComponent("vision_config.json")
        let visionWeightsURL = rootURL.appendingPathComponent("vision")
        encoder = try VisionEncoder(
            configURL: visionConfigURL,
            weightsURL: visionWeightsURL
        )
    }

    func encode(image: UIImage) throws -> Tensor<Float> {
        guard let pixelTensor = try encoder.encode(image: image) else {
            throw QwenVLError.imageEncodingFailed
        }
        return pixelTensor
    }
}

private extension UIImage {
    func preparingForInference(maxPixels: Int = 896) -> UIImage {
        let maxDimension = max(size.width, size.height)
        guard maxDimension > CGFloat(maxPixels) else { return self }
        let scale = CGFloat(maxPixels) / maxDimension
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        UIGraphicsBeginImageContextWithOptions(newSize, true, 1.0)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: newSize))
        return UIGraphicsGetImageFromCurrentImageContext() ?? self
    }
}

#endif

#if !canImport(MLXLLM)
private extension UIImage {
    func preparingForInference() -> UIImage { self }
}
#endif
