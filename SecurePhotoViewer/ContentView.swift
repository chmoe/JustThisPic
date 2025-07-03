import SwiftUI

struct ContentView: View {
    @State private var imageFiles: [ImageFile] = []
    @State private var selectedImageFile: ImageFile? = nil

    @State private var isSelecting = false
    @State private var selectedFiles = Set<ImageFile>()
    @State private var showDeleteAlert = false
    @State private var pendingDeleteFile: ImageFile? = nil

    // 缩放相关
    @State private var baseScale: CGFloat = 1.0
    @GestureState private var pinchScale: CGFloat = 1.0      // 手势中实时缩放值
    @State private var disableTap: Bool = false  // 临时禁用点击识别

    var effectiveScale: CGFloat {
        min(max(baseScale * pinchScale, 0.5), 2.5)
    }

    var body: some View {
        NavigationView {
            GeometryReader { geo in
                let screenWidth = geo.size.width
                let columnWidth = max(80, min(180, 100 * effectiveScale))
                let columnCount = max(2, Int(screenWidth / columnWidth))
                let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: columnCount)

                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(imageFiles) { imageFile in
                            let url = imageFile.url
                            ThumbnailImageView(
                                imageFile: imageFile,
                                size: columnWidth,
                                isSelected: selectedFiles.contains(imageFile),
                                isSelecting: isSelecting,
                                onTap: {
                                    if isSelecting {
                                        if selectedFiles.contains(imageFile) {
                                            selectedFiles.remove(imageFile)
                                        } else {
                                            selectedFiles.insert(imageFile)
                                        }
                                    } else {
                                        if disableTap { return }  // 防止缩放误触点击
                                        if !FileManager.default.fileExists(atPath: url.path) {
                                            print("❌ 文件不存在，忽略点击")
                                            return
                                        }
                                        DispatchQueue.main.async {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                selectedImageFile = imageFile
                                            }
                                        }
                                    }
                                },
                                onLongPress: {
                                    if isSelecting { return }
                                    pendingDeleteFile = imageFile
                                    showDeleteAlert = true
                                }
                            )
                            .frame(height: columnWidth)
                        }
                    }
                    .padding(.horizontal, 12)
                    .simultaneousGesture(
                        MagnificationGesture()
                            .updating($pinchScale) { value, state, _ in
                                state = value
                            }
                            .onEnded { value in
                                let newScale = baseScale * value
                                let snapped = snapScale(for: newScale, in: geo.size.width)
                                
                                disableTap = true
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                                    baseScale = snapped
                                }
                                
                                // 0.2秒后重新允许点击
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    disableTap = false
                                }
                            }
                    )

                    .animation(.interactiveSpring(response: 0.25, dampingFraction: 0.75), value: effectiveScale)

                    if imageFiles.isEmpty {
                        Text("暂无照片")
                            .foregroundColor(.gray)
                            .font(.title3)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .navigationTitle("已导入照片")
                .navigationBarItems(
                    leading: Button(action: {
                        isSelecting.toggle()
                        selectedFiles.removeAll()
                    }) {
                        Text(isSelecting ? "取消" : "选择")
                    },
                    trailing: HStack {
                        Button(action: { refreshImages() }) {
                            Image(systemName: "arrow.clockwise")
                        }
                        if isSelecting && !selectedFiles.isEmpty {
                            Button(action: { showDeleteAlert = true }) {
                                Image(systemName: "trash").foregroundColor(.red)
                            }
                        }
                    }
                )
                .onAppear { refreshImages() }
                .fullScreenCover(item: $selectedImageFile) { file in
                    FullScreenImageView(
                        imageURLs: imageFiles.map { $0.url },
                        selectedURL: file.url,
                        isPresented: Binding(
                            get: { selectedImageFile != nil },
                            set: { if !$0 { selectedImageFile = nil } }
                        )
                    )
                }
                .alert(isPresented: $showDeleteAlert) {
                    if let file = pendingDeleteFile {
                        return Alert(
                            title: Text("删除照片"),
                            message: Text("确定要删除这张照片吗？"),
                            primaryButton: .destructive(Text("删除")) {
                                deleteImages(files: [file])
                                pendingDeleteFile = nil
                                isSelecting = false
                            },
                            secondaryButton: .cancel {
                                pendingDeleteFile = nil
                            }
                        )
                    } else {
                        return Alert(
                            title: Text("删除选中照片"),
                            message: Text("确定要删除 \(selectedFiles.count) 张照片吗？"),
                            primaryButton: .destructive(Text("删除")) {
                                deleteImages(files: Array(selectedFiles))
                                selectedFiles.removeAll()
                                isSelecting = false
                            },
                            secondaryButton: .cancel()
                        )
                    }
                }
            }
        }
    }

    /// 缩放结束后，吸附到最近列数，并计算缩放比例
    func snapScale(for rawScale: CGFloat, in screenWidth: CGFloat) -> CGFloat {
        let clamped = min(max(rawScale, 0.5), 2.5)
        
        let baseWidth: CGFloat = 100
        let spacing: CGFloat = 12
        let totalWidth = screenWidth - 24  // 减去左右 padding
        
        // 当前列数估计
        let estimatedColumns = totalWidth / (baseWidth * clamped)
        let snappedColumns = max(2, Int(round(estimatedColumns)))

        // 重新计算：基于列数和 spacing，精确分配图片宽度
        let totalSpacing = spacing * CGFloat(snappedColumns - 1)
        let availableWidth = totalWidth - totalSpacing
        let finalWidthPerItem = availableWidth / CGFloat(snappedColumns)

        // 推导出新的 scale
        let finalScale = finalWidthPerItem / baseWidth
        return min(max(finalScale, 0.5), 2.5)
    }


    func deleteImages(files: [ImageFile]) {
        for file in files {
            do { try FileManager.default.removeItem(at: file.url) }
            catch { print("❌ 删除失败：\(file.url.path) - \(error)") }
        }
        refreshImages()
    }

    func refreshImages() {
        imageFiles = loadImageURLsFromSharedContainer().map { ImageFile(url: $0) }
    }
}

struct ImageFile: Identifiable, Hashable {
    let url: URL
    var id: String { url.path }
}
