//
//  StoreDocsViewModel.swift
//  PDF Converter - Aezakmi
//
//  Created by Andrey Kaldyaev on 16.10.2025.
//

import SwiftUI
import PDFKit

class StoreDocsViewModel: ObservableObject {
    @Published var storedDocuments: [Document] = []
    @Published var selectedDocument: Document?
    @Published var isShowingPDFReader = false
    @Published var isMergingMode = false
    @Published var documentsToMerge: [Document] = []
    @Published var isSharing = false
    @Published var alertMessage = ""
    @Published var showAlert = false
    
    private let fileManager = FileManager.default
    private let documentsDirectory: URL
    
    init() {
        documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        loadStoredDocuments()
        
        NotificationCenter.default.addObserver(
            forName: .documentsDidUpdate,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.loadStoredDocuments()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: Загрузка всех сохраненных документов
    func loadStoredDocuments() {
        do {
            let files = try fileManager.contentsOfDirectory(
                at: documentsDirectory,
                includingPropertiesForKeys: [.creationDateKey, .contentModificationDateKey],
                options: .skipsHiddenFiles
            )
            
            let pdfFiles = files.filter { $0.pathExtension.lowercased() == "pdf" }
            
            var documents: [Document] = []
            
            for fileURL in pdfFiles {
                guard let creationDate = (try? fileURL.resourceValues(forKeys: [.creationDateKey]))?.creationDate else {
                    continue
                }
                
                var document = Document(
                    name: fileURL.deletingPathExtension().lastPathComponent,
                    creationDate: creationDate,
                    fileURL: fileURL,
                    pages: []
                )
                
                document.generateThumbnail()
                documents.append(document)
            }
            
            storedDocuments = documents.sorted { $0.creationDate > $1.creationDate }
            
        } catch {
            showAlert(message: "Ошибка при загрузке документов: \(error.localizedDescription)")
        }
    }
    
    // MARK: Показать PDF в читалке
    func showPDFReader(for document: Document) {
        guard fileManager.fileExists(atPath: document.fileURL.path) else {
            showAlert(message: "Файл не найден")
            return
        }
        selectedDocument = document
        isShowingPDFReader = true
    }
    
    // MARK: Поделиться документом
    func shareDocument(_ document: Document) {
        guard fileManager.fileExists(atPath: document.fileURL.path) else {
            showAlert(message: "Файл не найден")
            return
        }
        selectedDocument = document
        isSharing = true
    }
    
    // MARK: Удалить документ
    func deleteDocument(_ document: Document) {
        do {
            if fileManager.fileExists(atPath: document.fileURL.path) {
                try fileManager.removeItem(at: document.fileURL)
                storedDocuments.removeAll { $0.id == document.id }
                
                NotificationCenter.default.post(name: .documentsDidUpdate, object: nil)
                
                showAlert(message: "Документ удален")
            }
        } catch {
            showAlert(message: "Ошибка при удалении документа: \(error.localizedDescription)")
        }
    }
    
    // MARK: Начать процесс объединения
    func startMerging(with document: Document) {
        isMergingMode = true
        documentsToMerge = [document]
        showAlert(message: "Выберите второй документ для объединения")
    }
    
    // MARK: Добавить документ для объединения
    func addDocumentForMerge(_ document: Document) {
        guard isMergingMode else { return }
        
        if documentsToMerge.contains(document) {
            showAlert(message: "Документ уже выбран для объединения")
            return
        }
        
        if documentsToMerge.count < 2 {
            documentsToMerge.append(document)
            
            if documentsToMerge.count == 2 {
                mergeDocuments()
            }
        }
    }
    
    // MARK: Отменить объединение
    func cancelMerging() {
        isMergingMode = false
        documentsToMerge.removeAll()
    }
    
    // MARK: Объединить документы
    private func mergeDocuments() {
        guard documentsToMerge.count == 2 else { return }
        
        let firstDocument = documentsToMerge[0]
        let secondDocument = documentsToMerge[1]
        
        let mergedPDF = PDFDocument()
        
        if let firstPDF = PDFDocument(url: firstDocument.fileURL) {
            for i in 0..<firstPDF.pageCount {
                if let page = firstPDF.page(at: i) {
                    mergedPDF.insert(page, at: mergedPDF.pageCount)
                }
            }
        }
        
        if let secondPDF = PDFDocument(url: secondDocument.fileURL) {
            for i in 0..<secondPDF.pageCount {
                if let page = secondPDF.page(at: i) {
                    mergedPDF.insert(page, at: mergedPDF.pageCount)
                }
            }
        }
        
        let fileName = "merged_\(Int(Date().timeIntervalSince1970)).pdf"
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        if mergedPDF.write(to: fileURL) {
            let mergedDocument = Document(
                name: "Merged_\(Date().formatted(date: .abbreviated, time: .shortened))",
                creationDate: Date(),
                fileURL: fileURL,
                pages: []
            )
            
            storedDocuments.insert(mergedDocument, at: 0)
            
            NotificationCenter.default.post(name: .documentsDidUpdate, object: nil)
            
            showAlert(message: "Документы успешно объединены!")
        } else {
            showAlert(message: "Ошибка при объединении документов")
        }
        
        isMergingMode = false
        documentsToMerge.removeAll()
        
        loadStoredDocuments()
    }
    
    // MARK: Проверить, выбран ли документ для объединения
    func isDocumentSelectedForMerge(_ document: Document) -> Bool {
        return documentsToMerge.contains(document)
    }
    
    private func showAlert(message: String) {
        alertMessage = message
        showAlert = true
    }
}
