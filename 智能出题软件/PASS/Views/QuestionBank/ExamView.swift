import SwiftUI
import CoreData

struct ExamView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var currentQuestionIndex = 0
    @State private var userAnswers: [Int?] // 用户选择的答案索引
    @State private var textAnswers: [String] // 用户填空题和简答题答案
    @State private var startTime = Date() // 考试开始时间
    @State private var showingAnswerSheet = false // 是否显示答题卡
    @State private var dragOffset = CGSize.zero // 拖动偏移量
    @State private var result: ExamResult? // 保存结果数据
    @State private var showingResult = false // 用于控制是否显示结果页面
    
    let questionBank: QuestionBank
    private var questions: [Question] {
        (questionBank.questions?.allObjects as? [Question])?.sorted { $0.number < $1.number } ?? []
    }
    
    init(questionBank: QuestionBank) {
        self.questionBank = questionBank
        _userAnswers = State(initialValue: Array(repeating: nil, count: questionBank.questions?.count ?? 0))
        _textAnswers = State(initialValue: Array(repeating: "", count: questionBank.questions?.count ?? 0))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            topNavigationBar
            
            if questions.isEmpty {
                EmptyQuestionView(showingAddQuestionView: .constant(false))
            } else {
                questionContent
                
                navigationButtons
            }
        }
        .background(Color.blue.opacity(0.1))
        .navigationBarHidden(true)
        .sheet(isPresented: $showingAnswerSheet) {
            AnswerSheetView(
                questionBank: questionBank, questions: questions,
                userAnswers: userAnswers,
                currentIndex: currentQuestionIndex,
                isSubmitted: false,
                onQuestionSelect: { index in
                    currentQuestionIndex = index
                    showingAnswerSheet = false
                },
                onSubmit: saveExamResult
            )
        }
    }
    
    // 顶部导航栏
    private var topNavigationBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            Text("\(currentQuestionIndex + 1) / \(questions.count)")
                .font(.headline)
            
            Spacer()
            
            Button(action: { showingAnswerSheet = true }) {
                Image(systemName: "list.bullet")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
        }
        .padding()
    }
    
    // 题目内容
    private var questionContent: some View {
        ScrollView {
            let question = questions[currentQuestionIndex]
            
            VStack(alignment: .leading, spacing: 16) {
                Text(getQuestionType(question.type ?? ""))
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
                
                Text("\(currentQuestionIndex + 1). \(question.content ?? "")")
                    .font(.title3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                questionOptions(question: question)
            }
            .padding()
        }
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    dragOffset = gesture.translation
                }
                .onEnded { gesture in
                    handleSwipeGesture(translation: gesture.translation)
                }
        )
    }
    
    // 选项内容
    private func questionOptions(question: Question) -> some View {
        Group {
            switch question.type?.lowercased() {
            case "judge":
                judgeQuestionView()
            case "short", "blanks":
                shortAnswerView(index: currentQuestionIndex)
            default: // 包括单选题和未知题型
                if let optionsString = question.options {
                    let cleanOptions = optionsString
                        .components(separatedBy: ";")
                        .map { removeOptionPrefix($0) }
                    multipleChoiceView(options: cleanOptions)
                } else {
                    // 如果没有选项，提供文本输入框
                    shortAnswerView(index: currentQuestionIndex)
                }
            }
        }
    }
    
    // 判断题视图
    private func judgeQuestionView() -> some View {
        HStack(spacing: 20) {
            ForEach(["正确", "错误"], id: \.self) { option in
                Button(action: {
                    userAnswers[currentQuestionIndex] = option == "正确" ? 1 : 0
                }) {
                    Text(option)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(userAnswers[currentQuestionIndex] == (option == "正确" ? 1 : 0) ?
                                    Color.blue.opacity(0.1) : Color.white)
                        .foregroundColor(.primary)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(userAnswers[currentQuestionIndex] == (option == "正确" ? 1 : 0) ?
                                       Color.blue : Color.gray, lineWidth: 1)
                        )
                }
            }
        }
        .padding(.horizontal)
    }
    
    // 简答题和填空题视图
    private func shortAnswerView(index: Int) -> some View {
        TextEditor(text: Binding(
            get: { textAnswers[index] },
            set: { textAnswers[index] = $0 }
        ))
        .frame(height: 150)
        .padding(8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
    
    // 选择题视图
    private func multipleChoiceView(options: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(options.indices, id: \.self) { index in
                Button(action: {
                    userAnswers[currentQuestionIndex] = index
                }) {
                    HStack {
                        Text("\(Character(UnicodeScalar(65 + index)!))")
                            .font(.headline)
                            .frame(width: 30, height: 30)
                            .background(Circle().stroke(userAnswers[currentQuestionIndex] == index ? Color.blue : Color.gray, lineWidth: 1))
                        
                        Text(options[index])
                            .font(.body)
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    .padding()
                    .background(userAnswers[currentQuestionIndex] == index ? Color.blue.opacity(0.1) : Color.white)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(userAnswers[currentQuestionIndex] == index ? Color.blue : Color.gray, lineWidth: 1)
                    )
                }
            }
        }
        .padding(.horizontal)
    }
    
    private func removeOptionPrefix(_ text: String) -> String {
        let prefixes = ["A.", "B.", "C.", "D.", "A、", "B、", "C、", "D、"]
        var result = text.trimmingCharacters(in: .whitespaces)
        for prefix in prefixes {
            if result.hasPrefix(prefix) {
                result = String(result.dropFirst(prefix.count)).trimmingCharacters(in: .whitespaces)
                break
            }
        }
        return result
    }
    
    // 底部导航按钮
    private var navigationButtons: some View {
        HStack {
            Button(action: {
                if currentQuestionIndex < questions.count - 1 {
                    currentQuestionIndex += 1
                } else {
                    showingAnswerSheet = true
                }
            }) {
                Text(currentQuestionIndex < questions.count - 1 ? "下一题" : "提交")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
    }
    
    // 处理滑动手势
    private func handleSwipeGesture(translation: CGSize) {
        if translation.width > 100 && currentQuestionIndex > 0 {
            withAnimation {
                currentQuestionIndex -= 1
            }
        } else if translation.width < -100 && currentQuestionIndex < questions.count - 1 {
            withAnimation {
                currentQuestionIndex += 1
            }
        }
        dragOffset = .zero
    }
    
    // 获取题型名称
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
    
    private func saveExamResult() -> ExamResult? {
        print("开始保存考试结果")
        let endTime = Date()
        let duration = Int32(endTime.timeIntervalSince(startTime))
        
        // 删除之前的考试记录，确保数据库只有最新记录
        let fetchRequest: NSFetchRequest<ExamResult> = ExamResult.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "questionBank == %@", questionBank)
        
        do {
            let results = try viewContext.fetch(fetchRequest)
            for oldResult in results {
                viewContext.delete(oldResult)
            }
        } catch {
            print("删除旧的考试记录失败: \(error)")
        }
        
        // 保存新的考试记录
        let result = ExamResult(context: viewContext)
        result.id = UUID()
        result.startTime = startTime
        result.endTime = endTime
        result.duration = duration
        result.correctCount = calculateCorrectCount()
        result.wrongCount = calculateWrongCount()
        result.unansweredCount = calculateUnansweredCount()
        result.questionBank = questionBank
        
        // 保存用户答案为字符串
        let answersString = userAnswers.map { String($0 ?? -1) }.joined(separator: ",")
        result.userAnswers = answersString
        
        do {
            try viewContext.save()
            print("考试结果保存成功")
            return result
        } catch {
            print("保存考试结果失败: \(error)")
            return nil
        }
    }
    
    // 添加计算答题统计的辅助方法
    private func calculateCorrectCount() -> Int16 {
        var count: Int16 = 0
        for (index, answer) in userAnswers.enumerated() {
            if let userAnswer = answer,
               let correctAnswer = questions[index].answer?.first?.wholeNumberValue,
               userAnswer == correctAnswer {
                count += 1
            }
        }
        return count
    }
    
    private func calculateWrongCount() -> Int16 {
        var count: Int16 = 0
        for (index, answer) in userAnswers.enumerated() {
            if let userAnswer = answer,
               let correctAnswer = questions[index].answer?.first?.wholeNumberValue,
               userAnswer != correctAnswer {
                count += 1
            }
        }
        return count
    }
    
    private func calculateUnansweredCount() -> Int16 {
        Int16(userAnswers.filter { $0 == nil }.count)
    }
}


struct EmptyQuestionView: View {
    @Binding var showingAddQuestionView: Bool // 绑定参数
    
    var body: some View {
        VStack {
            Spacer()
            Image(systemName: "exclamationmark.triangle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.gray)

            Text("题库中没有题目")
                .font(.title2)
                .foregroundColor(.gray)
                .padding(.top, 10)
            
            Button(action: {
                showingAddQuestionView = true // 设置显示添加题目的状态
            }) {
                Text("添加题目")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding(.horizontal, 40)
            Spacer()
        }
    }
}
