import SwiftUI
import CoreData

struct ExamResultView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    let questionBank: QuestionBank
    @State private var examResult: ExamResult? // 存储最新考试记录
    @State private var loadingError: String?  // 存储加载错误
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部导航栏
            HStack {
                Button(action: { dismiss() }) {
                    HStack {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                            .foregroundColor(.blue)
                        Text("返回")
                            .font(.body)
                            .foregroundColor(.blue)
                    }
                }
                
                Spacer()
                
                Text("考试结果")
                    .font(.headline)
                    .foregroundColor(.black)
                
                Spacer()
                
                Spacer().frame(width: 60) // 占位
            }
            .padding()
            
            
            Spacer()
            
            // 内容部分
            if let result = examResult {
                // 成绩统计部分
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                            .frame(width: 150, height: 150)
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(result.correctCount) / CGFloat(result.correctCount + result.wrongCount + result.unansweredCount))
                            .stroke(Color.green, lineWidth: 20)
                            .frame(width: 150, height: 150)
                            .rotationEffect(.degrees(-90))
                        
                        VStack {
                            Text("\(Int(result.correctCount * 100 / (result.correctCount + result.wrongCount + result.unansweredCount)))%")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.green)
                            Text("正确率")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    HStack(spacing: 30) {
                        StatItem(title: "正确", count: Int(result.correctCount), color: .green)
                        StatItem(title: "错误", count: Int(result.wrongCount), color: .red)
                        StatItem(title: "未答", count: Int(result.unansweredCount), color: .gray)
                    }
                }
                .padding()
            } else if let error = loadingError {
                // 错误提示部分
                VStack {
                    Text("加载考试记录失败")
                        .font(.headline)
                        .foregroundColor(.red)
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding()
            } else {
                // 无考试记录提示部分
                VStack {
                    Text("暂无考试记录")
                        .font(.title3)
                        .foregroundColor(.gray)
                        .padding()
                }
            }
            
            Spacer()
        }
        .background(Color.blue.opacity(0.1).ignoresSafeArea()) // 浅蓝色背景
        .onAppear(perform: fetchLatestExamResult) // 页面加载时获取考试记录
        .frame(maxWidth: .infinity, maxHeight: .infinity) // 确保内容居中
    }
    
    // 从 Core Data 获取最新考试记录
    private func fetchLatestExamResult() {
        let request = NSFetchRequest<ExamResult>(entityName: "ExamResult")
        request.predicate = NSPredicate(format: "questionBank == %@", questionBank)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ExamResult.endTime, ascending: false)]
        request.fetchLimit = 1
        
        do {
            let results = try viewContext.fetch(request)
            if let latestResult = results.first {
                examResult = latestResult
            } else {
                loadingError = "暂无考试记录"
            }
        } catch {
            loadingError = error.localizedDescription
        }
    }
}

// 统计项组件
struct StatItem: View {
    let title: String
    let count: Int
    let color: Color
    
    var body: some View {
        VStack {
            Text("\(count)")
                .font(.title2)
                .foregroundColor(color)
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }
}
