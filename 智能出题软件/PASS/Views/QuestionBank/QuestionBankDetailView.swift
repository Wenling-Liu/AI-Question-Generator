import SwiftUI
import CoreData

struct QuestionBankDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    let questionBank: QuestionBank
    @State private var showingExam = false
    @State private var showAnswers = true
    @State private var showingAddQuestion = false
    @State private var showingDeleteAlert = false
    @State private var questionToDelete: Question?
    @State private var showingExamResult = false
    @State private var showNoRecordAlert = false // 控制“暂无记录”弹窗
    @State private var examResult: ExamResult?
    
    private var questions: [Question] {
        (questionBank.questions?.allObjects as? [Question])?.sorted { ($0.number) < ($1.number) } ?? []
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部导航栏
            
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                
                Text(questionBank.name ?? "")
                    .font(.headline)
                    .padding(.leading, 8) // 添加左间距，拉近与返回按钮的距离
                
                Spacer()
                
                // 显示/隐藏答案按钮
                Button(action: { showAnswers.toggle() }) {
                    Image(systemName: showAnswers ? "eye.fill" : "eye.slash.fill")
                        .font(.title2)
                        .foregroundColor(showAnswers ? .blue : .gray)
                }
                
                Button(action: { showingAddQuestion = true }) {
                    Image(systemName: "plus")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                
                Button(action: {
                    showingExamResult = true
                }) {
                    Text("考试记录")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                .fullScreenCover(isPresented: $showingExamResult) {
                    ExamResultView(questionBank: questionBank)
                }
            }
            .padding()
            
            if questions.isEmpty {
                EmptyQuestionView(showingAddQuestionView: $showingAddQuestion)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(questions, id: \.self) { question in
                            QuestionCard(question: question, showAnswers: showAnswers)
                                .onLongPressGesture {
                                    questionToDelete = question
                                    showingDeleteAlert = true
                                }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                
                // 开始考试按钮
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
        }
        .background(Color.blue.opacity(0.1))
        .navigationBarHidden(true)
        .alert("删除题目", isPresented: $showingDeleteAlert) {
            Button("删除", role: .destructive) {
                if let question = questionToDelete {
                    deleteQuestion(question)
                }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("确定要删除这道题目吗？")
        }
        .fullScreenCover(isPresented: $showingExam) {
            ExamView(questionBank: questionBank)
        }
        .sheet(isPresented: $showingAddQuestion) {
            AddQuestionView(questionBank: questionBank)
        }
        .sheet(isPresented: $showingExamResult) {
            if let result = examResult {
                ExamResultView(questionBank: questionBank)
            }
        }
    }
    
    // 删除题目
    private func deleteQuestion(_ question: Question) {
        viewContext.delete(question)
        do {
            try viewContext.save()
        } catch {
            print("删除题目失败: \(error)")
        }
    }
    
    
    // 空题目提示视图
    struct EmptyQuestionView: View {
        @Binding var showingAddQuestionView: Bool
        
        var body: some View {
            Spacer()
            VStack {
                Image(systemName: "tray")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.gray)
                Text("此题库暂无题目")
                    .foregroundColor(.gray)
                    .font(.headline)
                    .padding(.top, 10)
            }
            Spacer()
        }
    }
    
    // 题目卡片组件
    struct QuestionCard: View {
        let question: Question
        let showAnswers: Bool
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                // 题型标签
                Text(getQuestionType(question.type ?? ""))
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
                
                // 题目内容容器
                VStack(alignment: .leading, spacing: 12) {
                    Text("\(question.number). \(question.content ?? "")")
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if showAnswers {
                        Divider().padding(.vertical, 8)
                        Text("答案：\(question.answer ?? "")")
                            .font(.body)
                            .foregroundColor(.green)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        if let analysis = question.analysis, !analysis.isEmpty {
                            Text("解析：\(analysis)")
                                .font(.body)
                                .foregroundColor(.gray)
                                .padding(.top, 4)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
        }
        
        private func getQuestionType(_ type: String) -> String {
            switch type.lowercased() {
            case "single": return "单选题"
            case "multiple": return "多选题"
            case "judge": return "判断题"
            case "blanks": return "填空题"
            case "short": return "简答题"
            default: return "未知题型"
            }
        }
    }
}
