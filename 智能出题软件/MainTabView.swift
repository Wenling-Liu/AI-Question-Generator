import SwiftUI

// 主 TabView 容器
struct MainTabView: View {
    @State private var selectedTab = 0 // 当前选中的 Tab 索引

    var body: some View {
        TabView(selection: $selectedTab) {
            // 出题页面
            QuestionGenerateView()
                .tag(0)
                .tabItem {
                    Image(systemName: "pencil")
                    Text("出题")
                }

            // 题库页面
            QuestionBankListView()
                .tag(1)
                .tabItem {
                    Image(systemName: "book")
                    Text("题库")
                }
        }
        .background(Color.blue.opacity(0.1).ignoresSafeArea()) // 设置浅蓝色背景
        .accentColor(.blue) // 设置选中颜色
    }
}
