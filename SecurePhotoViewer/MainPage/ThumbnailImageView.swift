//
//  ThumbnailImageView.swift
//  SecurePhotoViewer
//
//  Created by tricha on 2025/07/03.
//

// 单个缩略图的逻辑
import SwiftUI

struct ThumbnailImageView: View {
    let imageFile: ImageFile
    let size:CGFloat 
    let isSelected: Bool
    let isSelecting: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void

    @State private var thumbnail: UIImage? = nil
    @State private var hasLoaded: Bool = false
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            if let thumbnail = thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .onAppear(){
                        print("🌀 正在加载图片：\(imageFile.url.lastPathComponent)")
                    }
            } else {
//                Color.gray.opacity(0.2) // 占位符
//                    .frame(width: size, height: size)
//                    .overlay(Text("加载失败").font(.caption).foregroundColor(.red))
//                ProgressView()
                ZStack {
                    Color.gray.opacity(0.2)
                    ProgressView()
                }
                .frame(width: size, height: size)
            }
            
        }
        .onAppear {
            if !hasLoaded {
                hasLoaded = true
                DispatchQueue.global().async {
                    if let image = UIImage(contentsOfFile: imageFile.url.path) {
                        let resized = image.resizedToFit(maxLength: size)
                        DispatchQueue.main.async {
                            self.thumbnail = resized
                        }
                    }
                }
            }
        }

        .aspectRatio(contentMode: .fill)
        .frame(width: size, height: size)
        .cornerRadius(12).clipped()
        .shadow(radius: 4)
        .overlay(
            isSelecting && isSelected
                ? Color.black.opacity(0.25).cornerRadius(12)
                : nil
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .onLongPressGesture(perform: onLongPress)
        .overlay(alignment: .topTrailing) {
            if isSelecting {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(.white)
                    .background(Circle().fill(Color.blue))
                    .font(.system(size: 22))
                    .padding(6)
            }
        }
    }

}
fileprivate let sampleImageURL = URL(fileURLWithPath: "/System/Library/CoreServices/DefaultDesktop.heic")


#Preview("选中状态") {
    ThumbnailImageView(
        imageFile: ImageFile(url: sampleImageURL),
        size: 1.2,
        isSelected: true,
        isSelecting: true,
        onTap: {},
        onLongPress: {}
    )
}

#Preview("未选中状态") {
    ThumbnailImageView(
        imageFile: ImageFile(url: sampleImageURL),
        size: 1.2,
        isSelected: false,
        isSelecting: true,
        onTap: {},
        onLongPress: {}
    )
}

