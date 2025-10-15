//
//  WelcomeView.swift
//  PDF Converter - Aezakmi
//
//  Created by Andrey Kaldyaev on 15.10.2025.
//

import SwiftUI

struct WelcomeView: View {
    @StateObject private var viewModel = WelcomeViewModel()
    @Binding var shouldShowWelcome: Bool
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                VStack(spacing: 20) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.gold)
                    
                    Text("Это тестовое приложение для компании Aezakmi Group. В нем Вы можете открывать фотографии из галереи, конвертировать их в pdf-формат")
                        .font(.body)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                Button(action: {
                    viewModel.markWelcomeAsSeen()
                    shouldShowWelcome = false
                }) {
                    Text("Начать!")
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gold)
                        .cornerRadius(12)
                        .padding(.horizontal, 40)
                }
                
                Spacer().frame(height: 50)
            }
        }
    }
}
