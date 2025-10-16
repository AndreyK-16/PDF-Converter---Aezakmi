//
//  GenerationViewModel.swift
//  PDF Converter - Aezakmi
//
//  Created by Andrey Kaldyaev on 15.10.2025.
//

import SwiftUI
import PDFKit

class GenerationViewModel: ObservableObject {
    @Published var selectedImages: [UIImage] = []
    @Published var generatedDocuments: [Document] = []
    @Published var currentPDFURL: URL?
    @Published var isShowingDocumentPicker = false
    @Published var isShowingPDFReader = false
    @Published var isSharing = false
    @Published var alertMessage = ""
    @Published var showAlert = false
    @Published var documentToDelete: Document?
    @Published var showDeleteAlert = false
    
    private let fileManager = FileManager.default
    private let documentsDirectory: URL
    
    init() {
        // MARK: Получаем директорию Documents для постоянного хранения
        documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        loadSavedDocuments()
    }
    
    // MARK: Конвертация в PDF
    func convertToPDF() {
        guard !selectedImages.isEmpty else {
            showAlert(message: "Добавьте изображения для конвертации")
            return
        }
        
        // новый PDF документ
        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, CGRect.zero, nil)
        
        for image in selectedImages {
            // новая страница
            let imageSize = image.size
            let pageRect = CGRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height)
            UIGraphicsBeginPDFPageWithInfo(pageRect, nil)
            
            // отрисовка изображения на странице
            image.draw(in: pageRect)
        }
        UIGraphicsEndPDFContext()
        
        // Сохранение PDF в постоянную директорию
        let fileName = "document_\(Int(Date().timeIntervalSince1970)).pdf"
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        do {
            try pdfData.write(to: fileURL, options: .atomic)
            
            let document = Document(
                name: "Document_\(Date().formatted(date: .abbreviated, time: .shortened))",
                creationDate: Date(),
                fileURL: fileURL,
                pages: selectedImages
            )
            
            generatedDocuments.insert(document, at: 0)
            currentPDFURL = fileURL
            clearAllImages()
            
        } catch {
            showAlert(message: "Ошибка при создании PDF: \(error.localizedDescription)")
        }
    }
    
    // MARK: Показать PDF в читалке
    func showPDFReader(for document: Document) {
        guard fileManager.fileExists(atPath: document.fileURL.path) else {
            showAlert(message: "Файл не найден")
            return
        }
        currentPDFURL = document.fileURL
        isShowingPDFReader = true
    }
    
    // MARK: Поделиться документом
    func shareDocument(_ document: Document) {
        guard fileManager.fileExists(atPath: document.fileURL.path) else {
            showAlert(message: "Файл не найден")
            return
        }
        currentPDFURL = document.fileURL
        isSharing = true
    }
    
    // MARK: Сохранение PDF в файлы
    func savePDFToFiles(_ document: Document) {
        guard fileManager.fileExists(atPath: document.fileURL.path) else {
            showAlert(message: "Файл не найден")
            return
        }
        
        let tempFileName = "export_\(Int(Date().timeIntervalSince1970)).pdf"
        let tempURL = fileManager.temporaryDirectory.appendingPathComponent(tempFileName)
        
        do {
            if fileManager.fileExists(atPath: tempURL.path) {
                try fileManager.removeItem(at: tempURL)
            }
            try fileManager.copyItem(at: document.fileURL, to: tempURL)
            let documentPicker = UIDocumentPickerViewController(forExporting: [tempURL])
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                rootViewController.present(documentPicker, animated: true)
            }
        } catch {
            showAlert(message: "Ошибка при подготовке файла для экспорта: \(error.localizedDescription)")
        }
    }
    
    // MARK: Запрос на удаление документа
    func requestDeleteDocument(_ document: Document) {
        documentToDelete = document
        showDeleteAlert = true
    }
    
    // MARK: Удаление документа
    func deleteDocument() {
        guard let document = documentToDelete else { return }
        
        do {
            if fileManager.fileExists(atPath: document.fileURL.path) {
                try fileManager.removeItem(at: document.fileURL)
                generatedDocuments.removeAll { $0.id == document.id }
            }
        } catch {
            showAlert(message: "Ошибка при удалении документа: \(error.localizedDescription)")
        }
        
        documentToDelete = nil
    }
    
    // MARK: Загрузка всех сохраненных документов при запуске
    func loadSavedDocuments() {
        do {
            let files = try fileManager.contentsOfDirectory(
                at: documentsDirectory,
                includingPropertiesForKeys: [.creationDateKey],
                options: .skipsHiddenFiles
            )
            
            let pdfFiles = files.filter { $0.pathExtension.lowercased() == "pdf" }
            
            let documents = pdfFiles.compactMap { url -> Document? in
                guard let creationDate = (try? url.resourceValues(forKeys: [.creationDateKey]))?.creationDate else {
                    return nil
                }
                return Document(
                    name: url.deletingPathExtension().lastPathComponent,
                    creationDate: creationDate,
                    fileURL: url,
                    pages: []
                )
            }
            
            generatedDocuments = documents.sorted { $0.creationDate > $1.creationDate }
            
        } catch {
            print("Ошибка при загрузке документов: \(error)")
        }
    }
    
    // MARK: Удаление страницы из PDF
    func deletePage(at index: Int, from document: Document) {
        guard var pages = getPages(from: document.fileURL) else { return }
        
        if pages.count > 1 {
            pages.remove(at: index)
            createNewPDF(with: pages, originalDocument: document)
        } else {
            showAlert(message: "Нельзя удалить последнюю страницу")
        }
    }
    
    private func getPages(from url: URL) -> [UIImage]? {
        guard let pdfDocument = PDFDocument(url: url) else { return nil }
        var images: [UIImage] = []
        
        for i in 0..<pdfDocument.pageCount {
            if let page = pdfDocument.page(at: i) {
                let pageRect = page.bounds(for: .mediaBox)
                let renderer = UIGraphicsImageRenderer(size: pageRect.size)
                let image = renderer.image { ctx in
                    UIColor.white.set()
                    ctx.fill(pageRect)
                    ctx.cgContext.translateBy(x: 0.0, y: pageRect.size.height)
                    ctx.cgContext.scaleBy(x: 1.0, y: -1.0)
                    page.draw(with: .mediaBox, to: ctx.cgContext)
                }
                images.append(image)
            }
        }
        return images
    }
    
    private func createNewPDF(with pages: [UIImage], originalDocument: Document) {
        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, CGRect.zero, nil)
        
        for image in pages {
            let imageSize = image.size
            let pageRect = CGRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height)
            UIGraphicsBeginPDFPageWithInfo(pageRect, nil)
            image.draw(in: pageRect)
        }
        
        UIGraphicsEndPDFContext()
        
        let fileName = "document_\(Int(Date().timeIntervalSince1970)).pdf"
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        do {
            try pdfData.write(to: fileURL, options: .atomic)
            
            if let documentIndex = generatedDocuments.firstIndex(of: originalDocument) {
                let newDocument = Document(
                    name: originalDocument.name,
                    creationDate: Date(),
                    fileURL: fileURL,
                    pages: pages
                )
                generatedDocuments[documentIndex] = newDocument
                currentPDFURL = fileURL
                
                // Удаляем старый файл
                if fileManager.fileExists(atPath: originalDocument.fileURL.path) {
                    try fileManager.removeItem(at: originalDocument.fileURL)
                }
                
                showAlert(message: "Страница удалена")
            }
        } catch {
            showAlert(message: "Ошибка при обновлении PDF: \(error.localizedDescription)")
        }
    }
    
    // MARK: Добавление изображений из галереи
    func addImages(_ images: [UIImage]) {
        selectedImages.append(contentsOf: images)
    }
    
    // MARK: Добавление файлов из файловой системы
    func addFiles(_ urls: [URL]) {
        for url in urls {
            if let image = UIImage(contentsOfFile: url.path) {
                selectedImages.append(image)
            }
        }
    }
    
    // MARK: Удаление изображения
    func removeImage(at index: Int) {
        guard selectedImages.indices.contains(index) else { return }
        selectedImages.remove(at: index)
    }
    
    // MARK: Очистка всех изображений
    func clearAllImages() {
        selectedImages.removeAll()
    }
    
    private func showAlert(message: String) {
        alertMessage = message
        showAlert = true
    }
}
