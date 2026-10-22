import SwiftUI

struct InputAndActionView: View {
    @ObservedObject var viewModel: QuestionGenerateViewModel
    @Binding var showingDocumentPicker: Bool
    @Binding var requirement: String
    @Binding var selectedPDFURL: URL?
    let onGenerate: () -> Void

    // 判断按钮是否可用
    private var canGenerate: Bool {
        totalQuestionCount > 0 && !viewModel.isGenerating
    }

    // 计算题目总数量
    private var totalQuestionCount: Int {
        viewModel.questionCounts.compactMap { Int($0) }.reduce(0, +)
    }

    var body: some View {
        VStack(spacing: 20) {
            // 输入框部分
            ZStack(alignment: .topLeading) {
                TextEditor(text: $requirement)
                    .frame(height: 120)
                    .padding(12)
                    .background(Color.white)
                    .cornerRadius(12)

                if requirement.isEmpty {
                    Text("老师划重点了吗？快告诉我...")
                        .foregroundColor(.gray)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                        .allowsHitTesting(false)
                }
            }

            // 按钮部分
            HStack(spacing: 20) {
                // 导入 PDF 按钮
                Button(action: {
                    showingDocumentPicker = true
                }) {
                    HStack {
                        Image(systemName: "doc.text")
                        Text("导入PDF文档")
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.white)
                    .cornerRadius(8)
                }

                Spacer()

                // 生成按钮
                Button(action: {
                    if viewModel.isGenerating { return } // 防止重复点击
                    viewModel.isGenerating = true
                    onGenerate() // 调用生成逻辑
                }) {
                    Text( "生成")
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 10)
                        .background(canGenerate ? Color.blue : Color.gray)
                        .cornerRadius(8)
                }
                .disabled(!canGenerate) // 禁用条件
            }
        }
        .padding()
        .background(Color.blue.opacity(0.2))
        .cornerRadius(12)
    }
}
