import UIKit
import Social

class ShareViewController: SLComposeServiceViewController {

    override func isContentValid() -> Bool {
        return true
    }

    override func didSelectPost() {
        print("📤 Share Extension 被触发")

        guard let items = extensionContext?.inputItems as? [NSExtensionItem] else {
            print("❌ 无法获取 Extension Items")
            extensionContext?.completeRequest(returningItems: nil)
            return
        }

        let dispatchGroup = DispatchGroup()
        var didProcessAnyImage = false

        for item in items {
            for provider in item.attachments ?? [] {
                if provider.hasItemConformingToTypeIdentifier("public.image") {
                    dispatchGroup.enter()
                    didProcessAnyImage = true

                    provider.loadItem(forTypeIdentifier: "public.image", options: nil) { item, error in
                        defer { dispatchGroup.leave() }

                        var image: UIImage?

                        if let url = item as? URL {
                            image = UIImage(contentsOfFile: url.path)
                            print("🔗 从 URL 加载 UIImage：\(url.path)")
                        } else if let img = item as? UIImage {
                            image = img
                            print("🖼️ 从 UIImage 类型直接接收")
                        }

                        if let image = image,
                           let jpegData = image.jpegData(compressionQuality: 1.0) {
                            saveImageToSharedContainer(imageData: jpegData)
                            print("✅ 已转码为 JPEG 并保存")
                        } else {
                            print("❌ 无法转换为 JPEG")
                        }
                    }
                }
            }
        }

        if didProcessAnyImage {
            dispatchGroup.notify(queue: .main) {
                print("📦 所有图片处理完成")
                self.extensionContext?.completeRequest(returningItems: nil)
            }
        } else {
            print("⚠️ 没有符合的图片类型")
            self.extensionContext?.completeRequest(returningItems: nil)
        }
    }

    override func configurationItems() -> [Any]! {
        return []
    }
}
