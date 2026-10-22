import SwiftUI

struct AddQuestionBankView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var questionBankName: String = "" // 题库标题
    private let colors: [String: Color] = [ // 可用颜色列表
        "orange": .orange,
        "green": .green,
        "pink": .pink,
        "blue": .blue,
        "purple": .purple,
        "red": .red
    ]
    
    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Section(header: Text("题库信息")) {
                        TextField("请输入题库标题", text: $questionBankName)
                            .autocapitalization(.none)
                            .font(.system(size: 18))
                    }
                }
                .background(Color.blue.opacity(0.1)) // 设置浅蓝色背景
            }
            .navigationTitle("添加题库")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        addQuestionBank()
                        dismiss()
                    }
                    .disabled(questionBankName.isEmpty) // 标题为空时禁用保存按钮
                }
            }
            .background(Color.blue.opacity(0.1).ignoresSafeArea()) // 整体背景
        }
    }
    
    private func addQuestionBank() {
        // 创建题库
        let newBank = QuestionBank(context: viewContext)
        newBank.name = questionBankName
        newBank.createdAt = Date()
        newBank.color = colors.keys.randomElement() ?? "orange" // 随机分配颜色的键值

        do {
            try viewContext.save() // 保存到 Core Data
            print("成功保存题库，标题为：\(questionBankName)，颜色为：\(newBank.color ?? "orange")")
        } catch {
            print("保存题库时发生错误：\(error)")
        }
    }
}
