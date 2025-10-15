//
//  MainTabView.swift
//  PDF Converter - Aezakmi
//
//  Created by Andrey Kaldyaev on 15.10.2025.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            GenerationView()
                .tabItem {
                    Image(systemName: "doc.badge.plus")
                    Text("Генерация")
                }
            
            StoreDocsView()
                .tabItem {
                    Image(systemName: "folder.fill")
                    Text("Документы")
                }
        }
        .accentColor(.gold)
    }
}
