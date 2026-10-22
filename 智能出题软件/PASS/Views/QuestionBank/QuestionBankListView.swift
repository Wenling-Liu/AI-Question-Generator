import SwiftUI
import CoreData

struct QuestionBankListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: QuestionBank.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \QuestionBank.createdAt, ascending: false)]
    ) private var questionBanks: FetchedResults<QuestionBank>
    
    @State private var searchText: String = ""
    @State private var showingAddView = false
    @State private var isSelectionMode = false
    @State private var selectedBanks: Set<QuestionBank> = []
    @State private var selectedBankForDetail: QuestionBank? // 用于导航到详情页面

    var body: some View {
        NavigationView {
            VStack {
                // 根据是否为选择模式显示不同的工具栏
                if isSelectionMode {
                    SelectionToolbar(
                        isSelectionMode: $isSelectionMode,
                        selectedBanks: $selectedBanks,
                        allBanks: questionBanks,
                        deleteAction: deleteSelectedBanks
                    )
                } else {
                    SearchBar(searchText: $searchText)
                }
                
                // 题库网格
                QuestionBankGrid(
                    questionBanks: questionBanks,
                    isSelectionMode: $isSelectionMode,
                    selectedBanks: $selectedBanks,
                    addAction: { showingAddView.toggle() },
                    openDetail: { bank in
                        selectedBankForDetail = bank
                    }
                )
            }
            .navigationBarTitleDisplayMode(.inline) // 保持 inline 模式
            .toolbar {
                ToolbarItem(placement: .principal) { // 自定义标题位置
                    VStack {
                        Text("我是押题王")
                            .font(.headline)
                            .foregroundColor(.black)
                            .padding(.top, 8) // 向下移动标题
                    }
                }
            }
            .sheet(isPresented: $showingAddView) {
                AddQuestionBankView()
            }
            .fullScreenCover(item: $selectedBankForDetail) { bank in
                QuestionBankDetailView(questionBank: bank)
            }
        }
    }
    
    // 筛选题库
    private var filteredQuestionBanks: [QuestionBank] {
        if searchText.isEmpty {
            return questionBanks.map { $0 }
        } else {
            return questionBanks.filter { bank in
                (bank.name ?? "").localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    // 删除选中的题库
    private func deleteSelectedBanks() {
        withAnimation {
            for bank in selectedBanks {
                viewContext.delete(bank)
            }
            selectedBanks.removeAll()
            do {
                try viewContext.save()
            } catch {
                print("删除题库时发生错误：\(error)")
            }
        }
    }
}

// 搜索框
struct SearchBar: View {
    @Binding var searchText: String

    var body: some View {
        HStack {
            TextField("搜索题目", text: $searchText)
                .padding(10)
                .background(Color.white)
                .cornerRadius(10)
                .shadow(color: .gray.opacity(0.3), radius: 3, x: 0, y: 2)
                .font(.system(size: 16))

            Button(action: {
                print("搜索内容：\(searchText)")
            }) {
                Image(systemName: "magnifyingglass")
                    .padding(10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .font(.system(size: 18))
            }
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }
}

// 工具栏（选择模式）
struct SelectionToolbar: View {
    @Binding var isSelectionMode: Bool
    @Binding var selectedBanks: Set<QuestionBank>
    let allBanks: FetchedResults<QuestionBank>
    let deleteAction: () -> Void

    var body: some View {
        HStack {
            Button("全选") {
                selectedBanks = Set(allBanks)
            }
            .padding()
            
            Spacer()
            
            Button("删除", role: .destructive, action: deleteAction)
                .padding()
            
            Spacer()
            
            Button("取消") {
                isSelectionMode = false
                selectedBanks.removeAll()
            }
            .padding()
        }
        .background(Color.gray.opacity(0.2))
    }
}

struct QuestionBankGrid: View {
    let questionBanks: FetchedResults<QuestionBank> // 数据源
    @Binding var isSelectionMode: Bool
    @Binding var selectedBanks: Set<QuestionBank>
    let addAction: () -> Void
    let openDetail: (QuestionBank) -> Void // 添加 openDetail 参数
    
    private let iconColors: [Color] = [
        .orange, .green, .pink, .blue, .purple, .red
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                // 添加题库按钮
                AddButton(action: addAction)
                
                // 显示已有题库
                ForEach(questionBanks, id: \.self) { bank in
                    if isSelectionMode {
                        SelectableQuestionBankItem(
                            bank: bank,
                            isSelected: selectedBanks.contains(bank),
                            color: getColor(for: bank),
                            toggleSelection: { toggleSelection(for: bank) }
                        )
                    } else {
                        QuestionBankItem(
                            bank: bank,
                            color: getColor(for: bank),
                            onClick: { openDetail(bank) },
                            onLongPress: { enterSelectionMode(with: bank) }
                        )
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 10)
        }
    }
    
    private func toggleSelection(for bank: QuestionBank) {
        if selectedBanks.contains(bank) {
            selectedBanks.remove(bank)
        } else {
            selectedBanks.insert(bank)
        }
    }

    private func enterSelectionMode(with bank: QuestionBank) {
        isSelectionMode = true
        selectedBanks.insert(bank)
    }

    private func getColor(for bank: QuestionBank) -> Color {
        guard let colorName = bank.color else { return .gray }
        switch colorName {
        case "orange": return .orange
        case "green": return .green
        case "pink": return .pink
        case "blue": return .blue
        case "purple": return .purple
        case "red": return .red
        default: return .gray
        }
    }
}

// 正常模式下的题库项
struct QuestionBankItem: View {
    let bank: QuestionBank
    let color: Color
    let onClick: () -> Void
    let onLongPress: () -> Void

    var body: some View {
        VStack {
            Circle()
                .fill(color)
                .frame(width: 70, height: 70)
                .overlay(
                    Image(systemName: "book.closed.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .foregroundColor(.white)
                )
            
            Text(bank.name ?? "未知题库")
                .font(.footnote)
                .lineLimit(1)
                .foregroundColor(.black)
        }
        .onTapGesture(perform: onClick)
        .onLongPressGesture(perform: onLongPress)
    }
}

// 可选择的题库项（选择模式下）
struct SelectableQuestionBankItem: View {
    let bank: QuestionBank
    let isSelected: Bool
    let color: Color
    let toggleSelection: () -> Void

    var body: some View {
        VStack {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
                    .onTapGesture {
                        toggleSelection()
                    }
                Spacer()
            }
            
            Circle()
                .fill(color)
                .frame(width: 70, height: 70)
                .overlay(
                    Image(systemName: "book.closed.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .foregroundColor(.white)
                )
            
            Text(bank.name ?? "未知题库")
                .font(.footnote)
                .lineLimit(1)
                .foregroundColor(.black)
        }
    }
}

// 添加按钮
struct AddButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 70, height: 70)
                    .overlay(
                        Image(systemName: "plus")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.gray)
                    )
                Text("添加题库")
                    .font(.footnote)
                    .foregroundColor(.gray)
            }
        }
    }
}
