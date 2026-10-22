import SwiftUI

struct AnswerSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingResult = false
    @State private var examResult: ExamResult?
    let questionBank: QuestionBank
    let questions: [Question]
    let userAnswers: [Int?]
    let currentIndex: Int
    let isSubmitted: Bool
    let onQuestionSelect: (Int) -> Void
    let onSubmit: () -> ExamResult?
    
    var body: some View {
        VStack(spacing: 16) {
            // 顶部标题
            HStack {
                Text("答题卡")
                    .font(.headline)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.gray)
                }
            }
            .padding()
            
            // 答题状态说明
            HStack(spacing: 20) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 16, height: 16)
                    Text("已答")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                HStack(spacing: 8) {
                    Circle()
                        .stroke(Color.gray, lineWidth: 1)
                        .frame(width: 16, height: 16)
                    Text("未答")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            .padding(.bottom)
            
            // 答题格子网格
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 5), spacing: 12) {
                ForEach(questions.indices, id: \.self) { index in
                    Button(action: { onQuestionSelect(index) }) {
                        ZStack {
                            Circle()
                                .fill(userAnswers[index] != nil ? Color.green : Color.white)
                                .overlay(
                                    Circle()
                                        .stroke(Color.gray, lineWidth: userAnswers[index] != nil ? 0 : 1)
                                )
                            
                            Text("\(index + 1)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(userAnswers[index] != nil ? .white : .black)
                        }
                        .frame(width: 40, height: 40)
                    }
                }
            }
            .padding()
            
            Spacer()
            
            // 交卷按钮
            Button(action: {
                if let result = onSubmit() {
                    examResult = result
                    showingResult = true
                }
            }) {
                Text("交卷")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
            }
            .padding(.horizontal)
            .padding(.bottom)
            .fullScreenCover(isPresented: $showingResult) {
                if examResult != nil {
                    ExamResultView(questionBank: questionBank)
                }
            }
        }
    }
}


