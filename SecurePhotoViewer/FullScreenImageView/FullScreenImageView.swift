import SwiftUI

struct FullScreenImageView: View {
    let imageURLs: [URL]
    @Binding var isPresented: Bool
    @State private var selectedIndex: Int
    @State private var resetToken = UUID()  // 每次页面变化时更换，触发缩放重置
    
    @State private var showUI = true
    @State private var backgroundColor = Color.white

    init(imageURLs: [URL], selectedURL: URL, isPresented: Binding<Bool>) {
        self.imageURLs = imageURLs
        self._isPresented = isPresented
        self._selectedIndex = State(initialValue: imageURLs.firstIndex(of: selectedURL) ?? 0)
    }

    var body: some View {
        ZStack {
//            Color.black.edgesIgnoringSafeArea(.all)
            backgroundColor.edgesIgnoringSafeArea(.all)
            if !imageURLs.isEmpty {
                TabView(selection: $selectedIndex) {
                    ForEach(imageURLs.indices, id: \.self) { index in
                        let url = imageURLs[index]
                        if let image = loadCachedImage(for: url) {
                            ZoomableScrollImageView(
                                image: image,
                                resetTrigger: resetToken,
                                onSwipeDownToDismiss: {
                                    isPresented = false
                                },
                                onSingleTap: {
                                    // ✅ 单击切换 UI 和背景色
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        showUI.toggle()
                                        backgroundColor = showUI ? Color(.systemBackground) : .black
                                    }
                                }
                            )
                            .ignoresSafeArea() // 填满单页
                            .tag(index)
                        } else {
                            Text("⚠️ 加载失败")
                                .foregroundColor(.red)
                                .tag(index)
                        }
                    }
                }
//                .contentShape(Rectangle())
//                .onTapGesture {
//                    withAnimation(.easeInOut(duration: 0.2)) {
//                        showUI.toggle()
//                        backgroundColor = showUI ? Color(.systemBackground) : .black
//                    }
//                }  // ❌ 移除这一段，交给 ZoomableScrollImageView 内部处理

                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                .ignoresSafeArea(.all, edges: .all)
                .onChangeCompatible(of: selectedIndex) {
                    resetToken = UUID()
                }
            }

            if showUI {
                VStack {
                    // 顶部标题栏
                    HStack {
                        Button(action: {
                            isPresented = false
                        }) {
                            Image(systemName: "chevron.down.circle.fill")
                                .resizable()
                                .frame(width: 28, height: 28)
                                .foregroundColor(.primary)
                                .padding(.leading, 16)
                        }

                        Spacer()

                        Text("\(selectedIndex + 1) / \(imageURLs.count)")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .padding(.trailing, 16)

                    }
                    .padding(.top, 50)
                    .padding(.bottom, 8)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)

                    Spacer()
                    
                    // 保留底部菜单栏
                    HStack(spacing: 32) {
                        Button(action: {
                            print("🔖 标记")
                        }) {
                            Image(systemName: "bookmark")
                                .font(.system(size: 24))
                        }

                        Button(action: {
                            print("📤 分享")
                        }) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 24))
                        }

                        Button(action: {
                            print("🗑️ 删除")
                        }) {
                            Image(systemName: "trash")
                                .font(.system(size: 24))
                                .foregroundColor(.red)
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.bottom, 40)
                    .transition(.move(edge: .bottom))
                    .animation(.easeInOut(duration: 0.2), value: showUI)
                }
            }

        }
    }
}

struct OnChangeCompatibleModifier<Value: Equatable>: ViewModifier {
    let value: Value
    let action: () -> Void

    func body(content: Content) -> some View {
        if #available(iOS 17, *) {
            content.onChange(of: value, action)
        } else {
            content.onChange(of: value) { _ in
                action()
            }
        }
    }
}
extension View {
    func onChangeCompatible<Value: Equatable>(of value: Value, perform action: @escaping () -> Void) -> some View {
        self.modifier(OnChangeCompatibleModifier(value: value, action: action))
    }
}
func loadCachedImage(for url: URL) -> UIImage? {
    if let cached = ImageCache.shared.image(for: url) {
        return cached
    } else if let image = UIImage(contentsOfFile: url.path) {
        ImageCache.shared.setImage(image, for: url)
        return image
    }
    return nil
}
