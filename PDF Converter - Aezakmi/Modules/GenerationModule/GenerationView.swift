//
//  GenerationView.swift
//  PDF Converter - Aezakmi
//
//  Created by Andrey Kaldyaev on 15.10.2025.
//

import SwiftUI
import PhotosUI

struct GenerationView: View {
    @StateObject private var viewModel = GenerationViewModel()
    @State private var selectedItems: [PhotosPickerItem] = []
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // MARK: Верхняя часть с кнопками добавления
                    VStack(spacing: 20) {
                        // MARK: Кнопки добавления файлов
                        HStack(spacing: 20) {
                            // MARK: Добавление из галереи
                            PhotosPicker(
                                selection: $selectedItems,
                                maxSelectionCount: 10,
                                matching: .images
                            ) {
                                VStack {
                                    Image(systemName: "photo.on.rectangle")
                                        .font(.title2)
                                    Text("Галерея")
                                        .font(.caption)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gold.opacity(0.2))
                                .cornerRadius(12)
                            }
                            
                            .onChange(of: selectedItems) { newItems in
                                loadImages(from: newItems)
                            }
                            
                            // MARK: Добавление из файлов
                            Button(action: {
                                viewModel.isShowingDocumentPicker = true
                            }) {
                                VStack {
                                    Image(systemName: "folder")
                                        .font(.title2)
                                    Text("Файлы")
                                        .font(.caption)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gold.opacity(0.2))
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)
                        
                        // MARK: Список выбранных изображений
                        if !viewModel.selectedImages.isEmpty {
                            VStack(alignment: .leading) {
                                HStack {
                                    Text("Выбранные изображения: \(viewModel.selectedImages.count)")
                                        .foregroundColor(.white)
                                        .font(.headline)
                                    
                                    Spacer()
                                    
                                    Button("Очистить") {
                                        viewModel.clearAllImages()
                                    }
                                    .foregroundColor(.gold)
                                }
                                .padding(.horizontal)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        ForEach(Array(viewModel.selectedImages.enumerated()), id: \.offset) { index, image in
                                            ZStack(alignment: .topTrailing) {
                                                Image(uiImage: image)
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 100, height: 150)
                                                    .cornerRadius(8)
                                                
                                                Button(action: {
                                                    viewModel.removeImage(at: index)
                                                }) {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .foregroundColor(.red)
                                                        .background(Color.white)
                                                        .clipShape(Circle())
                                                }
                                                .offset(x: 8, y: -8)
                                            }
                                        }
                                    }
                                    .padding()
                                }
                                .frame(height: 170)
                            }
                        }
                        
                        // MARK: Кнопка конвертации
                        if !viewModel.selectedImages.isEmpty {
                            Button(action: {
                                viewModel.convertToPDF()
                            }) {
                                Text("Конвертировать в PDF")
                                    .font(.headline)
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.gold)
                                    .cornerRadius(12)
                                    .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.top)
                    
                    // MARK: Разделитель
                    if !viewModel.generatedDocuments.isEmpty {
                        Rectangle()
                            .fill(Color.gold.opacity(0.3))
                            .frame(height: 1)
                            .padding(.vertical, 10)
                    }
                    
                    // MARK: Список созданных документов (занимает всю оставшуюся высоту)
                    if !viewModel.generatedDocuments.isEmpty {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Созданные документы")
                                .foregroundColor(.white)
                                .font(.headline)
                                .padding(.horizontal)
                                .padding(.bottom, 10)
                            
                            List {
                                ForEach(viewModel.generatedDocuments) { document in
                                    DocumentRowView(
                                        document: document,
                                        viewModel: viewModel
                                    )
                                    .listRowBackground(Color.black)
                                    .listRowSeparatorTint(Color.gold.opacity(0.3))
                                }
                            }
                            .listStyle(PlainListStyle())
                        }
                    } else {
                        // MARK: Пустое состояние
                        VStack {
                            Spacer()
                            Image(systemName: "doc.text")
                                .font(.system(size: 60))
                                .foregroundColor(.gold.opacity(0.5))
                            Text("Нет созданных документов")
                                .foregroundColor(.white.opacity(0.7))
                                .font(.headline)
                                .padding(.top, 10)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Генерация PDF")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $viewModel.isShowingPDFReader) {
                if let url = viewModel.currentPDFURL {
                    PDFReaderView(
                        documentURL: url,
                        viewModel: viewModel,
                        isPresented: $viewModel.isShowingPDFReader
                    )
                }
            }
            .sheet(isPresented: $viewModel.isShowingDocumentPicker) {
                DocumentPicker { urls in
                    viewModel.addFiles(urls)
                }
            }
            .sheet(isPresented: $viewModel.isSharing) {
                if let url = viewModel.currentPDFURL {
                    ShareSheet(activityItems: [url])
                }
            }
            .alert("Удаление документа", isPresented: $viewModel.showDeleteAlert) {
                Button("Отмена", role: .cancel) {
                    viewModel.documentToDelete = nil
                }
                Button("Удалить", role: .destructive) {
                    viewModel.deleteDocument()
                }
            } message: {
                Text("Вы уверены, что хотите удалить этот документ?")
            }
            .alert(isPresented: $viewModel.showAlert) {
                Alert(
                    title: Text(viewModel.alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    private func loadImages(from items: [PhotosPickerItem]) {
        Task {
            var loadedImages: [UIImage] = []
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    loadedImages.append(image)
                }
            }
            await MainActor.run {
                viewModel.addImages(loadedImages)
                selectedItems.removeAll()
            }
        }
    }
}

// MARK: View созданного документа
struct DocumentRowView: View {
    let document: Document
    let viewModel: GenerationViewModel
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(document.name)
                    .foregroundColor(.white)
                    .font(.headline)
                Text(document.creationDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .onTapGesture {
                print("tap to cell doc")
                viewModel.showPDFReader(for: document)
            }
            
            Spacer()
            
            // MARK: Кнопка поделиться
            Image(systemName: "square.and.arrow.up")
                .foregroundColor(.gold)
                .frame(width: 30, height: 30)
                .onTapGesture {
                    viewModel.shareDocument(document)
                    print("tap to share button")
                }
            
            // MARK: Кнопка удаления
            Image(systemName: "trash.fill")
                .foregroundColor(.red)
                .frame(width: 30, height: 30)
                .onTapGesture {
                    viewModel.requestDeleteDocument(document)
                    print("tap to delete button")
                }
            
            // MARK: Кнопка экспорта
            Image(systemName: "arrow.down.doc.fill")
                .foregroundColor(.gold)
                .frame(width: 30, height: 30)
                .onTapGesture {
                    viewModel.savePDFToFiles(document)
                    print("tap to save button")
                }
        }
        .padding()
        .contentShape(Rectangle())
    }
}

