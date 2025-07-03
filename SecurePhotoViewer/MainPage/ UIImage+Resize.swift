//
//   UIImage+Resize.swift
//  SecurePhotoViewer
//
//  Created by tricha on 2025/07/03.
//
import SwiftUI

extension UIImage {
    /// 按原始比例缩放图片，使其长边不超过 maxLength（单位：pt）
    func resizedToFit(maxLength: CGFloat) -> UIImage {
        let originalSize = self.size

        let widthRatio = maxLength / originalSize.width
        let heightRatio = maxLength / originalSize.height
        let scaleRatio = min(widthRatio, heightRatio)

        let newSize = CGSize(
            width: originalSize.width * scaleRatio,
            height: originalSize.height * scaleRatio
        )

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
