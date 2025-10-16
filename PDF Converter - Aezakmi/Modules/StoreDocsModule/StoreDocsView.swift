//
//  StoreDocsView.swift
//  PDF Converter - Aezakmi
//
//  Created by Andrey Kaldyaev on 15.10.2025.
//

import SwiftUI
import PDFKit

struct StoreDocsView: View {
    @StateObject private var viewModel = StoreDocsViewModel()
    @State private var longPressedDocument: Document?
    @State private var showContextMenu = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                contentView
            }
            .navigationTitle("Мои документы")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                toolbarItems
            }
            .sheet(isPresented: $viewModel.isShowingPDFReader) {
                pdfReaderSheet
            }
            .sheet(isPresented: $viewModel.isSharing) {
                shareSheet
            }
            .confirmationDialog(
                "Действия с документом",
                isPresented: $showContextMenu,
                presenting: longPressedDocument
            ) { document in
                contextMenuActions(for: document)
            }
            .alert(isPresented: $viewModel.showAlert) {
                Alert(
                    title: Text("Информация"),
                    message: Text(viewModel.alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onChange(of: viewModel.isMergingMode) { isMerging in
                if !isMerging {
                    longPressedDocument = nil
                }
            }
        }
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        if viewModel.isMergingMode {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Отмена") {
                    viewModel.cancelMerging()
                }
                .foregroundColor(.gold)
            }
            
            ToolbarItem(placement: .principal) {
                Text("Выберите второй документ")
                    .foregroundColor(.white)
                    .font(.headline)
            }
        }
    }
    
    // MARK: - Subviews
    
    private var contentView: some View {
        Group {
            if viewModel.storedDocuments.isEmpty {
                emptyStateView
            } else {
                documentsListView
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack {
            Image(systemName: "doc.text")
                .font(.system(size: 80))
                .foregroundColor(.gold.opacity(0.5))
            Text("Нет сохраненных документов")
                .foregroundColor(.white.opacity(0.7))
                .font(.headline)
                .padding(.top, 20)
            Text("Созданные PDF документы появятся здесь")
                .foregroundColor(.gray)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
    
    private var documentsListView: some View {
        List {
            ForEach(viewModel.storedDocuments) { document in
                DocumentCell(
                    document: document,
                    isSelectedForMerge: viewModel.isDocumentSelectedForMerge(document),
                    isMergingMode: viewModel.isMergingMode
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    handleDocumentTap(document)
                }
                .onLongPressGesture {
                    handleDocumentLongPress(document)
                }
                .listRowBackground(
                    viewModel.isDocumentSelectedForMerge(document) ?
                    Color.gold.opacity(0.2) : Color.black
                )
                .listRowSeparatorTint(Color.gold.opacity(0.3))
            }
        }
        .listStyle(PlainListStyle())
    }
    
    private var pdfReaderSheet: some View {
        Group {
            if let document = viewModel.selectedDocument {
                StorePDFReaderView(
                    documentURL: document.fileURL,
                    viewModel: viewModel,
                    isPresented: $viewModel.isShowingPDFReader
                )
            }
        }
    }
    
    private var shareSheet: some View {
        Group {
            if let document = viewModel.selectedDocument {
                ShareSheet(activityItems: [document.fileURL])
            }
        }
    }
    
    // MARK: - Methods
    private func handleDocumentTap(_ document: Document) {
        if viewModel.isMergingMode {
            viewModel.addDocumentForMerge(document)
        } else {
            viewModel.showPDFReader(for: document)
        }
    }
    
    private func handleDocumentLongPress(_ document: Document) {
        if !viewModel.isMergingMode {
            longPressedDocument = document
            showContextMenu = true
        }
    }
    
    private func contextMenuActions(for document: Document) -> some View {
        Group {
            Button("Поделиться") {
                viewModel.shareDocument(document)
            }
            
            Button("Объединить", role: .none) {
                viewModel.startMerging(with: document)
            }
            
            Button("Удалить", role: .destructive) {
                viewModel.deleteDocument(document)
            }
            
            Button("Отмена", role: .cancel) {
                longPressedDocument = nil
            }
        }
    }
}

// MARK: - Document Cell
struct DocumentCell: View {
    let document: Document
    let isSelectedForMerge: Bool
    let isMergingMode: Bool
    
    var body: some View {
        HStack(spacing: 15) {
            thumbnailView
            documentInfoView
            Spacer()
            trailingIconView
        }
        .padding(.vertical, 8)
        .overlay(selectionOverlay)
    }
    
    private var thumbnailView: some View {
        Group {
            if let thumbnail = document.thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 80)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gold.opacity(0.5), lineWidth: 1)
                    )
            } else {
                ZStack {
                    Rectangle()
                        .fill(Color.gold.opacity(0.2))
                        .frame(width: 60, height: 80)
                        .cornerRadius(8)
                    
                    Image(systemName: "doc.text")
                        .font(.title2)
                        .foregroundColor(.gold)
                }
            }
        }
    }
    
    private var documentInfoView: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(document.name)
                    .foregroundColor(.white)
                    .font(.headline)
                    .lineLimit(1)
                
                if isMergingMode && isSelectedForMerge {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.gold)
                        .font(.caption)
                }
            }
            
            HStack {
                Text("• \(document.fileExtension)")
                    .foregroundColor(.gold)
                    .font(.caption)
                    .padding(4)
                    .background(Color.gold.opacity(0.2))
                    .cornerRadius(4)
                
                Text(document.creationDate, style: .date)
                    .foregroundColor(.gray)
                    .font(.caption)
            }
            
            Text("Создан: \(document.creationDate, style: .time)")
                .foregroundColor(.gray)
                .font(.caption2)
        }
    }
    
    private var trailingIconView: some View {
        Group {
            if isMergingMode && !isSelectedForMerge {
                Image(systemName: "plus.circle")
                    .foregroundColor(.gray)
                    .font(.title3)
            } else if !isMergingMode {
                Image(systemName: "chevron.right")
                    .foregroundColor(.gold.opacity(0.7))
                    .font(.caption)
            }
        }
    }
    
    private var selectionOverlay: some View {
        Group {
            if isSelectedForMerge {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gold, lineWidth: 2)
            } else {
                EmptyView()
            }
        }
    }
}
