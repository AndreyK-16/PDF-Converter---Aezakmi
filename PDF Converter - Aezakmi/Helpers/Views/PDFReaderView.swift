//
//  PDFReaderView.swift
//  PDF Converter - Aezakmi
//
//  Created by Andrey Kaldyaev on 15.10.2025.
//


import SwiftUI
import PDFKit

struct PDFReaderView: View {
    let documentURL: URL
    let viewModel: GenerationViewModel
    @Binding var isPresented: Bool
    @State private var currentPage = 0
    @State private var totalPages = 0
    @State private var showDeleteAlert = false
    @State private var pageToDelete: Int?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack {
                    // MARK: PDF View
                    PDFKitView(
                        url: documentURL,
                        currentPage: $currentPage,
                        totalPages: $totalPages
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    // MARK: Панель управления
                    HStack {
                        Button(action: {
                            if currentPage > 0 {
                                currentPage -= 1
                            }
                        }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.gold.opacity(0.3))
                                .clipShape(Circle())
                        }
                        .disabled(currentPage == 0)
                        
                        Spacer()
                        
                        Text("\(currentPage + 1) / \(totalPages)")
                            .foregroundColor(.white)
                            .font(.headline)
                        
                        if totalPages > 1 {
                            Button(action: {
                                showDeleteAlert = true
                                pageToDelete = currentPage
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                                    .padding()
                                    .background(Color.gold.opacity(0.3))
                                    .clipShape(Circle())
                            }
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            if currentPage < totalPages - 1 {
                                currentPage += 1
                            }
                        }) {
                            Image(systemName: "chevron.right")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.gold.opacity(0.3))
                                .clipShape(Circle())
                        }
                        .disabled(currentPage == totalPages - 1)
                    }
                    .padding()
                }
            }
            .navigationTitle("Просмотр PDF")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        isPresented = false
                    }
                    .foregroundColor(.gold)
                }
            }
            .alert(isPresented: $showDeleteAlert) {
                Alert(
                    title: Text("Удалить страницу"),
                    message: Text("Вы уверены, что хотите удалить эту страницу?"),
                    primaryButton: .destructive(Text("Удалить")) {
                        if let pageIndex = pageToDelete {
                            if let document = viewModel.generatedDocuments.first(where: { $0.fileURL == documentURL }) {
                                viewModel.deletePage(at: pageIndex, from: document)
                                if pageIndex >= totalPages - 1 {
                                    currentPage = max(0, totalPages - 2)
                                }
                            }
                        }
                    },
                    secondaryButton: .cancel(Text("Отмена"))
                )
            }
            .onAppear {
                loadPDFInfo()
            }
        }
    }
    
    private func loadPDFInfo() {
        guard let pdfDocument = PDFDocument(url: documentURL) else { return }
        totalPages = pdfDocument.pageCount
    }
}

 
struct PDFKitView: UIViewRepresentable {
    let url: URL
    @Binding var currentPage: Int
    @Binding var totalPages: Int
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePage
        pdfView.displayDirection = .horizontal
        pdfView.usePageViewController(true)
        
        if let document = PDFDocument(url: url) {
            pdfView.document = document
            totalPages = document.pageCount
        }
        
        // Наблюдатель за изменением страницы
        NotificationCenter.default.addObserver(
            forName: .PDFViewPageChanged,
            object: pdfView,
            queue: .main
        ) { _ in
            if let currentPage = pdfView.currentPage,
               let pageIndex = pdfView.document?.index(for: currentPage) {
                self.currentPage = pageIndex
            }
        }
        
        return pdfView
    }
    
    func updateUIView(_ pdfView: PDFView, context: Context) {
        if let document = pdfView.document,
           currentPage < document.pageCount,
           let page = document.page(at: currentPage) {
            pdfView.go(to: page)
        }
    }
}
