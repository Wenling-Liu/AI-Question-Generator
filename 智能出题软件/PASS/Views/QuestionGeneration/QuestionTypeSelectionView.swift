import SwiftUI

struct QuestionTypeSelectionView: View {
    let questionTypes: [(String, String, Color)] // 题型数据（名称，图标，颜色）
    @Binding var questionCounts: [String] // 每种题型对应的数量

    // 计算总题目数
    private var totalCount: Int {
        questionCounts.compactMap { Int($0) }.reduce(0, +)
    }

    var body: some View {
        VStack(spacing: 15) {
            // 标题部分
            HStack {
                Text("题型选择")
                    .font(.system(size: 20, weight: .regular))
                Spacer()
                Text("数量")
                    .font(.system(size: 18, weight: .regular))
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(Color.blue.opacity(0.2))
            .cornerRadius(10)

            // 每种题型的行
            ForEach(0..<questionTypes.count, id: \.self) { index in
                HStack(spacing: 10) {
                    // 图标
                    Circle()
                        .fill(questionTypes[index].2)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: questionTypes[index].1)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                                .foregroundColor(.white)
                        )

                    // 标题
                    Text(questionTypes[index].0)
                        .foregroundColor(.black)
                        .font(.system(size: 18))

                    Spacer()

                    // 数量输入框和按钮
                    HStack {
                        // 减号按钮
                        Button(action: {
                            decreaseCount(at: index)
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .resizable()
                                .frame(width: 20, height: 20)
                                .foregroundColor(.gray)
                        }

                        // 数字显示
                        TextField("", text: $questionCounts[index])
                            .frame(width: 40, height: 35)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                            .multilineTextAlignment(.center)
                            .onChange(of: questionCounts[index]) { _ in
                                validateInput(for: index) // 验证输入
                            }

                        // 加号按钮
                        Button(action: {
                            increaseCount(at: index)
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .resizable()
                                .frame(width: 20, height: 20)
                                .foregroundColor(totalCount >= 30 ? .gray : .blue)
                        }
                        .disabled(totalCount >= 30) // 超过30题禁用按钮
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.8))
                .cornerRadius(10)
            }

            // 总题目数显示
            Text("共\(totalCount)道（最多30道）")
                .font(.subheadline)
                .foregroundColor(totalCount > 30 ? .red : .gray)
        }
        .padding()
    }

    // MARK: - 输入验证与数量调整方法

    /// 验证输入是否合法（只能是0到30的数字）
    private func validateInput(for index: Int) {
        if let value = Int(questionCounts[index]) {
            if value < 0 {
                questionCounts[index] = "0"
            } else if value > 30 {
                questionCounts[index] = "30"
            }
        } else {
            questionCounts[index] = "0"
        }
    }

    /// 减少题目数量
    private func decreaseCount(at index: Int) {
        if let currentValue = Int(questionCounts[index]), currentValue > 0 {
            questionCounts[index] = "\(currentValue - 1)"
        }
    }

    /// 增加题目数量
    private func increaseCount(at index: Int) {
        if let currentValue = Int(questionCounts[index]), currentValue < 30 && totalCount < 30 {
            questionCounts[index] = "\(currentValue + 1)"
        }
    }
}
