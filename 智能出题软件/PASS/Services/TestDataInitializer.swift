import CoreData

struct TestDataInitializer {
    static func initializeTestData(context: NSManagedObjectContext) {
        // 检查是否已经存在数据，避免重复插入
        let fetchRequest: NSFetchRequest<QuestionBank> = QuestionBank.fetchRequest()
        fetchRequest.fetchLimit = 1

        do {
            let count = try context.count(for: fetchRequest)
            if count > 0 {
                print("测试数据已存在，无需重复初始化。")
                return
            }
        } catch {
            print("检查测试数据时出错：\(error)")
            return
        }

        // 创建题库
        let questionBank = QuestionBank(context: context)
        questionBank.id = UUID()
        questionBank.name = "大数据方向测试题库"
        questionBank.createdAt = Date()

        // 添加测试数据（题目）
        let question1 = Question(context: context)
        question1.id = UUID()
        question1.type = "single"
        question1.number = 1
        question1.content = "以下哪个是大数据的特点？"
        question1.options = "A. 数据量大; B. 数据类型单一; C. 数据处理速度慢; D. 只适合小型企业"
        question1.answer = "A"
        question1.analysis = "大数据的特点包括数据量大、种类多样、处理速度快等。"
        question1.bank = questionBank

        let question2 = Question(context: context)
        question2.id = UUID()
        question2.type = "multiple"
        question2.number = 2
        question2.content = "大数据的核心技术包括以下哪些？"
        question2.options = "A. 分布式存储; B. 数据挖掘; C. 高性能计算; D. 区块链"
        question2.answer = "A,B,C"
        question2.analysis = "大数据的核心技术包括分布式存储、数据挖掘、高性能计算等。"
        question2.bank = questionBank

        let question3 = Question(context: context)
        question3.id = UUID()
        question3.type = "judge"
        question3.number = 3
        question3.content = "Hadoop 是一种大数据处理框架。"
        question3.answer = "正确"
        question3.analysis = "Hadoop 是一种开源的大数据分布式处理框架。"
        question3.bank = questionBank

        let question4 = Question(context: context)
        question4.id = UUID()
        question4.type = "blanks"
        question4.number = 4
        question4.content = "大数据分析的三个阶段是：数据采集、数据处理和____。"
        question4.answer = "数据可视化"
        question4.analysis = "数据采集、数据处理和数据可视化是大数据分析的重要阶段。"
        question4.bank = questionBank

        let question5 = Question(context: context)
        question5.id = UUID()
        question5.type = "short"
        question5.number = 5
        question5.content = "简述大数据的 4V 特性及其意义。"
        question5.answer = "详见代码中答案"
        question5.analysis = "理解 4V 特性有助于掌握大数据的核心特点。"
        question5.bank = questionBank

        // 保存数据
        do {
            try context.save()
            print("测试数据保存成功！")
        } catch {
            print("保存测试数据时发生错误：\(error)")
        }
    }
}
