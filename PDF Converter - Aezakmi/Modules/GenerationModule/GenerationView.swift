//
//  GenerationView.swift
//  PDF Converter - Aezakmi
//
//  Created by Andrey Kaldyaev on 15.10.2025.
//

import SwiftUI

struct GenerationView: View {
//    @StateObject private var viewModel = GenerationViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                Text("GenerationView")
                    .font(.title)
                    .foregroundColor(.white)
            }
            .navigationTitle("Генерация")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}
