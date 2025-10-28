import Foundation
import PhotosUI
import UIKit

enum ImageUtilitiesError: LocalizedError {
    case failedToLoad
    case decodingFailure

    var errorDescription: String? {
        switch self {
        case .failedToLoad:
            return "画像データを読み込めませんでした"
        case .decodingFailure:
            return "画像をデコードできませんでした"
        }
    }
}

struct ImageUtilities {
    func loadUIImage(from item: PhotosPickerItem) async throws -> UIImage {
        if let data = try await item.loadTransferable(type: Data.self) {
            guard let image = UIImage(data: data) else {
                throw ImageUtilitiesError.decodingFailure
            }
            return image.normalizedImage()
        }

        if #available(iOS 17.0, *) {
            if let image = try await item.loadTransferable(type: UIImage.self) {
                return image.normalizedImage()
            }
        }

        throw ImageUtilitiesError.failedToLoad
    }
}

private extension UIImage {
    func normalizedImage() -> UIImage {
        guard imageOrientation != .up else { return self }
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext() ?? self
    }
}
