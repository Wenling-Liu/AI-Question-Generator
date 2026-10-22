
import CoreData
import Foundation

class StorageService {
    static let shared = StorageService()
    
    private var viewContext: NSManagedObjectContext {
        PersistenceController.shared.container.viewContext
    }
    
    // 创建题库
    func createQuestionBank(title: String, questions: [Question], createdAt: Date) async {
        let bank = QuestionBank(context: viewContext)
        bank.id = UUID()
        bank.name = title
        bank.createdAt = createdAt
        
        for question in questions {
            let entity = QuestionEntity(context: viewContext)
            entity.id = question.id
            entity.number = Int16(question.number)
            entity.type = question.type.rawValue
            entity.content = question.content
            entity.options = question.options?.joined(separator: "|||")
            entity.answer = question.answer
            entity.analysis = question.analysis
            entity.bank = bank
        }
        
        do {
            try viewContext.save()
        } catch {
            print("Error saving question bank: \(error)")
        }
    }
    
    // 获取所有题库
    func fetchQuestionBanks() -> [QuestionBank] {
        let request: NSFetchRequest<QuestionBank> = QuestionBank.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \QuestionBank.createdAt, ascending: false)]
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Error fetching question banks: \(error)")
            return []
        }
    }
    
    // 获取题库中的题目
    func fetchQuestions(in bank: QuestionBank) -> [Question] {
        guard let entities = bank.questions?.allObjects as? [QuestionEntity] else {
            return []
        }
        
        return entities.compactMap { entity in
            guard let id = entity.id,
                  let type = Question.QuestionType.from(entity.type ?? ""),
                  let content = entity.content,
                  let answer = entity.answer else {
                return nil
            }
            
            let options = entity.options?.components(separatedBy: "|||")
            
            return Question(
                id: id,
                number: Int(entity.number),
                type: type,
                content: content,
                options: options,
                answer: answer,
                analysis: entity.analysis ?? ""
            )
        }
    }
}
