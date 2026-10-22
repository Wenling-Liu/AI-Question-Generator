import Foundation

class AIService {
    static let shared = AIService()
    
    private let baseURL = "https://open.bigmodel.cn/api/paas/v4/chat/completions"
    private let apiKey = "52e48d4444084161995eb4068a9caeff.j2f42yoQDeiw6MCo"
    
    private init() {}
    
    struct QuestionGenerationParams {
        let content: String?
        let pdfContent: String?
        let singleChoiceCount: Int
        let multipleChoiceCount: Int
        let judgementCount: Int
        let fillBlankCount: Int
        let shortAnswerCount: Int
    }
    
    struct Question: Codable, Hashable {
        let type: String
        let number: Int
        let content: String
        let options: [String]?
        let answer: String
        let analysis: String?
    }
    
    /// 与 AI 交互，并获取完整的响应
    private func chatWithAI(prompt: String) async throws -> String {
        guard let url = URL(string: baseURL) else {
            throw NSError(domain: "Invalid URL", code: -1, userInfo: nil)
        }
        
        // 请求体参数
        let parameters: [String: Any] = [
            "model": "glm-4-plus",  // 确保模型名称正确
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.7,
            "top_p": 0.9,
            "max_tokens": 1000
        ]
        
        // 序列化请求体
        guard let httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: []) else {
            throw NSError(domain: "Failed to serialize request body", code: -1, userInfo: nil)
        }
        
        // 设置请求
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = httpBody
        
        print("Request URL: \(url)")
        print("Request Body: \(String(data: httpBody, encoding: .utf8) ?? "Invalid JSON")")
        
        // 执行异步请求
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // 打印响应状态码
        if let httpResponse = response as? HTTPURLResponse {
            print("HTTP Status Code: \(httpResponse.statusCode)")
            if httpResponse.statusCode != 200 {
                throw NSError(domain: "API returned error status: \(httpResponse.statusCode)", code: httpResponse.statusCode, userInfo: nil)
            }
        }
        
        // 打印响应数据
        print("Response Data: \(String(data: data, encoding: .utf8) ?? "Invalid Response")")
        
        // 解析响应 JSON
        guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw NSError(domain: "Invalid API response format", code: -1, userInfo: nil)
        }
        
        return content // 返回完整的 AI 响应
    }
    
    /// 生成题目，并返回完整的语言模型回复
    func generateQuestions(params: QuestionGenerationParams) async throws -> (rawResponse: String, questions: [Question]) {
        // 生成 Prompt
        let prompt = generatePrompt(params: params)
        
        // 获取 AI 完整回复
        let rawResponse = try await chatWithAI(prompt: prompt)
        
        // 打印 AI 的完整回复到控制台
        print("AI Response:\n\(rawResponse)")
        
        // 尝试解析题目
        let questions = parseQuestions(from: rawResponse)
        
        // 如果解析失败，打印提示信息
        if questions.isEmpty {
            print("⚠️ 解析失败，AI 回复的内容可能不符合预期格式。")
        }
        
        return (rawResponse, questions) // 返回完整回复和解析后的题目
    }
    
    /// 生成 Prompt
    private func generatePrompt(params: QuestionGenerationParams) -> String {
        var contentScope = ""
        if let content = params.content {
            contentScope += "用户输入内容：\n\(content)\n"
        }
        if let pdfContent = params.pdfContent {
            contentScope += "PDF 文档内容：\n\(pdfContent)\n"
        }
        
        return """
        你是一个出题专家，请根据以下要求生成题目答案和解析：
        
        \(contentScope)
        
        单选题：\(params.singleChoiceCount)道
        多选题：\(params.multipleChoiceCount)道
        判断题：\(params.judgementCount)道
        填空题：\(params.fillBlankCount)道
        简答题：\(params.shortAnswerCount)道
        """
    }
    
    /// 解析题目
    private func parseQuestions(from content: String) -> [Question] {
        var questions: [Question] = []
        let lines = content.split(separator: "\n")
        
        var currentType: String = ""
        var currentNumber: Int = 0
        var currentContent: String = ""
        var currentOptions: [String] = []
        var currentAnswer: String = ""
        var currentAnalysis: String?
        
        for line in lines {
            if line.hasPrefix("单选题：") {
                currentType = "single"
            } else if line.hasPrefix("多选题：") {
                currentType = "multiple"
            } else if line.hasPrefix("判断题：") {
                currentType = "judge"
            } else if line.hasPrefix("填空题：") {
                currentType = "blanks"
            } else if line.hasPrefix("简答题：") {
                currentType = "short"
            } else if line.hasPrefix("答案：") {
                currentAnswer = String(line.dropFirst(3).trimmingCharacters(in: .whitespaces))
            } else if line.hasPrefix("解析：") {
                currentAnalysis = String(line.dropFirst(3).trimmingCharacters(in: .whitespaces))
            } else if let numberRange = line.range(of: #"^\d+\."#, options: .regularExpression) {
                // 当前行是题目内容
                if !currentContent.isEmpty {
                    // 保存上一个题目
                    questions.append(Question(
                        type: currentType,
                        number: currentNumber,
                        content: currentContent,
                        options: currentOptions.isEmpty ? nil : currentOptions,
                        answer: currentAnswer,
                        analysis: currentAnalysis
                    ))
                    currentOptions.removeAll()
                }
                currentNumber += 1
                let rangeLength = line.distance(from: numberRange.lowerBound, to: numberRange.upperBound)
                currentContent = String(line.dropFirst(rangeLength))
            } else if let optionRange = line.range(of: #"^[A-D]\."#, options: .regularExpression) {
                // 当前行是选项
                let rangeLength = line.distance(from: optionRange.lowerBound, to: optionRange.upperBound)
                currentOptions.append(String(line.dropFirst(rangeLength)))
            }
        }
        
        // 添加最后一个题目
        if !currentContent.isEmpty {
            questions.append(Question(
                type: currentType,
                number: currentNumber,
                content: currentContent,
                options: currentOptions.isEmpty ? nil : currentOptions,
                answer: currentAnswer,
                analysis: currentAnalysis
            ))
        }
        
        return questions
    }
}
