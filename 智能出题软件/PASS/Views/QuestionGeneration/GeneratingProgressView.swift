import SwiftUI
import CoreData

struct GeneratingProgressView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: QuestionGenerateViewModel
    @State private var isLoading = true
    @State private var isLoadFailed = false
    @State private var errorMessage: String? // 错误信息
    @State private var showingExam = false

    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    LoadingView(isLoadFailed: $isLoadFailed, errorMessage: $errorMessage, onReturn: {
                        dismiss()
                    })
                } else {
                    if viewModel.generatedQuestions.isEmpty {
                        EmptyStateView(onReturn: {
                            dismiss()
                        })
                    } else {
                        LoadedView(
                            viewModel: viewModel,
                            dismissAction: {
                                dismiss()
                                viewModel.clearAll()
                            },
                            showingExam: $showingExam
                        )
                        .sheet(isPresented: $showingExam) {
                            if let questionBank = fetchSavedQuestionBank(named: viewModel.questionBankName) {
                                ExamView(questionBank: questionBank)
                                    .environment(\.managedObjectContext, viewContext)
                            }
                        }
                    }
                }
            }
            .onAppear {
                handleLoading()
            }
        }
    }

    private func handleLoading() {
        guard isLoading else { return }

        Task {
            do {
                // 检查参数有效性
                guard isRequestValid() else {
                    throw NSError(domain: "Invalid Request", code: -1, userInfo: [
                        NSLocalizedDescriptionKey: "题目数量为零，请返回并设置题目数量。"
                    ])
                }

                // 异步加载题目
                try await viewModel.generateQuestions()
                await MainActor.run {
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoadFailed = true
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }

    private func isRequestValid() -> Bool {
        return viewModel.totalQuestions > 0
    }

    private func fetchSavedQuestionBank(named name: String) -> QuestionBank? {
        let request: NSFetchRequest<QuestionBank> = QuestionBank.fetchRequest()
        request.predicate = NSPredicate(format: "name == %@", name)
        request.fetchLimit = 1
        do {
            return try viewContext.fetch(request).first
        } catch {
            print("无法找到题库: \(error.localizedDescription)")
            return nil
        }
    }
}

// 修改加载页面视图
struct LoadingView: View {
    @Binding var isLoadFailed: Bool
    @Binding var errorMessage: String?
    let onReturn: () -> Void

    var body: some View {
        VStack {
            if isLoadFailed {
                Text(errorMessage ?? "生成失败，请稍后重试")
                    .font(.subheadline)
                    .foregroundColor(.red)
                    .padding()

                Button(action: onReturn) {
                    Text("返回")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(8)
                }
            } else {
                ProgressView("正在生成题目，请稍等...")
                    .padding()
                    .font(.headline)
                    .foregroundColor(.gray)
            }
        }
    }
}

// 题目卡片视图
struct GeneratingQuestionCardView: View {
    let question: AIService.Question

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(getQuestionType(question.type))
                .font(.subheadline)
                .foregroundColor(.blue)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(4)

            Text("\(question.number). \(question.content)")
                .font(.body)

            if let options = question.options {
                ForEach(options.indices, id: \.self) { index in
                    Text("\(Character(UnicodeScalar(65 + index)!)). \(options[index])")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }

            Text("答案：\(question.answer)")
                .font(.subheadline)
                .foregroundColor(.green)

            if let analysis = question.analysis {
                Text("解析：\(analysis)")
                    .font(.footnote)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 1)
    }

    private func getQuestionType(_ type: String) -> String {
        switch type.lowercased() {
        case "single": return "单选题"
        case "multiple": return "多选题"
        case "judge": return "判断题"
        case "blanks": return "填空题"
        case "short": return "简答题"
        default: return "简答题"
        }
    }
}
// 导航栏视图
struct GeneratingTopNavigationView: View {
    let questionBankName: String
    let dismissAction: () -> Void

    var body: some View {
        HStack {
            Button(action: dismissAction) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.blue)
            }

            Spacer()

            Text(questionBankName)
                .font(.headline)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding()
        .background(Color.white)
    }
}

// 加载完成页面
struct LoadedView: View {
    @ObservedObject var viewModel: QuestionGenerateViewModel
    let dismissAction: () -> Void
    @Binding var showingExam: Bool

    var body: some View {
        VStack(spacing: 0) {
            GeneratingTopNavigationView(
                questionBankName: viewModel.questionBankName,
                dismissAction: dismissAction
            )

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(viewModel.generatedQuestions, id: \.self) { question in
                        GeneratingQuestionCardView(question: question)
                    }
                }
                .padding()
            }

            Button(action: {
                showingExam = true
            }) {
                Text("开始考试")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color.blue.opacity(0.1))
    }
}

// 空状态页面
struct EmptyStateView: View {
    let onReturn: () -> Void

    var body: some View {
        VStack {
            Text("未生成任何题目，请稍后重试")
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding()

            Button(action: onReturn) {
                Text("返回")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
