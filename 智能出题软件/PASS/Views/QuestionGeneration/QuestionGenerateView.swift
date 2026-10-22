import SwiftUI

struct QuestionGenerateView: View {
    @StateObject private var viewModel = QuestionGenerateViewModel()
    @State private var showingDocumentPicker = false
    @Environment(\.managedObjectContext) private var viewContext

    private let questionTypes = [
        ("单选题", "checkmark.circle", Color.blue),
        ("多选题", "checkmark.square", Color.pink),
        ("判断题", "questionmark.circle", Color.purple),
        ("填空题", "pencil", Color.green),
        ("简答题", "text.bubble", Color.cyan)
    ]

    var body: some View {
        VStack(spacing: 20) {
            // 问题类型选择视图
            QuestionTypeSelectionView(
                questionTypes: questionTypes,
                questionCounts: $viewModel.questionCounts
            )

            // 文本输入和操作按钮
            InputAndActionView(
                viewModel: viewModel,
                showingDocumentPicker: $showingDocumentPicker,
                requirement: $viewModel.requirement,
                selectedPDFURL: $viewModel.selectedPDFURL
            ) {
                // 使用 Task 包装异步调用
                Task {
                    await startQuestionGeneration()
                }
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .sheet(isPresented: $showingDocumentPicker) {
            DocumentPicker { url in
                viewModel.handleSelectedPDF(url) // 传递闭包
            }
        }
        .sheet(isPresented: $viewModel.isGenerating) { // 用 $ 绑定
            GeneratingProgressView(viewModel: viewModel)
                .environment(\.managedObjectContext, viewContext) // 传递 Core Data 上下文
        }
    }

    /// 启动题目生成逻辑
    private func startQuestionGeneration() async {
        if viewModel.isGenerating {
            return
        }
        viewModel.isGenerating = true
        await viewModel.generateQuestions()
    }
}

#Preview {
    QuestionGenerateView()
}
