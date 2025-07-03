import Foundation
import UIKit

let appGroupID = "group.com.rtmacha.securephotoviewer"

func getSharedContainerURL() -> URL? {
    FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
}

func saveImageToSharedContainer(imageData: Data) {
    print("[PhotoShareExtension]测试：保存图片到共享容器")
    guard let folder = getSharedContainerURL() else {
        print("[PhotoShareExtension]无法获取共享容器路径")
        return
    }
    let fileName = UUID().uuidString + ".jpg"
    let fileURL = folder.appendingPathComponent(fileName)
    do {
        try imageData.write(to: fileURL)
        print("[PhotoShareExtension]已保存图片到：\(fileURL.path)")
    } catch {
        print("[PhotoShareExtension]写入图片失败：\(error)")
    }
}

func loadImageURLsFromSharedContainer() -> [URL] {
    guard let folder = getSharedContainerURL() else { return [] }
    let contents = try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)
    return contents?.filter { ["jpg", "png"].contains($0.pathExtension.lowercased()) } ?? []
}
