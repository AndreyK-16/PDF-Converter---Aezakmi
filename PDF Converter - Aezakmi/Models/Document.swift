//
//  Document.swift
//  PDF Converter - Aezakmi
//
//  Created by Andrey Kaldyaev on 15.10.2025.
//

import PDFKit

struct Document: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let creationDate: Date
    let fileURL: URL
    let pages: [UIImage]
    var thumbnail: UIImage?
    
    var fileExtension: String {
        return "PDF"
    }
    
    static func == (lhs: Document, rhs: Document) -> Bool {
        lhs.id == rhs.id
    }
    
    mutating func generateThumbnail() {
        if let pdfDocument = PDFDocument(url: fileURL),
           let firstPage = pdfDocument.page(at: 0) {
            let pageRect = firstPage.bounds(for: .mediaBox)
            let scale: CGFloat = 0.1
            let thumbnailSize = CGSize(
                width: pageRect.width * scale,
                height: pageRect.height * scale
            )
            
            let renderer = UIGraphicsImageRenderer(size: thumbnailSize)
            thumbnail = renderer.image { ctx in
                UIColor.white.set()
                ctx.fill(CGRect(origin: .zero, size: thumbnailSize))
                ctx.cgContext.translateBy(x: 0.0, y: thumbnailSize.height)
                ctx.cgContext.scaleBy(x: scale, y: -scale)
                firstPage.draw(with: .mediaBox, to: ctx.cgContext)
            }
        }
    }
}
