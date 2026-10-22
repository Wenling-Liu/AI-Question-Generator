import SwiftUI

struct AddQuestionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @ObservedObject var questionBank: QuestionBank // 需要传入所属题库
    
    @State private var questionTitle: String = "" // 题目标题
    @State private var questionType: String = "单选" // 默认题型
    @State private var questionAnswer: String = "" // 答案
    @State private var questionOptions: [String] = ["", "", "", ""] // 选项数组

    private let questionTypes = ["单选", "多选", "判断", "填空", "简答"]
    private let questionTypeMapping: [String: String] = [
        "单选": "single",
        "多选": "multiple",
        "判断": "judge",
        "填空": "blanks",
        "简答": "short"
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("题目信息")) {
                    TextField("请输入题目标题", text: $questionTitle)
                        .autocapitalization(.none)
                        .font(.system(size: 18))
                    
                    Picker("题目类型", selection: $questionType) {
                        ForEach(questionTypes, id: \.self) { type in
                            Text(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                // 动态显示选项输入框（仅适用于单选和多选）
                if questionType == "单选" || questionType == "多选" {
                    Section(header: Text("选项")) {
                        ForEach(0..<questionOptions.count, id: \.self) { index in
                            TextField("选项 \(index + 1)", text: $questionOptions[index])
                        }
                        Button("添加选项") {
                            questionOptions.append("")
                        }
                        .foregroundColor(.blue)
                    }
                }
                
                Section(header: Text("答案")) {
                    if questionType == "填空" || questionType == "简答" {
                        TextEditor(text: $questionAnswer)
                            .frame(height: 100)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    } else {
                        TextField("请输入答案", text: $questionAnswer)
                            .autocapitalization(.none)
                    }
                }
            }
            .navigationTitle("添加题目")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        addQuestion()
                        dismiss()
                    }
                    .disabled(!isValidQuestion())
                }
            }
            .background(Color.blue.opacity(0.1))
        }
    }
    
    private func addQuestion() {
        // 创建新题目
        let newQuestion = Question(context: viewContext)
        newQuestion.id = UUID()
        newQuestion.content = questionTitle
        newQuestion.type = {
            switch questionType {
            case "单选": return "single"
            case "多选": return "multiple"
            case "判断": return "judge"
            case "填空": return "blanks"
            case "简答": return "short"
            default: return "unknown"
            }
        }()
        newQuestion.answer = questionAnswer

        // 如果是单选或多选题，将选项存储为字符串（用分隔符拼接）
        if questionType == "单选" || questionType == "多选" {
            newQuestion.options = questionOptions.joined(separator: ";")
        }

        // 确定题目序号
        let currentQuestions = questionBank.questions?.allObjects as? [Question] ?? []
        let nextNumber = (currentQuestions.map { $0.number }.max() ?? 0) + 1
        newQuestion.number = nextNumber

        // 将题目关联到所属题库
        newQuestion.bank = questionBank

        do {
            try viewContext.save() // 保存到 Core Data
            print("成功保存题目，序号为：\(nextNumber)")
        } catch {
            print("保存题目时发生错误：\(error)")
        }
    }
    
    private func isValidQuestion() -> Bool {
        // 标题和答案不能为空，单选/多选题需要至少有两个选项
        if questionTitle.isEmpty || questionAnswer.isEmpty {
            return false
        }
        if (questionType == "单选" || questionType == "多选") && questionOptions.filter({ !$0.isEmpty }).count < 2 {
            return false
        }
        return true
    }
}
