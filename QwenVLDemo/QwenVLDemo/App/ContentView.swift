import SwiftUI
import PhotosUI

struct ContentView: View {
    @EnvironmentObject private var viewModel: QwenVLViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var selectedPhotoItem: PhotosPickerItem?
    @FocusState private var promptIsFocused: Bool

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                let padding = horizontalPadding(for: proxy.size.width)
                ScrollView {
                    VStack(spacing: sectionSpacing) {
                        photoSection(maxWidth: proxy.size.width - padding * 2)
                        promptSection
                        actionSection
                        outputSection
                    }
                    .padding(.horizontal, padding)
                    .padding(.vertical, 24)
                }
                .frame(maxWidth: .infinity)
                .navigationTitle("Qwen VL Demo")
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("閉じる") {
                            promptIsFocused = false
                        }
                    }
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .task {
            await viewModel.prepareModelIfNeeded()
        }
    }

    @ViewBuilder
    private func photoSection(maxWidth: CGFloat) -> some View {
        let effectiveWidth = max(maxWidth, 280)
        let containerHeight = adaptivePhotoHeight(for: effectiveWidth)

        VStack(alignment: .leading, spacing: 12) {
            Text("画像入力")
                .font(.headline)

            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [6]))
                    .foregroundStyle(.secondary)

                if let uiImage = viewModel.uiImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: effectiveWidth)
                        .frame(maxHeight: containerHeight - 24)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: horizontalSizeClass == .compact ? 38 : 48))
                            .foregroundColor(.secondary)
                        Text("カメラで撮影するか、フォトライブラリから選択してください")
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                            .font(horizontalSizeClass == .compact ? .subheadline : .body)
                    }
                    .padding()
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: containerHeight)

            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                Label("画像を選択 / 撮影", systemImage: "photo.on.rectangle.angled")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.accentColor)
            .onChange(of: selectedPhotoItem) { newItem in
                guard let newItem else { return }
                Task {
                    await viewModel.loadImage(from: newItem)
                }
            }
        }
    }

    private var promptSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("プロンプト")
                .font(.headline)
            TextEditor(text: $viewModel.prompt)
                .focused($promptIsFocused)
                .frame(minHeight: promptEditorMinHeight)
                .padding(12)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.secondary.opacity(0.25), lineWidth: 1)
                )
            Text("既定のプロンプトはいつでも編集できます。")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var actionSection: some View {
        VStack(spacing: 16) {
            Button {
                Task {
                    await viewModel.generateResponse()
                }
            } label: {
                if viewModel.isProcessing {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                } else {
                    Text("文章を生成")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isProcessing || viewModel.uiImage == nil || viewModel.prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            if let error = viewModel.errorMessage {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow)
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(12)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var outputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("生成結果")
                .font(.headline)
            if let generated = viewModel.generatedText {
                Text(generated)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else {
                Text("ここに生成結果が表示されます")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }

    private var sectionSpacing: CGFloat {
        horizontalSizeClass == .compact ? 20 : 24
    }

    private var promptEditorMinHeight: CGFloat {
        horizontalSizeClass == .compact ? 100 : 140
    }

    private func horizontalPadding(for width: CGFloat) -> CGFloat {
        width >= 768 ? 32 : 16
    }

    private func adaptivePhotoHeight(for width: CGFloat) -> CGFloat {
        let base = width * 0.62
        return min(max(base, 200), 360)
    }
}

#Preview {
    ContentView()
        .environmentObject(QwenVLViewModel(previewMode: true))
}
