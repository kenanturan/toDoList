//
//  ContentView.swift
//  toDoList
//
//  Created by Kenan TURAN on 17.12.2024.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingEditAlert = false
    @State private var itemToEdit: Item?
    @State private var newTitle = ""
    @State private var searchText = ""

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)],
        animation: .default)
    private var items: FetchedResults<Item>
    
    var filteredItems: [Item] {
        if searchText.isEmpty {
            return Array(items)
        }
        return items.filter { item in
            (item.title ?? "").localizedCaseInsensitiveContains(searchText) ||
            (item.note ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationView {
            List {
                SearchBar(text: $searchText)
                    .textCase(nil)
                
                ForEach(filteredItems, id: \.self) { item in
                    NavigationLink(destination: DetailView(item: item)) {
                        VStack(alignment: .leading) {
                            Text(item.title ?? "Yeni Not")
                                .font(.headline)
                            Text(item.timestamp ?? Date(), formatter: itemFormatter)
                                .font(.caption)
                            if let reminderDate = item.reminderDate {
                                HStack {
                                    Image(systemName: "bell.fill")
                                        .foregroundColor(.blue)
                                    Text(reminderDate, formatter: itemFormatter)
                                        .font(.caption)
                                }
                            }
                        }
                    }
                    .swipeActions(edge: .trailing) {
                        Button {
                            itemToEdit = item
                            newTitle = item.title ?? "Yeni Not"
                            showingEditAlert = true
                        } label: {
                            Label("Düzenle", systemImage: "pencil")
                        }
                        .tint(.blue)
                        
                        Button(role: .destructive) {
                            withAnimation {
                                viewContext.delete(item)
                                try? viewContext.save()
                            }
                        } label: {
                            Label("Sil", systemImage: "trash")
                        }
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Not Ekle", systemImage: "plus")
                    }
                }
            }
            .alert("Başlığı Düzenle", isPresented: $showingEditAlert) {
                TextField("Başlık", text: $newTitle)
                Button("İptal", role: .cancel) { }
                Button("Kaydet") {
                    if let item = itemToEdit {
                        item.title = newTitle
                        try? viewContext.save()
                    }
                }
            }
        }
    }

    private func addItem() {
        withAnimation {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Date()
            newItem.title = "Yeni Not"
            try? viewContext.save()
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)
            try? viewContext.save()
        }
    }
}

struct SearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField("Ara...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
