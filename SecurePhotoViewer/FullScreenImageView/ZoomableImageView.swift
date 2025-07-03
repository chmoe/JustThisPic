import SwiftUI
import UIKit

struct ZoomableScrollImageView: UIViewRepresentable {
    let image: UIImage
    let resetTrigger: UUID
    var onSwipeDownToDismiss: (() -> Void)? = nil  // 下滑回调
    var onSingleTap: (() -> Void)? = nil           // 单击回调（切换 UI）

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = baseScrollView(context: context)
        context.coordinator.scrollView = scrollView
        return scrollView
    }

    func updateUIView(_ uiView: UIScrollView, context: Context) {
        if let imageView = uiView.viewWithTag(100) as? UIImageView {
            imageView.image = image
        }

        // 记录 resetTrigger，并判断是否变化
        if context.coordinator.lastResetTrigger != resetTrigger {
            context.coordinator.lastResetTrigger = resetTrigger

            // 只有 resetToken 变化时才重置缩放
            uiView.setZoomScale(1.0, animated: false)
            uiView.contentOffset = .zero
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onSwipeDownToDismiss: onSwipeDownToDismiss, onSingleTap: onSingleTap)
    }

    class Coordinator: NSObject, UIScrollViewDelegate {
        var lastResetTrigger: UUID?
        weak var scrollView: UIScrollView?

        private var doubleTapRecognizer: UITapGestureRecognizer?
        private var panRecognizer: UIPanGestureRecognizer?
        private var singleTapRecognizer: UITapGestureRecognizer?

        private var isZoomed: Bool = false
        private var onSwipeDownToDismiss: (() -> Void)?
        private var onSingleTap: (() -> Void)?

        init(onSwipeDownToDismiss: (() -> Void)? = nil, onSingleTap: (() -> Void)? = nil) {
            self.onSwipeDownToDismiss = onSwipeDownToDismiss
            self.onSingleTap = onSingleTap
        }

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return scrollView.viewWithTag(100)
        }

        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            centerImageView(in: scrollView)
        }

        func scrollViewDidLayoutSubviews(_ scrollView: UIScrollView) {
            guard let imageView = scrollView.viewWithTag(100) as? UIImageView else { return }

            // 缩放前的中心点（百分比）
            let oldCenter = CGPoint(
                x: (scrollView.contentOffset.x + scrollView.bounds.size.width / 2) / scrollView.contentSize.width,
                y: (scrollView.contentOffset.y + scrollView.bounds.size.height / 2) / scrollView.contentSize.height
            )

            // 使用图片真实比例计算 imageView 尺寸
            let imageSize = imageView.image?.size ?? .zero
            let scrollSize = scrollView.bounds.size
            let imageRatio = imageSize.width / imageSize.height
            let scrollRatio = scrollSize.width / scrollSize.height

            var displaySize: CGSize
            if imageRatio > scrollRatio {
                // 按宽度适配
                let width = scrollSize.width
                let height = width / imageRatio
                displaySize = CGSize(width: width, height: height)
            } else {
                // 按高度适配
                let height = scrollSize.height
                let width = height * imageRatio
                displaySize = CGSize(width: width, height: height)
            }

            imageView.frame = CGRect(origin: .zero, size: displaySize)
            scrollView.contentSize = displaySize

            // 限制缩放值在有效范围
            scrollView.zoomScale = max(scrollView.minimumZoomScale, min(scrollView.zoomScale, scrollView.maximumZoomScale))

            // 保持原中心位置
            let newOffset = CGPoint(
                x: displaySize.width * oldCenter.x - scrollView.bounds.size.width / 2,
                y: displaySize.height * oldCenter.y - scrollView.bounds.size.height / 2
            )
            scrollView.contentOffset = newOffset

            // 居中处理
            centerImageView(in: scrollView)
        }



        private func centerImageView(in scrollView: UIScrollView) {
            guard let imageView = scrollView.viewWithTag(100) else { return }

            let boundsSize = scrollView.bounds.size
            let contentSize = scrollView.contentSize

            var verticalInset: CGFloat = 0
            var horizontalInset: CGFloat = 0

            if contentSize.width < boundsSize.width {
                horizontalInset = (boundsSize.width - contentSize.width) / 2
            }

            if contentSize.height < boundsSize.height {
                verticalInset = (boundsSize.height - contentSize.height) / 2
            }

            scrollView.contentInset = UIEdgeInsets(top: verticalInset,
                                                   left: horizontalInset,
                                                   bottom: verticalInset,
                                                   right: horizontalInset)
        }

        @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
            guard let scrollView = scrollView else { return }
            let newScale: CGFloat = scrollView.zoomScale > 1.1 ? 1.0 : 2.5
            let point = gesture.location(in: scrollView)

            let width = scrollView.frame.size.width / newScale
            let height = scrollView.frame.size.height / newScale
            let x = point.x - (width / 2.0)
            let y = point.y - (height / 2.0)

            let zoomRect = CGRect(x: x, y: y, width: width, height: height)
            scrollView.zoom(to: zoomRect, animated: true)
        }

        @objc func handleSingleTap(_ gesture: UITapGestureRecognizer) {
            onSingleTap?()
        }

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let scrollView = scrollView else { return }
            let velocity = gesture.velocity(in: scrollView)
            let translation = gesture.translation(in: scrollView)

            if gesture.state == .ended {
                if velocity.y > 1200 && abs(translation.y) > 80 {
                    onSwipeDownToDismiss?()
                }
            }
        }

        func attachGestures(to scrollView: UIScrollView) {
            let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
            doubleTap.numberOfTapsRequired = 2
            scrollView.addGestureRecognizer(doubleTap)
            self.doubleTapRecognizer = doubleTap

            let singleTap = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap(_:)))
            singleTap.numberOfTapsRequired = 1
            singleTap.require(toFail: doubleTap)
            scrollView.addGestureRecognizer(singleTap)
            self.singleTapRecognizer = singleTap

            let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
            pan.delegate = self
            scrollView.addGestureRecognizer(pan)
            self.panRecognizer = pan
        }
    }
}

extension ZoomableScrollImageView.Coordinator: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
        return true
    }
}

// MARK: - Private ScrollView factory
private extension ZoomableScrollImageView {
    func baseScrollView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator

        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 5.0
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.bouncesZoom = true
        scrollView.clipsToBounds = true
        scrollView.backgroundColor = .clear

        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.tag = 100
        
        let imageSize = image.size
        let scrollSize = scrollView.bounds.size
        let imageRatio = imageSize.width / imageSize.height
        let scrollRatio = scrollSize.width / scrollSize.height

        var displaySize: CGSize
        if imageRatio > scrollRatio {
            displaySize = CGSize(width: scrollSize.width, height: scrollSize.width / imageRatio)
        } else {
            displaySize = CGSize(width: scrollSize.height * imageRatio, height: scrollSize.height)
        }

        imageView.frame = CGRect(origin: .zero, size: displaySize)
        scrollView.contentSize = displaySize

        
        imageView.translatesAutoresizingMaskIntoConstraints = true
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        scrollView.addSubview(imageView)

        // 注册手势
        context.coordinator.attachGestures(to: scrollView)

        return scrollView
    }
}
