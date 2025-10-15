//
//  Document.swift
//  PDF Converter - Aezakmi
//
//  Created by Andrey Kaldyaev on 15.10.2025.
//

import Foundation
struct Document: Identifiable {
    let id = UUID()
    let name: String
    let creationDate: Date
    let fileURL: URL
}
