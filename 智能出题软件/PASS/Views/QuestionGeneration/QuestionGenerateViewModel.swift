import Foundation
import CoreData

@MainActor
class QuestionGenerateViewModel: ObservableObject, Sendable {
    @Published var aiResponse: String? = nil
    @Published var questionCounts = Array(repeating: "0", count: 5)
    @Published var requirement = ""
    @Published var selectedPDFURL: URL?
    @Published var isGenerating = false
    @Published var isGenerationCompleted = false
    @Published var generatedQuestions: [AIService.Question] = []
    @Published var error: String?
    @Published var questionBankName: String = "新题库"
    @Published var totalQuestions: Int = 0
    
    private let aiService = AIService.shared
    private let colors: [String] = ["orange", "green", "pink", "blue", "purple", "red"]

    // MARK: - 清空状态
    func clearAll() {
        isGenerating = false
        isGenerationCompleted = false
        generatedQuestions = []
        requirement = ""
        selectedPDFURL = nil
        aiResponse = nil
        questionCounts = Array(repeating: "0", count: 5)
    }
    
    @MainActor
    func handleSelectedPDF(_ url: URL?) {
        selectedPDFURL = url
        if let url = url {
            print("用户选择了 PDF 文件: \(url.lastPathComponent)")
        } else {
            print("用户取消了 PDF 文件选择")
        }
    }

    @MainActor
    func generateQuestions() async {
        guard !isGenerating else { return }
        isGenerating = true
        
        let params = AIService.QuestionGenerationParams(
            content: requirement,
            pdfContent: nil,
            singleChoiceCount: Int(questionCounts[0]) ?? 0,
            multipleChoiceCount: Int(questionCounts[1]) ?? 0,
            judgementCount: Int(questionCounts[2]) ?? 0,
            fillBlankCount: Int(questionCounts[3]) ?? 0,
            shortAnswerCount: Int(questionCounts[4]) ?? 0
        )
        
        totalQuestions = params.singleChoiceCount + params.multipleChoiceCount +
        params.judgementCount + params.fillBlankCount + params.shortAnswerCount
        
        do {
            defer {
                self.isGenerating = false
            }
            let result = try await aiService.generateQuestions(params: params)
            self.generatedQuestions = result.questions
            self.aiResponse = result.rawResponse
            saveGeneratedQuestionsToDatabase(result.questions)
            self.isGenerationCompleted = true
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    private func saveGeneratedQuestionsToDatabase(_ questions: [AIService.Question]) {
        let context = PersistenceController.shared.container.viewContext
        
        questionBankName = generateUniqueQuestionBankName(context: context)
        
        let questionBank = QuestionBank(context: context)
        questionBank.name = questionBankName
        questionBank.createdAt = Date()
        questionBank.color = assignColorToBank(questionBank)
        
        for (index, question) in questions.enumerated() {
            let newQuestion = Question(context: context)
            newQuestion.content = question.content
            newQuestion.answer = question.answer
            newQuestion.analysis = question.analysis
            newQuestion.options = question.options?.joined(separator: ";")
            newQuestion.type = question.type
            newQuestion.number = Int16(index + 1)
            newQuestion.bank = questionBank
        }
        
        do {
            try context.save()
        } catch {
            print("保存失败: \(error.localizedDescription)")
        }
    }

    private func generateUniqueQuestionBankName(context: NSManagedObjectContext) -> String {
        let baseName = generateQuestionBankName()
        var uniqueName = baseName
        var suffix = 1
        
        let fetchRequest: NSFetchRequest<QuestionBank> = QuestionBank.fetchRequest()
        
        while true {
            fetchRequest.predicate = NSPredicate(format: "name == %@", uniqueName)
            if (try? context.fetch(fetchRequest).isEmpty) == true {
                break
            }
            suffix += 1
            uniqueName = "\(baseName)(\(suffix))"
        }
        
        return uniqueName
    }
    
    func generateQuestionBankName() -> String {
        if let pdfURL = selectedPDFURL {
            return pdfURL.lastPathComponent.replacingOccurrences(of: ".pdf", with: "")
        } else if !requirement.isEmpty {
            return String(requirement.prefix(10))
        } else {
            return "新题库"
        }
    }
    
    private func assignColorToBank(_ bank: QuestionBank) -> String {
        guard let id = bank.id else { return colors.first! }
        let index = abs(id.hashValue) % colors.count
        return colors[index]
    }
}
