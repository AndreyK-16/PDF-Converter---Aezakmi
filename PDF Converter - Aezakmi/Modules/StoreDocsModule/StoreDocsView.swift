//
//  StoreDocsView.swift
//  PDF Converter - Aezakmi
//
//  Created by Andrey Kaldyaev on 15.10.2025.
//

import SwiftUI

struct StoreDocsView: View {
//    @StateObject private var viewModel = StoreDocsViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                Text("StoreDocsView")
                    .font(.title)
                    .foregroundColor(.white)
            }
            .navigationTitle("Документы")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}
