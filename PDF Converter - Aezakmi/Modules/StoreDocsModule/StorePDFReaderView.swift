//
//  StorePDFReaderView.swift
//  PDF Converter - Aezakmi
//
//  Created by Andrey Kaldyaev on 16.10.2025.
//

import SwiftUI
import PDFKit

struct StorePDFReaderView: View {
    let documentURL: URL
    let viewModel: StoreDocsViewModel
    @Binding var isPresented: Bool
    @State private var currentPage = 0
    @State private var totalPages = 0
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack {
                    // PDF View
                    PDFKitView(
                        url: documentURL,
                        currentPage: $currentPage,
                        totalPages: $totalPages
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    // Панель управления
                    if totalPages > 1 {
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
        }
    }
}
